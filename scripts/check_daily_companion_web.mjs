#!/usr/bin/env node

// Reproduz o preflight do navegador sem token, diario ou chamada ao modelo.
import { readFileSync } from 'node:fs';

const originArgument = process.argv[2];
if (!originArgument) {
  console.error('Uso: node scripts/check_daily_companion_web.mjs <origem-do-app>');
  process.exit(2);
}

function httpOrigin(value) {
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
    throw new Error('Informe uma URL HTTP(S) sem credenciais.');
  }
  return url.origin;
}

try {
  const origin = httpOrigin(originArgument);
  let supabaseUrl = process.env.SUPABASE_URL;
  if (!supabaseUrl) {
    const env = readFileSync(new URL('../.env', import.meta.url), 'utf8');
    supabaseUrl = env.match(/^\s*SUPABASE_URL\s*=\s*(.*?)\s*$/m)?.[1]
      .replace(/^(['"])(.*)\1$/, '$2');
  }
  if (!supabaseUrl) throw new Error('Defina SUPABASE_URL no ambiente ou no .env.');
  const endpoint = `${httpOrigin(supabaseUrl)}/functions/v1/ai-daily-companion`;
  const requestedHeaders = ['authorization', 'apikey', 'content-type', 'x-client-info'];
  const response = await fetch(endpoint, {
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
    process.exitCode = 1;
  } else {
    console.log('CORS OK. Este teste não valida sessão, consentimento ou geração.');
  }
} catch (error) {
  console.error(`Não foi possível verificar o preflight: ${error.message}`);
  process.exitCode = 1;
}
