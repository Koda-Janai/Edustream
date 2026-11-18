const { test } = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');

const lecciones = JSON.parse(readFileSync(join(__dirname, '../Firebase/lecciones.json'), 'utf8'));

test('las once categorías tienen IDs de documento únicos', () => {
  assert.ok(lecciones.length >= 11);
  assert.equal(new Set(lecciones.map(leccion => leccion.id)).size, lecciones.length);
  assert.ok(lecciones.every(leccion => /^[a-z][a-z0-9-]+$/.test(leccion.id)));
  assert.deepEqual(new Set(lecciones.map(leccion => leccion.tema)),
    new Set(['Series', 'Historia', 'Deportes', 'Química', 'Cine', 'Música',
      'Filosofía', 'Arte', 'Matemática', 'Videojuegos', 'Física']));
});

test('cada documento incluye tres fragmentos, recurso visual y respuesta válida', () => {
  for (const leccion of lecciones) {
    for (const campo of ['titulo', 'tema', 'area', 'nivel', 'texto', 'ejemploVisual', 'pregunta', 'explicacion']) {
      assert.ok(typeof leccion[campo] === 'string' && leccion[campo].trim(), campo);
    }
    assert.ok(leccion.texto.split('\n\n').filter(texto => texto.trim()).length >= 3);
    assert.ok(Number.isInteger(leccion.minutos) && leccion.minutos > 0);
    assert.equal(typeof leccion.destacada, 'boolean');
    assert.ok(leccion.opciones.length > 1 && leccion.opciones.every(opcion => opcion.trim()));
    assert.ok(Number.isInteger(leccion.respuestaCorrecta) && leccion.opciones[leccion.respuestaCorrecta]);
  }
});

test('la vista previa es repetible y diferencia los destinos sin credenciales', () => {
  const programa = join(__dirname, '../Firebase/publicar.mjs');
  const ejecutar = (...args) => execFileSync(process.execPath, [programa, ...args], { encoding: 'utf8' });
  const normal = ejecutar();
  assert.equal(normal, ejecutar());
  assert.match(normal, /edustream-ab036\/lessons/);
  assert.match(ejecutar('--emulador'), /demo-edustream\/lessons/);
  assert.match(normal, /Vista previa/);
});
