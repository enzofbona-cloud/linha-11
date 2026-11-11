#!/usr/bin/env node
// Teste de ponta a ponta no navegador: abre o build Web em um Chrome/Edge real
// e confere menu, captura do mouse, câmera, movimento, lanterna e pausa.
//
// Uso:  node tools/e2e/web-smoke.mjs [pasta do site] [--headful] [--url <endereço>]
// Requer: `npm install` dentro de tools/e2e e um Chrome ou Edge instalado.
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer-core';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const headful = args.includes('--headful');
const urlArg = args.includes('--url') ? args[args.indexOf('--url') + 1] : null;
const siteDir = resolve(args.find((a) => !a.startsWith('--') && a !== urlArg) ?? 'build/site');
const PORT = 4399;
const shotsDir = resolve('build/e2e');
mkdirSync(shotsDir, { recursive: true });

const BROWSERS = [
  process.env.BROWSER_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium-browser',
].filter(Boolean);
const executablePath = BROWSERS.find((p) => existsSync(p));
if (!executablePath) {
  console.error('ERRO: nenhum Chrome/Edge encontrado. Defina BROWSER_PATH.');
  process.exit(2);
}

const results = [];
const check = (name, ok, detail = '') => {
  results.push({ name, ok });
  console.log(`${ok ? 'OK  ' : 'FALHA'}  ${name}${detail ? '  — ' + detail : ''}`);
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let server;
if (!urlArg) {
  server = spawn(process.execPath, [join(here, '..', 'serve.mjs'), siteDir, String(PORT)], { stdio: 'ignore' });
  await sleep(700);
}
const base = urlArg ?? `http://localhost:${PORT}/dev/`;

const browser = await puppeteer.launch({
  executablePath,
  headless: headful ? false : 'new',
  args: ['--window-size=1280,720', ...(headful ? [] : ['--use-angle=swiftshader', '--enable-unsafe-swiftshader']),
    '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required', '--mute-audio'],
  defaultViewport: { width: 1280, height: 720 },
});

const errors = [];
try {
  const page = await browser.newPage();
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(String(e)));

  const state = () => page.evaluate(() => window.linha11 ?? null);
  const locked = () => page.evaluate(() => document.pointerLockElement !== null);
  const waitFor = async (fn, ms = 20000, step = 200) => {
    const end = Date.now() + ms;
    while (Date.now() < end) {
      const v = await fn();
      if (v) return v;
      await sleep(step);
    }
    return null;
  };

  await page.goto(base, { waitUntil: 'load', timeout: 120000 });
  const started = await waitFor(() => page.evaluate(() => {
    const c = document.querySelector('canvas');
    const s = document.querySelector('#status');
    return !!c && (!s || getComputedStyle(s).display === 'none' || s.style.visibility === 'hidden' || s.hidden);
  }), 120000, 500);
  check('o jogo carrega no navegador', !!started);
  await sleep(2500);
  await page.screenshot({ path: join(shotsDir, '01-menu.png') });

  // Menu: o botão "Nova campanha" já tem foco; Enter inicia.
  await page.mouse.click(900, 600);
  await page.keyboard.press('Enter');
  const inGame = await waitFor(async () => (await state())?.scene === 'Prototype', 30000);
  check('Nova campanha abre o Capítulo 1', !!inGame);
  await sleep(1200);

  // Captura do mouse: um clique na tela deve prender o cursor.
  if (!(await locked())) await page.mouse.click(640, 360);
  const gotLock = await waitFor(async () => (await locked()) && (await state())?.captured, 6000);
  check('clicar prende o mouse (pointer lock)', !!gotLock, JSON.stringify(await state()));
  check('aviso "Clique para jogar" some depois da captura', (await state())?.overlay === false);

  // Câmera: mover o mouse deve girar, inclusive além da borda da tela.
  const before = await state();
  for (let i = 0; i < 40; i++) await page.mouse.move(640 + i * 40, 360 + i * 3, { steps: 1 });
  await sleep(600);
  const after = await state();
  const yawDelta = Math.abs((after?.yaw ?? 0) - (before?.yaw ?? 0));
  check('mover o mouse gira a câmera', yawDelta > 20, `giro de ${yawDelta.toFixed(1)}°`);
  check('a câmera continua girando além da largura da tela', yawDelta > 100, `giro de ${yawDelta.toFixed(1)}°`);
  // volta a olhar para a frente
  for (let i = 0; i < 40; i++) await page.mouse.move(2240 - i * 40, 480 - i * 3, { steps: 1 });
  await sleep(400);

  // Movimento
  const p0 = await state();
  await page.keyboard.down('KeyW');
  await sleep(1500);
  await page.keyboard.up('KeyW');
  await sleep(400);
  const p1 = await state();
  const moved = Math.hypot((p1?.x ?? 0) - (p0?.x ?? 0), (p1?.z ?? 0) - (p0?.z ?? 0));
  // Sem placa de vídeo (modo sem janela) o jogo roda lento; o limite é menor.
  check('W anda para a frente', moved > (headful ? 1.5 : 0.3), `andou ${moved.toFixed(2)} m`);

  // Lanterna
  const f0 = (await state())?.flashlight;
  await page.keyboard.press('KeyF', { delay: 90 });
  const toggled = await waitFor(async () => (await state())?.flashlight !== f0, 2500);
  check('F alterna a lanterna', !!toggled, `antes ${f0}, depois ${(await state())?.flashlight}`);
  await page.keyboard.press('KeyF', { delay: 90 });
  await page.screenshot({ path: join(shotsDir, '02-jogo.png') });

  // Pausa por tecla e retomada
  await page.keyboard.press('KeyP');
  const paused = await waitFor(async () => (await state())?.paused === true, 4000);
  check('P pausa e solta o mouse', !!paused && !(await locked()));
  await page.screenshot({ path: join(shotsDir, '03-pausa.png') });
  await page.keyboard.press('KeyP');
  const resumed = await waitFor(async () => {
    const s = await state();
    return s && !s.paused && s.captured;
  }, 5000);
  check('P de novo retoma e prende o mouse', !!resumed, JSON.stringify(await state()));

  // O navegador solta o mouse (equivalente ao Esc): o jogo deve pausar.
  await page.evaluate(() => document.exitPointerLock());
  const autoPaused = await waitFor(async () => (await state())?.paused === true, 4000);
  check('soltar o mouse pelo navegador (Esc) pausa o jogo', !!autoPaused);

  const serious = errors.filter((e) => !/favicon|WrongDocumentError/i.test(e));
  check('console sem erros', serious.length === 0, serious.slice(0, 3).join(' | '));
} catch (err) {
  check('execução do teste', false, String(err));
} finally {
  await browser.close();
  server?.kill();
}

const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length - failed.length} de ${results.length} verificações passaram.`);
process.exit(failed.length === 0 ? 0 : 1);
