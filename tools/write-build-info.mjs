#!/usr/bin/env node
// Gera o JSON de identificação do build (lido pelo jogo e pela página de testes).
// Uso: node tools/write-build-info.mjs --channel <dev|stable> --commit <sha> --out <arquivo> [--out <arquivo>...]
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { pathToFileURL } from 'node:url';

const CHANNELS = ['dev', 'stable'];

export function buildInfo({ version, commit, date, channel }) {
  if (!CHANNELS.includes(channel)) throw new Error(`canal inválido: "${channel}" (use dev ou stable)`);
  if (!commit) throw new Error('commit não informado');
  if (!version) throw new Error('versão não informada');
  return { version, commit: commit.slice(0, 7), date, channel };
}

export function readProjectVersion(projectText) {
  const match = projectText.match(/^config\/version="([^"]+)"/m);
  if (!match) throw new Error('versão não encontrada em project.godot (config/version)');
  return match[1];
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  const opts = { out: [] };
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, '');
    if (key === 'out') opts.out.push(args[i + 1]);
    else opts[key] = args[i + 1];
  }
  try {
    if (opts.out.length === 0) throw new Error('informe ao menos um --out');
    const info = buildInfo({
      version: readProjectVersion(readFileSync('project.godot', 'utf8')),
      commit: opts.commit,
      date: new Date().toISOString().replace(/\.\d+Z$/, 'Z'),
      channel: opts.channel,
    });
    for (const file of opts.out) {
      mkdirSync(dirname(file), { recursive: true });
      writeFileSync(file, JSON.stringify(info, null, 2) + '\n');
    }
    console.log(JSON.stringify(info));
  } catch (err) {
    console.error(`ERRO: ${err.message}`);
    process.exit(1);
  }
}
