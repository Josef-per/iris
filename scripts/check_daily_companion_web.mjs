#!/usr/bin/env node

// Verifica CORS e a versao publicada sem token, diario ou chamada ao modelo.
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const localSource = readFileSync(new URL('../supabase/functions/ai-daily-companion/index.ts', import.meta.url), 'utf8');
export const expectedFunctionVersion = localSource.match(/const functionVersion = "([^"]+)";/)?.[1];

function httpOrigin(value) {
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
    throw new Error('Informe uma URL HTTP(S) sem credenciais.');
  }
  return url.origin;
}

export async function checkDailyCompanionWeb(supabaseUrl, originArgument, request = fetch) {
  const origin = httpOrigin(originArgument);
  if (!expectedFunctionVersion) throw new Error('Versao local da reflexao ausente.');
  const endpoint = `${httpOrigin(supabaseUrl)}/functions/v1/ai-daily-companion`;
  const requestedHeaders = ['authorization', 'apikey', 'content-type', 'x-client-info'];
  const response = await request(endpoint, {
    method: 'OPTIONS',
    headers: {
      Origin: origin,
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': requestedHeaders.join(','),
    },
    signal: AbortSignal.timeout(10000),
  });
  const allowedOrigin = response.headers.get('access-control-allow-origin');
  const allowedHeaders = (response.headers.get('access-control-allow-headers') ?? '')
    .toLowerCase().split(',').map((value) => value.trim());
  const allowedMethods = (response.headers.get('access-control-allow-methods') ?? '')
    .toUpperCase().split(',').map((value) => value.trim());
  const valid = response.ok && allowedOrigin === origin &&
    allowedMethods.includes('POST') &&
    requestedHeaders.every((header) => allowedHeaders.includes(header));

  console.log(`Origem do aplicativo: ${origin}`);
  console.log(`Preflight da reflexão: HTTP ${response.status}`);
  console.log(`Origem autorizada: ${allowedOrigin ?? '(ausente)'}`);
  if (!valid) {
    console.error('FALHA: o navegador não consegue enviar a requisição da reflexão.');
    console.error('Confira AI_SUPPORT_ALLOWED_ORIGINS nos secrets do projeto Supabase.');
    console.error('Inclua a origem acima na lista existente, separada por vírgulas.');
    return false;
  }

  // GET retorna 405 antes de autenticar, ler contexto ou gerar uma reflexao.
  const versionResponse = await request(endpoint, {
    method: 'GET', headers: { Origin: origin }, signal: AbortSignal.timeout(10000),
  });
  let data;
  try { data = await versionResponse.json(); } catch { data = null; }
  const deployedVersion = typeof data?.functionVersion === 'string' &&
      /^daily-companion-v\d+$/.test(data.functionVersion) ? data.functionVersion : null;
  console.log(`Versão local: ${expectedFunctionVersion}`);
  console.log(`Versão publicada: ${deployedVersion ?? '(não identificada)'}`);
  if (versionResponse.status !== 405 || data?.code !== 'METHOD_NOT_ALLOWED' ||
      versionResponse.headers.get('access-control-allow-origin') !== origin ||
      deployedVersion !== expectedFunctionVersion) {
    console.error('FALHA: a função publicada não confirmou o contrato local.');
    console.error('Confira a migration 0014 e publique ai-daily-companion antes de distribuir o aplicativo.');
    return false;
  }
  console.log('CORS e versão OK. Este teste não valida banco, sessão, consentimento ou geração.');
  return true;
}

async function main() {
  const originArgument = process.argv[2];
  if (!originArgument) {
    console.error('Uso: node scripts/check_daily_companion_web.mjs <origem-do-app>');
    process.exitCode = 2;
    return;
  }
  try {
    let supabaseUrl = process.env.SUPABASE_URL;
    if (!supabaseUrl) {
      const env = readFileSync(new URL('../.env', import.meta.url), 'utf8');
      supabaseUrl = env.match(/^\s*SUPABASE_URL\s*=\s*(.*?)\s*$/m)?.[1]
        .replace(/^(['"])(.*)\1$/, '$2');
    }
    if (!supabaseUrl) throw new Error('Defina SUPABASE_URL no ambiente ou no .env.');
    if (!(await checkDailyCompanionWeb(supabaseUrl, originArgument))) process.exitCode = 1;
  } catch (error) {
    console.error(`Não foi possível verificar a reflexão: ${error.message}`);
    process.exitCode = 1;
  }
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) await main();
