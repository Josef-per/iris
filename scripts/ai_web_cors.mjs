// Diagnostico publico: nenhum token, diario ou chamada ao modelo.
export const aiFunctionNames = ['ai-daily-companion', 'ai-support-recommend'];
export const aiRequestHeaders = ['authorization', 'apikey', 'content-type', 'x-client-info'];

export function httpOrigin(value) {
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
    throw new Error('Informe uma URL HTTP(S) sem credenciais.');
  }
  return url.origin;
}

export function buildWebOrigin(env) {
  return env.IRIS_WEB_ORIGIN ||
    (env.VERCEL_ENV === 'production' && env.VERCEL_PROJECT_PRODUCTION_URL
      ? `https://${env.VERCEL_PROJECT_PRODUCTION_URL}` : '');
}

export async function checkAiWebCors(supabaseUrl, originArgument, request = fetch) {
  const origin = httpOrigin(originArgument);
  const base = httpOrigin(supabaseUrl);
  const checks = await Promise.all(aiFunctionNames.map(async (name) => {
    const response = await request(`${base}/functions/v1/${name}`, {
      method: 'OPTIONS',
      headers: {
        Origin: origin,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': aiRequestHeaders.join(','),
      },
      signal: AbortSignal.timeout(10000),
    });
    const allowedOrigin = response.headers.get('access-control-allow-origin');
    const values = (header) => (response.headers.get(header) ?? '')
      .toLowerCase().split(',').map((value) => value.trim());
    return {
      name, status: response.status, allowedOrigin,
      valid: response.ok && allowedOrigin === origin &&
        values('access-control-allow-methods').includes('post') &&
        aiRequestHeaders.every((header) => values('access-control-allow-headers').includes(header)),
    };
  }));
  for (const check of checks) {
    console.log(`${check.name}: preflight HTTP ${check.status}, origem ${check.allowedOrigin ?? '(ausente)'}`);
  }
  if (checks.some((check) => !check.valid)) {
    console.error(`CORS bloqueia a IA em ${origin}. Inclua essa origem em AI_SUPPORT_ALLOWED_ORIGINS no Supabase publicado.`);
    console.error('Preserve as outras origens. Editar o .env local ou recompilar não atualiza esse secret.');
    return false;
  }
  return true;
}
