import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runInNewContext } from 'node:vm';
import { prepareLanding } from './prepare_landing.mjs';

const source = readFileSync('web/landing/main.js', 'utf8');
function page({ search = '', hash = '', userAgent = '', standalone = false } = {}) {
  const events = {};
  const nodes = new Map();
  function element(selector) {
    if (!nodes.has(selector)) nodes.set(selector, {
      textContent: '', disabled: false, open: false, events: {},
      addEventListener(name, callback) { this.events[name] = callback; },
      querySelector: element,
      showModal() { this.open = true; },
      close() { this.open = false; },
    });
    return nodes.get(selector);
  }
  const location = { search, hash, replace(url) { this.redirect = url; } };
  runInNewContext(source, {
    URLSearchParams, location,
    document: { querySelector: element },
    navigator: { userAgent, platform: '', maxTouchPoints: 0 },
    matchMedia: () => ({ matches: standalone }),
    window: { addEventListener(name, callback) { events[name] = callback; } },
  });
  return { element, events, location };
}

test('preserva callbacks de autenticação e links antigos do Flutter', () => {
  for (const [search, hash] of [['?code=example', ''], ['', '#access_token=example&type=recovery'], ['', '#/profissional/agenda'], ['?error_code=expired', '']]) {
    assert.equal(page({ search, hash }).location.redirect, `/app${search}${hash}`);
  }
  assert.equal(page({ hash: '#sobre' }).location.redirect, undefined);
});

test('mostra instruções de instalação para Android, iPhone e desktop', async () => {
  for (const [userAgent, expected] of [['Android', 'Chrome'], ['iPhone', 'Safari'], ['', 'Edge']]) {
    const current = page({ userAgent });
    await current.element('#install-button').events.click();
    assert.equal(current.element('#install-dialog').open, true);
    assert.ok(current.element('#dialog-instructions').textContent.includes(expected));
    current.element('.dialog-close').events.click();
    assert.equal(current.element('#install-dialog').open, false);
  }
});

test('usa o prompt nativo e permite continuar quando a instalação é recusada', async () => {
  const current = page();
  let prompted = false;
  current.events.beforeinstallprompt({ preventDefault() {}, async prompt() { prompted = true; }, userChoice: Promise.resolve({ outcome: 'dismissed' }) });
  await current.element('#install-button').events.click();
  assert.equal(prompted, true);
  assert.equal(current.element('#install-button').disabled, false);
  assert.match(current.element('#install-status').textContent, /adicionar depois/);
  await current.element('#install-button').events.click();
  assert.equal(current.element('#install-dialog').open, true);
});

test('recupera falha do prompt e reconhece aplicativo instalado', async () => {
  const current = page();
  current.events.beforeinstallprompt({ preventDefault() {}, async prompt() { throw new Error('indisponível'); } });
  await current.element('#install-button').events.click();
  assert.equal(current.element('#install-dialog').open, true);
  current.events.appinstalled();
  assert.equal(current.element('#install-button').disabled, true);
  assert.equal(page({ standalone: true }).element('#install-button').disabled, true);
});

test('montagem preserva o shell e atualiza-o em builds subsequentes', () => {
  const directory = mkdtempSync(join(tmpdir(), 'iris-landing-'));
  try {
    assert.throws(() => prepareLanding(directory), /Compile o Flutter/);
    mkdirSync(join(directory, 'landing'));
    writeFileSync(join(directory, 'flutter_bootstrap.js'), '');
    writeFileSync(join(directory, 'landing/index.html'), '<h1>Landing</h1>');
    writeFileSync(join(directory, 'index.html'), '<script src="flutter_bootstrap.js"></script>');
    prepareLanding(directory);
    assert.equal(readFileSync(join(directory, 'index.html'), 'utf8'), '<h1>Landing</h1>');
    prepareLanding(directory);
    assert.match(readFileSync(join(directory, 'app.html'), 'utf8'), /flutter_bootstrap/);
    writeFileSync(join(directory, 'index.html'), '<script src="flutter_bootstrap.js"></script>novo build');
    prepareLanding(directory);
    assert.match(readFileSync(join(directory, 'app.html'), 'utf8'), /novo build/);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
