import assert from 'node:assert/strict';
import test from 'node:test';
import { aiFunctionNames, buildWebOrigin, checkAiWebCors } from './ai_web_cors.mjs';

const origin = 'https://iris-landingpage.vercel.app';
const cors = {
  'Access-Control-Allow-Origin': origin,
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
};

function endpoint(overrides = {}) {
  const calls = [];
  return {
    calls,
    async request(url, init) {
      const name = new URL(url).pathname.split('/').pop();
      calls.push(name);
      assert.equal(init.method, 'OPTIONS');
      assert.equal(init.headers.Origin, origin);
      assert.equal(init.body, undefined);
      assert.equal(init.headers.Authorization, undefined);
      assert.equal(init.headers.apikey, undefined);
      const { status = 204, headers = cors } = overrides[name] ?? {};
      return new Response(null, { status, headers });
    },
  };
}

test('verifica ambas as funções sem sessão, dados pessoais ou geração', async () => {
  const remote = endpoint();
  assert.equal(await checkAiWebCors('https://project.example', origin, remote.request), true);
  assert.deepEqual(remote.calls, aiFunctionNames);
});

test('reproduz bloqueio 403 do novo domínio e rejeita falha em qualquer função', async () => {
  for (const name of aiFunctionNames) {
    const remote = endpoint({ [name]: { status: 403, headers: {} } });
    assert.equal(await checkAiWebCors('https://project.example', origin, remote.request), false);
    assert.deepEqual(remote.calls, aiFunctionNames);
  }
});

test('rejeita preflight sem origem exata, método POST ou cabeçalhos do Flutter', async () => {
  for (const headers of [
    { ...cors, 'Access-Control-Allow-Origin': 'https://iris-demo-drab.vercel.app' },
    { ...cors, 'Access-Control-Allow-Methods': 'OPTIONS' },
    { ...cors, 'Access-Control-Allow-Headers': 'authorization, apikey, content-type' },
  ]) {
    const remote = endpoint({ 'ai-daily-companion': { headers } });
    assert.equal(await checkAiWebCors('https://project.example', origin, remote.request), false);
  }
});

test('falha de rede impede confirmar publicação', async () => {
  await assert.rejects(checkAiWebCors('https://project.example', origin, async () => {
    throw new Error('network_unavailable');
  }), /network_unavailable/);
});

test('usa domínio estável da Vercel em produção e permite origem explícita', () => {
  const env = {
    VERCEL_ENV: 'production', VERCEL_PROJECT_PRODUCTION_URL: 'iris-landingpage.vercel.app',
    VERCEL_URL: 'iris-preview-unico.vercel.app',
  };
  assert.equal(buildWebOrigin(env), origin);
  assert.equal(buildWebOrigin({ ...env, IRIS_WEB_ORIGIN: 'https://custom.example' }), 'https://custom.example');
  assert.equal(buildWebOrigin({ ...env, VERCEL_ENV: 'preview' }), '');
  assert.equal(buildWebOrigin({}), '');
});
