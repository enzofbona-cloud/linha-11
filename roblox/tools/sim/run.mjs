#!/usr/bin/env node
// Junta o simulador, os scripts do jogo e um roteiro de teste num único arquivo
// Luau e roda com o interpretador (build/luau/luau.exe). Não precisa do Studio.
//
// Uso: node roblox/tools/sim/run.mjs [roteiro.luau]   (padrão: campaign.luau)
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '../../..');
const srcRoot = join(repo, 'roblox/src');
const luau = process.env.LUAU || join(repo, 'build/luau/luau.exe');
const scenario = resolve(here, process.argv[2] || 'campaign.luau');
if (!existsSync(luau)) {
  console.error(`ERRO: interpretador Luau não encontrado em ${luau}`);
  process.exit(2);
}

const PARAMS = 'script, require, game, workspace, Instance, Vector3, CFrame, Color3, UDim, UDim2, Vector2, TweenInfo, ' +
  'ColorSequence, ColorSequenceKeypoint, NumberSequence, NumberSequenceKeypoint, NumberRange, Enum, typeof, os, task, warn';

const lines = [];
const map = []; // { start, end, file }
const push = (file, text) => {
  const body = text.replace(/\r/g, '').split('\n');
  map.push({ start: lines.length + 1, end: lines.length + body.length, file });
  lines.push(...body);
};

push('tools/sim/mock.luau', readFileSync(join(here, 'mock.luau'), 'utf8'));
lines.push('local SOURCES = {}');
for (const dir of ['shared', 'server', 'client']) {
  for (const file of readdirSync(join(srcRoot, dir)).sort()) {
    if (!file.endsWith('.lua') && !file.endsWith('.luau')) continue;
    const key = `${dir}/${file.replace(/\.luau?$/, '')}`;
    lines.push(`SOURCES[${JSON.stringify(key)}] = function(${PARAMS})`);
    push(`src/${dir}/${file}`, readFileSync(join(srcRoot, dir, file), 'utf8'));
    lines.push('end');
  }
}
push('tools/sim/runtime.luau', readFileSync(join(here, 'runtime.luau'), 'utf8'));
push(`tools/sim/${process.argv[2] || 'campaign.luau'}`, readFileSync(scenario, 'utf8'));

const outDir = join(repo, 'build/tmp');
mkdirSync(outDir, { recursive: true });
const bundle = join(outDir, 'sim_bundle.luau');
writeFileSync(bundle, lines.join('\n'));

const result = spawnSync(luau, [bundle], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
const translate = (text) => text.replace(/[^\s"':]*sim_bundle(?:\.luau)?"?\]?:(\d+)/g, (_, n) => {
  const line = Number(n);
  const hit = map.find((m) => line >= m.start && line <= m.end);
  return hit ? `${hit.file}:${line - hit.start + 1}` : `bundle:${line}`;
});
const output = translate((result.stdout || '') + (result.stderr || ''));
process.stdout.write(output);
const ok = result.status === 0 && /RESULTADO: \d+ verificacoes, 0 falhas, 0 erros/.test(output);
process.exit(ok ? 0 : 1);
