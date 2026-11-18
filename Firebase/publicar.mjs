import { readFileSync } from 'node:fs';

const argumentos = process.argv.slice(2);
const destinosValidos = new Set(['--apply', '--emulador']);
if (argumentos.some(arg => !destinosValidos.has(arg))) {
  throw new Error('Uso: node Firebase/publicar.mjs [--apply] [--emulador]');
}

const emulador = argumentos.includes('--emulador');
const aplicar = argumentos.includes('--apply');
const projectId = emulador ? 'demo-edustream' : 'edustream-ab036';
const lecciones = JSON.parse(readFileSync(new URL('./lecciones.json', import.meta.url), 'utf8'));
const ids = new Set(lecciones.map(leccion => leccion.id));
if (ids.size !== lecciones.length || [...ids].some(id => !/^[a-z][a-z0-9-]+$/.test(id))) {
  throw new Error('El catálogo contiene IDs inválidos o repetidos.');
}

console.log(`Destino: ${projectId}/lessons · ${lecciones.length} documentos`);
if (!aplicar) {
  for (const { id, titulo } of lecciones) console.log(`${id}: ${titulo}`);
  console.log('Vista previa. Para crear los documentos faltantes, usa --apply.');
} else {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (emulador && host && host !== '127.0.0.1:8080' && host !== 'localhost:8080') {
    throw new Error('Para pruebas usa el emulador local de Firestore en el puerto 8080.');
  }
  if (!emulador && host) {
    throw new Error('Quita FIRESTORE_EMULATOR_HOST para publicar en el proyecto indicado.');
  }
  if (emulador) process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

  const { applicationDefault, initializeApp } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  const app = initializeApp(emulador ? { projectId } : { credential: applicationDefault(), projectId });
  const db = getFirestore(app);
  for (const { id, ...campos } of lecciones) {
    try {
      await db.collection('lessons').doc(id).create(campos);
      console.log(`Creada: ${id}`);
    } catch (error) {
      if (error.code !== 6 && error.code !== 'ALREADY_EXISTS') throw error;
      console.log(`Ya existe: ${id}`);
    }
  }
}
