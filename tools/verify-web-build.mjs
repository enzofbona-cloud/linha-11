#!/usr/bin/env node
// Verifica se uma pasta contém um build Web publicável no GitHub Pages.
// Uso: node tools/verify-web-build.mjs <pasta>
import { existsSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { pathToFileURL } from 'node:url';

export const MAX_FILE_BYTES = 104857600; // 100 MB (limite por arquivo do GitHub)
export const MAX_TOTAL_BYTES = 1073741824; // 1 GB (limite por site do GitHub Pages)

function listFiles(dir) {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...listFiles(full));
    else out.push({ path: full, size: statSync(full).size });
  }
  return out;
}

const mb = (bytes) => (bytes / 1048576).toFixed(1) + ' MB';

export function verifyBuild(dir, { maxFileBytes = MAX_FILE_BYTES, maxTotalBytes = MAX_TOTAL_BYTES } = {}) {
  const errors = [];
  if (!dir || !existsSync(dir) || !statSync(dir).isDirectory()) {
    return { ok: false, errors: [`pasta de build não encontrada: ${dir}`], files: [], total: 0 };
  }

  const files = listFiles(dir).map((f) => ({ name: relative(dir, f.path).replaceAll('\\', '/'), size: f.size }));
  const total = files.reduce((sum, f) => sum + f.size, 0);
  const topLevel = files.filter((f) => !f.name.includes('/')).map((f) => f.name);

  if (!topLevel.includes('index.html')) errors.push('falta index.html');
  if (!topLevel.some((n) => n.endsWith('.wasm'))) errors.push('falta o arquivo .wasm');
  if (!topLevel.some((n) => n.endsWith('.pck'))) errors.push('falta o arquivo .pck');

  for (const f of files) {
    if (f.size > maxFileBytes) errors.push(`arquivo grande demais: ${f.name} (${mb(f.size)}, limite ${mb(maxFileBytes)})`);
  }
  if (total > maxTotalBytes) errors.push(`tamanho total acima do limite: ${mb(total)} (limite ${mb(maxTotalBytes)})`);

  return { ok: errors.length === 0, errors, files, total };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const result = verifyBuild(process.argv[2]);
  for (const f of result.files) console.log(`${mb(f.size).padStart(10)}  ${f.name}`);
  console.log(`${mb(result.total).padStart(10)}  total`);
  if (!result.ok) {
    for (const e of result.errors) console.error(`ERRO: ${e}`);
    process.exit(1);
  }
  console.log('Build Web válido.');
}
