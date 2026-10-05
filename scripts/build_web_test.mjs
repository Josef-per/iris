import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const script = fileURLToPath(new URL('./build_web.mjs', import.meta.url));
const publicConfig = {
  SUPABASE_URL: 'https://project.example',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
};

function checkConfig(t, { file, env = {}, filename = '.env' } = {}) {
  const cwd = mkdtempSync(join(tmpdir(), 'iris-build-config-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  if (file !== undefined) writeFileSync(join(cwd, filename), file);
  const cleanEnv = { ...process.env };
  for (const name of [
    'IRIS_ENV_FILE', 'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY',
    'SUPABASE_ANON_KEY', 'SUPABASE_AUTH_REDIRECT_URL',
  ]) delete cleanEnv[name];
  const result = spawnSync(process.execPath, [script, '--check-config'], {
    cwd, env: { ...cleanEnv, ...env }, encoding: 'utf8',
  });
  assert.ifError(result.error);
  return result;
}

test('informa variáveis ausentes sem expor configurações de IA', (t) => {
  const result = checkConfig(t, { file: 'OPENAI_API_KEY=segredo-de-teste\n' });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Faltam SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY/);
  assert.match(result.stderr, /\.env\.example e docs\/deploy_vercel\.md/);
  assert.doesNotMatch(result.stderr, /segredo-de-teste|at file:/);
});

test('valida .env e IRIS_ENV_FILE sem iniciar Flutter', (t) => {
  const file = Object.entries(publicConfig).map(([k, v]) => `${k}="${v}"`).join('\n');
  assert.equal(checkConfig(t, { file }).status, 0);
  assert.equal(checkConfig(t, {
    file, filename: 'custom.env', env: { IRIS_ENV_FILE: 'custom.env' },
  }).status, 0);
  const missing = checkConfig(t, { env: { ...publicConfig, IRIS_ENV_FILE: 'missing.env' } });
  assert.equal(missing.status, 1);
  assert.match(missing.stderr, /IRIS_ENV_FILE não encontrado/);
});

test('prioriza ambiente e informa somente a variável ausente', (t) => {
  assert.equal(checkConfig(t, {
    file: 'SUPABASE_URL=invalid\nSUPABASE_PUBLISHABLE_KEY=sb_secret_test',
    env: publicConfig,
  }).status, 0);
  const missing = checkConfig(t, { env: { SUPABASE_URL: publicConfig.SUPABASE_URL } });
  assert.equal(missing.status, 1);
  assert.match(missing.stderr, /Faltam SUPABASE_PUBLISHABLE_KEY/);
  assert.doesNotMatch(missing.stderr, /Faltam SUPABASE_URL/);
});

test('rejeita URLs inválidas e HTTP com diagnóstico sem valores', (t) => {
  for (const SUPABASE_URL of ['invalid-private-value', 'http://project.example']) {
    const result = checkConfig(t, { env: { ...publicConfig, SUPABASE_URL } });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /SUPABASE_URL deve ser uma URL HTTPS válida/);
    assert.doesNotMatch(result.stderr, /invalid-private-value|at file:/);
  }
  const redirect = checkConfig(t, {
    env: { ...publicConfig, SUPABASE_AUTH_REDIRECT_URL: 'invalid' },
  });
  assert.equal(redirect.status, 1);
  assert.match(redirect.stderr, /SUPABASE_AUTH_REDIRECT_URL deve ser uma URL HTTPS válida/);
});

test('aceita anon legada e rejeita chaves administrativas', (t) => {
  const jwt = (role) => `e30.${Buffer.from(JSON.stringify({ role })).toString('base64url')}.test`;
  assert.equal(checkConfig(t, { env: {
    SUPABASE_URL: publicConfig.SUPABASE_URL, SUPABASE_ANON_KEY: jwt('anon'),
  } }).status, 0);
  for (const SUPABASE_PUBLISHABLE_KEY of ['sb_secret_private', jwt('service_role')]) {
    const result = checkConfig(t, { env: { ...publicConfig, SUPABASE_PUBLISHABLE_KEY } });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /somente chave publicável ou anon/);
    assert.ok(!result.stderr.includes(SUPABASE_PUBLISHABLE_KEY));
  }
});
