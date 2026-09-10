import { existsSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { management, base, projectRef, env } from './supabase_admin.mjs';

const argument = process.argv[2];
if (!argument) throw new Error('Uso: node scripts/configure_supabase_web.mjs https://dominio-do-app');
const parsed = new URL(argument);
if (parsed.protocol !== 'https:' || parsed.username || parsed.password || parsed.pathname !== '/' || parsed.search || parsed.hash) {
  throw new Error('Informe somente a origem HTTPS do aplicativo.');
}
const origin = parsed.origin;
const auth = await management('/config/auth');
const secrets = await management('/secrets');
const remoteValue = secrets.find((item) => item.name === 'AI_SUPPORT_ALLOWED_ORIGINS')?.value ?? '';
const hashed = /^[a-f0-9]{64}$/i.test(remoteValue);
const replacement = process.argv.includes('--replace-origins');
let origins = hashed ? (env.IRIS_EXISTING_ALLOWED_ORIGINS ?? '') : remoteValue;
if (replacement) {
  if (!env.IRIS_EXISTING_ALLOWED_ORIGINS) throw new Error('Informe IRIS_EXISTING_ALLOWED_ORIGINS para substituir a lista.');
  origins = env.IRIS_EXISTING_ALLOWED_ORIGINS;
} else if (hashed && createHash('sha256').update(origins).digest('hex') !== remoteValue) {
  throw new Error('A API retorna somente o hash das origens. Informe a lista exata em IRIS_EXISTING_ALLOWED_ORIGINS; use --replace-origins apenas para uma substituicao autorizada.');
}
for (const item of origins.split(',').map((x) => x.trim()).filter(Boolean)) {
  const url = new URL(item);
  if (!['https:', 'http:'].includes(url.protocol) || url.origin !== item) {
    throw new Error('Lista de origens invalida.');
  }
}
const backup = 'supabase-web-config.local.json';
if (!existsSync(backup)) writeFileSync(backup, JSON.stringify({
  projectRef, site_url: auth.site_url, uri_allow_list: auth.uri_allow_list,
  AI_SUPPORT_ALLOWED_ORIGINS: hashed && replacement ? null : origins,
  previous_origins_hash: hashed ? remoteValue : null,
}, null, 2), { mode: 0o600 });
const merge = (list, additions) => [...new Set([...list.split(',').map((x) => x.trim()).filter(Boolean), ...additions])].join(',');
const redirects = merge(auth.uri_allow_list ?? '', [
  origin, `${origin}/auth-callback`, 'http://localhost:8080', 'io.supabase.iris://auth-callback',
]);
const allowedOrigins = merge(origins, [origin]);
await management('/config/auth', { site_url: origin, uri_allow_list: redirects }, 'PATCH');
await management('/secrets', [{ name: 'AI_SUPPORT_ALLOWED_ORIGINS', value: allowedOrigins }], 'POST');
const verified = await management('/config/auth');
if (verified.site_url !== origin || !verified.uri_allow_list.split(',').includes(origin)) {
  throw new Error('A configuracao de autenticacao nao foi confirmada.');
}
for (const name of ['ai-daily-companion', 'ai-support-recommend']) {
  const response = await fetch(`${base}/functions/v1/${name}`, {
    method: 'OPTIONS', headers: {
      Origin: origin, 'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'authorization,apikey,content-type,x-client-info',
    }, signal: AbortSignal.timeout(15000),
  });
  if (!response.ok || response.headers.get('access-control-allow-origin') !== origin) {
    throw new Error(`CORS ainda nao confirmado: ${name}, HTTP ${response.status}. Repita apos a propagacao.`);
  }
  console.log(`${name}: origem autorizada.`);
}
console.log(`Login e IA configurados para ${origin}. Configuracao anterior em ${backup}.`);
