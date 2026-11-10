import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, truncateSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { verifyBuild } from './verify-web-build.mjs';

function makeBuild(files = ['index.html', 'index.wasm', 'index.pck', 'index.js']) {
  const dir = mkdtempSync(join(tmpdir(), 'l11-build-'));
  for (const f of files) writeFileSync(join(dir, f), 'x');
  return dir;
}

test('build completo é aceito', () => {
  const r = verifyBuild(makeBuild());
  assert.equal(r.ok, true);
  assert.deepEqual(r.errors, []);
});

for (const [missing, label] of [['index.wasm', '.wasm'], ['index.pck', '.pck'], ['index.html', 'index.html']]) {
  test(`build sem ${label} é rejeitado`, () => {
    const all = ['index.html', 'index.wasm', 'index.pck'];
    const r = verifyBuild(makeBuild(all.filter((f) => f !== missing)));
    assert.equal(r.ok, false);
    assert.ok(r.errors.some((e) => e.includes(label)), r.errors.join('; '));
  });
}

test('arquivo acima de 100 MB é rejeitado com o nome dele', () => {
  const dir = makeBuild();
  truncateSync(join(dir, 'index.pck'), 104857601);
  const r = verifyBuild(dir);
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('index.pck')), r.errors.join('; '));
});

test('arquivo com exatamente 100 MB é aceito', () => {
  const dir = makeBuild();
  truncateSync(join(dir, 'index.pck'), 104857600);
  assert.equal(verifyBuild(dir).ok, true);
});

test('total acima do limite é rejeitado', () => {
  const dir = makeBuild();
  const r = verifyBuild(dir, { maxTotalBytes: 3 });
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('total')), r.errors.join('; '));
});

test('arquivos em subpastas entram na conta', () => {
  const dir = makeBuild();
  mkdirSync(join(dir, 'sub'));
  writeFileSync(join(dir, 'sub', 'grande.bin'), 'xxxxxxxxxx');
  const r = verifyBuild(dir, { maxFileBytes: 5 });
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('grande.bin')));
});

test('pasta inexistente é rejeitada sem lançar exceção', () => {
  const r = verifyBuild(join(tmpdir(), 'l11-nao-existe-' + Date.now()));
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('não encontrada')));
});

test('pasta vazia é rejeitada', () => {
  const r = verifyBuild(mkdtempSync(join(tmpdir(), 'l11-vazio-')));
  assert.equal(r.ok, false);
});
