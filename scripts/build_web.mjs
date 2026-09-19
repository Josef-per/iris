import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { parseEnv } from 'node:util';
import { spawnSync } from 'node:child_process';
import { prepareLanding } from './prepare_landing.mjs';

const local = existsSync('.env') ? parseEnv(readFileSync('.env', 'utf8')) : {};
const value = (name) => (process.env[name] ?? local[name] ?? '').trim();
const url = value('SUPABASE_URL');
const key = value('SUPABASE_PUBLISHABLE_KEY') || value('SUPABASE_ANON_KEY');
if (!url || !key || new URL(url).protocol !== 'https:') {
  throw new Error('Defina SUPABASE_URL HTTPS e SUPABASE_PUBLISHABLE_KEY.');
}
let publicKey = key.startsWith('sb_publishable_');
if (!publicKey && key.split('.').length === 3) {
  try {
    publicKey = JSON.parse(Buffer.from(key.split('.')[1], 'base64url')).role === 'anon';
  } catch { /* A chave precisa ser publica e valida antes de compilar. */ }
}
if (!publicKey) throw new Error('O build aceita somente chave publicavel ou anon.');
const defines = [
  `--dart-define=SUPABASE_URL=${url}`,
  `--dart-define=SUPABASE_PUBLISHABLE_KEY=${key}`,
];
// Sem override, o aplicativo usa a propria origem web para o callback.
const redirect = value('SUPABASE_AUTH_REDIRECT_URL');
if (redirect) {
  if (new URL(redirect).protocol !== 'https:') throw new Error('Callback deve usar HTTPS.');
  defines.push(`--dart-define=SUPABASE_AUTH_REDIRECT_URL=${redirect}`);
}
function run(command, args) {
  const result = spawnSync(command, args, { stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
const flutter = process.env.IRIS_FLUTTER_BIN || 'flutter';
run(flutter, ['pub', 'get', '--enforce-lockfile']);
run(flutter, ['build', 'web', '--release', '--no-pub', ...defines]);
prepareLanding();
run('bash', ['scripts/check_client_bundle.sh', 'build/web']);

// Permite publicar somente os arquivos compilados pelo CLI da Vercel.
const config = JSON.parse(readFileSync('vercel.json', 'utf8'));
config.buildCommand = '';
config.outputDirectory = '.';
writeFileSync('build/web/vercel.json', `${JSON.stringify(config, null, 2)}\n`);
writeFileSync('build/web/.vercelignore', '.env*\n.vercel\n.gitignore\n*.map\n');
