import assert from 'node:assert/strict';
import test from 'node:test';
import { checkDailyCompanionWeb, expectedFunctionVersion } from './check_daily_companion_web.mjs';

const origin = 'https://app.example';
const cors = {
  'access-control-allow-origin': origin,
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-headers': 'authorization,apikey,content-type,x-client-info',
};

function mockEndpoint(versionBody, { preflightStatus = 204, versionStatus = 405, versionCors = cors } = {}) {
  const calls = [];
  return {
    calls,
    async request(url, init) {
      calls.push(init.method);
      assert.equal(url, 'https://project.example/functions/v1/ai-daily-companion');
      assert.equal(init.body, undefined, 'diagnostico nunca envia diario ou chama geracao');
      assert.equal(init.headers.Authorization, undefined);
      assert.equal(init.headers.apikey, undefined);
      if (init.method === 'OPTIONS') return new Response(null, { status: preflightStatus, headers: cors });
      assert.equal(init.method, 'GET');
      return new Response(JSON.stringify(versionBody), { status: versionStatus, headers: versionCors });
    },
  };
}

test('rejeita a versao antiga mesmo quando o CORS passa', async () => {
  const endpoint = mockEndpoint({ code: 'METHOD_NOT_ALLOWED', functionVersion: 'daily-companion-v5' });
  assert.equal(await checkDailyCompanionWeb('https://project.example', origin, endpoint.request), false);
  assert.deepEqual(endpoint.calls, ['OPTIONS', 'GET']);
});

test('confirma a versao local sem autenticacao nem geracao', async () => {
  const endpoint = mockEndpoint({ code: 'METHOD_NOT_ALLOWED', functionVersion: expectedFunctionVersion });
  assert.equal(await checkDailyCompanionWeb('https://project.example', origin, endpoint.request), true);
});

test('interrompe quando o preflight falha', async () => {
  const endpoint = mockEndpoint(null, { preflightStatus: 403 });
  assert.equal(await checkDailyCompanionWeb('https://project.example', origin, endpoint.request), false);
  assert.deepEqual(endpoint.calls, ['OPTIONS']);
});

test('nao confunde erro de gateway ou versao ausente com contrato valido', async () => {
  for (const [body, options] of [
    [{ code: 'METHOD_NOT_ALLOWED' }, {}],
    ['Bad Gateway', { versionStatus: 502 }],
    [{ code: 'METHOD_NOT_ALLOWED', functionVersion: expectedFunctionVersion }, { versionCors: {} }],
    [{ code: 'METHOD_NOT_ALLOWED', functionVersion: expectedFunctionVersion }, { versionStatus: 200 }],
  ]) {
    const endpoint = mockEndpoint(body, options);
    assert.equal(await checkDailyCompanionWeb('https://project.example', origin, endpoint.request), false);
  }
});
