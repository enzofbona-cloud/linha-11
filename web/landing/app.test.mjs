import { test } from 'node:test';
import assert from 'node:assert/strict';
import { channelView } from './app.js';

test('canal sem dados não é jogável', () => {
  const v = channelView(null);
  assert.equal(v.playable, false);
  assert.equal(v.status, 'ainda não publicado');
  assert.equal(v.version, '—');
});

test('canal com dados válidos é jogável', () => {
  const v = channelView({ version: '0.1.0', commit: 'abc1234', date: '2026-11-10T12:00:00Z', channel: 'dev' });
  assert.equal(v.playable, true);
  assert.equal(v.version, '0.1.0');
  assert.equal(v.commit, 'abc1234');
  assert.equal(v.status, 'compilação publicada com sucesso');
  assert.match(v.date, /10\/11\/2026/);
});

test('objeto sem versão é tratado como não publicado', () => {
  assert.equal(channelView({ commit: 'abc1234' }).playable, false);
});

test('valor que não é objeto é tratado como não publicado', () => {
  assert.equal(channelView('<html>404</html>').playable, false);
  assert.equal(channelView([]).playable, false);
});

test('data inválida não quebra a página', () => {
  const v = channelView({ version: '0.1.0', commit: 'abc1234', date: 'lixo', channel: 'dev' });
  assert.equal(v.playable, true);
  assert.equal(v.date, 'data desconhecida');
});
