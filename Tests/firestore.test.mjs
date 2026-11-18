import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails } from '@firebase/rules-unit-testing';
import { collection, doc, getDocFromServer, getDocsFromServer, runTransaction,
  serverTimestamp, setDoc } from 'firebase/firestore';

let ambiente;
before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Activa el emulador local de Firestore.');
  ambiente = await initializeTestEnvironment({
    projectId: 'demo-edustream',
    firestore: { rules: readFileSync(new URL('../Firebase/firestore.rules', import.meta.url), 'utf8') }
  });
  await ambiente.clearFirestore();
  await ambiente.withSecurityRulesDisabled(async contexto => {
    const [leccion] = JSON.parse(readFileSync(new URL('../Firebase/lecciones.json', import.meta.url), 'utf8'));
    const { id, ...datos } = leccion;
    await setDoc(doc(contexto.firestore(), 'lessons', id), datos);
  });
});
after(async () => { await ambiente?.cleanup(); });

const dbDe = uid => ambiente.authenticatedContext(uid).firestore();
const finalizacion = (db, uid) => doc(db, 'users', uid, 'lessonProgress', 'proporciones');

function crearSiFalta(db, ref, campos) {
  return runTransaction(db, async transaccion => {
    if (!(await transaccion.get(ref)).exists()) transaccion.set(ref, campos);
  });
}

function guardarPosicion(db, ref, position) {
  return runTransaction(db, async transaccion => {
    const anterior = (await transaccion.get(ref)).data()?.position ?? 0;
    if (position > anterior) transaccion.set(ref, { position });
  });
}

test('completar concurrentemente y reintentar conserva una fila y la primera marca', async () => {
  const uid = 'ana';
  const db = dbDe(uid);
  const ref = finalizacion(db, uid);
  const campos = () => ({ completedAt: serverTimestamp() });
  await Promise.all([crearSiFalta(db, ref, campos()), crearSiFalta(db, ref, campos())]);
  const primero = await getDocFromServer(ref);
  assert.ok(primero.exists());
  const siguienteSesion = dbDe(uid);
  await crearSiFalta(siguienteSesion, finalizacion(siguienteSesion, uid), campos());
  const despues = await getDocFromServer(ref);
  assert.ok(primero.data().completedAt.isEqual(despues.data().completedAt));
  assert.equal((await getDocsFromServer(collection(db, 'users', uid, 'lessonProgress'))).size, 1);
  await assertFails(setDoc(ref, campos()));
});

test('la posición conserva el máximo ante reintentos desordenados', async () => {
  const uid = 'lectora';
  const db = dbDe(uid);
  const ref = doc(db, 'users', uid, 'readingProgress', 'proporciones');
  await Promise.all([guardarPosicion(db, ref, 1), guardarPosicion(db, ref, 2)]);
  await guardarPosicion(db, ref, 2);
  await guardarPosicion(db, ref, 1);
  assert.equal((await getDocFromServer(ref)).data().position, 2);
  await assertFails(setDoc(ref, { position: 1 }));
});

test('el mismo ID de quiz conserva su respuesta y una nueva tentativa tiene otro ID', async () => {
  const uid = 'estudiante';
  const db = dbDe(uid);
  const intentos = collection(db, 'users', uid, 'quizAttempts');
  const primero = doc(intentos, 'intento-primero');
  const segundo = doc(intentos, 'intento-segundo');
  const datos = answer => ({ lessonId: 'proporciones', answer, submittedAt: serverTimestamp() });
  await crearSiFalta(db, primero, datos(1));
  const original = (await getDocFromServer(primero)).data();
  await crearSiFalta(db, primero, datos(0));
  await crearSiFalta(db, segundo, datos(0));
  const reintento = (await getDocFromServer(primero)).data();
  assert.equal(reintento.answer, original.answer);
  assert.ok(reintento.submittedAt.isEqual(original.submittedAt));
  assert.equal((await getDocsFromServer(intentos)).size, 2);
  await assertFails(setDoc(doc(intentos, 'invalido'), datos(999)));
});

test('las rutas privadas rechazan acceso cruzado y el catálogo exige sesión', async () => {
  const uid = 'luis';
  const db = dbDe(uid);
  const propio = finalizacion(db, uid);
  await crearSiFalta(db, propio, { completedAt: serverTimestamp() });
  assert.ok((await getDocFromServer(propio)).exists());
  for (const [carpeta, id, datos] of [
    ['lessonProgress', 'proporciones', { completedAt: serverTimestamp() }],
    ['readingProgress', 'proporciones', { position: 1 }],
    ['quizAttempts', 'intruso', { lessonId: 'proporciones', answer: 1, submittedAt: serverTimestamp() }]
  ]) {
    const ajeno = doc(db, 'users', 'otra-persona', carpeta, id);
    await assertFails(getDocFromServer(ajeno));
    await assertFails(setDoc(ajeno, datos));
  }
  const sinSesion = ambiente.unauthenticatedContext().firestore();
  await assertFails(getDocFromServer(doc(sinSesion, 'lessons', 'proporciones')));
  assert.ok((await getDocFromServer(doc(db, 'lessons', 'proporciones'))).exists());
});
