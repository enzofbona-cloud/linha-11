import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildInfo, readProjectVersion } from './write-build-info.mjs';

test('commit é encurtado para 7 caracteres', () => {
  const i = buildInfo({ version: '0.1.0', commit: 'abcdef1234567', date: '2026-11-10T12:00:00Z', channel: 'dev' });
  assert.deepEqual(i, { version: '0.1.0', commit: 'abcdef1', date: '2026-11-10T12:00:00Z', channel: 'dev' });
});

test('canal estável é aceito', () => {
  assert.equal(buildInfo({ version: '1', commit: 'abcdef1', date: 'd', channel: 'stable' }).channel, 'stable');
});

test('canal desconhecido lança erro', () => {
  assert.throws(() => buildInfo({ version: '1', commit: 'abcdef1', date: 'd', channel: 'prod' }), /canal/);
});

test('commit vazio lança erro', () => {
  assert.throws(() => buildInfo({ version: '1', commit: '', date: 'd', channel: 'dev' }), /commit/);
});

test('versão é lida do texto do project.godot', () => {
  const txt = '[application]\n\nconfig/name="X"\nconfig/version="0.1.0"\n';
  assert.equal(readProjectVersion(txt), '0.1.0');
});

test('project.godot sem versão lança erro', () => {
  assert.throws(() => readProjectVersion('[application]\nconfig/name="X"\n'), /versão/);
});
