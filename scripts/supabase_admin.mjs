import { existsSync, readFileSync } from 'node:fs';
import { parseEnv } from 'node:util';
import { homedir } from 'node:os';
import { join } from 'node:path';

const local = existsSync('.env') ? parseEnv(readFileSync('.env', 'utf8')) : {};
export const env = { ...local, ...process.env };
export const base = new URL(env.SUPABASE_URL).origin;
export const projectRef = new URL(base).hostname.split('.')[0];

export async function request(url, { method, body, headers = {} } = {}) {
  const response = await fetch(url, {
    method: method ?? (body === undefined ? 'GET' : 'POST'),
    headers: { 'Content-Type': 'application/json', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(45000),
  });
  const raw = await response.text();
  let data;
  try { data = raw ? JSON.parse(raw) : null; } catch { data = null; }
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${data?.code ?? data?.error_code ?? 'request_failed'} (${new URL(url).pathname})`);
  }
  return data;
}

export function api(path, body, { token, admin = false, method, headers = {} } = {}) {
  const key = admin
    ? (env.SUPABASE_SECRET_KEY || env.SERVICE_ROLE_KEY)
    : (env.SUPABASE_PUBLISHABLE_KEY || env.SUPABASE_ANON_KEY);
  if (!key) throw new Error('Credencial Supabase ausente.');
  return request(`${base}${path}`, {
    method, body,
    headers: {
      apikey: key,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(admin && key.split('.').length === 3 ? { Authorization: `Bearer ${key}` } : {}),
      ...headers,
    },
  });
}

export function management(path, body, method) {
  const token = env.SUPABASE_ACCESS_TOKEN || readFileSync(
    join(homedir(), '.supabase', 'access-token'), 'utf8',
  ).trim();
  return request(`https://api.supabase.com/v1/projects/${projectRef}${path}`, {
    body, method, headers: { Authorization: `Bearer ${token}` },
  });
}
