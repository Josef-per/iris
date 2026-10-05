import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { parseEnv } from 'node:util';
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import { prepareLanding } from './prepare_landing.mjs';

function fail(message) {
  console.error(`Erro de configuração: ${message}`);
  process.exit(1);
}
const envFile = process.env.IRIS_ENV_FILE || '.env';
if (process.env.IRIS_ENV_FILE && !existsSync(envFile)) {
  fail('Arquivo indicado por IRIS_ENV_FILE não encontrado.');
}
const local = existsSync(envFile) ? parseEnv(readFileSync(envFile, 'utf8')) : {};
const value = (name) => (process.env[name] ?? local[name] ?? '').trim();
const url = value('SUPABASE_URL');
const key = value('SUPABASE_PUBLISHABLE_KEY') || value('SUPABASE_ANON_KEY');
const missing = [];
if (!url) missing.push('SUPABASE_URL');
if (!key) missing.push('SUPABASE_PUBLISHABLE_KEY (ou SUPABASE_ANON_KEY)');
if (missing.length) {
  fail(`Faltam ${missing.join(' e ')}. Adicione os valores públicos ao .env ` +
    'da raiz, ao arquivo indicado por IRIS_ENV_FILE ou às variáveis de ambiente. ' +
    'Consulte .env.example e docs/deploy_vercel.md.');
}
function isHttps(value) {
  try { return new URL(value).protocol === 'https:'; }
  catch { return false; }
}
if (!isHttps(url)) fail('SUPABASE_URL deve ser uma URL HTTPS válida.');
let publicKey = key.startsWith('sb_publishable_');
if (!publicKey && key.split('.').length === 3) {
  try {
    publicKey = JSON.parse(Buffer.from(key.split('.')[1], 'base64url')).role === 'anon';
  } catch { /* A chave precisa ser publica e valida antes de compilar. */ }
}
if (!publicKey) fail('O build aceita somente chave publicável ou anon.');
const defines = [
  `--dart-define=SUPABASE_URL=${url}`,
  `--dart-define=SUPABASE_PUBLISHABLE_KEY=${key}`,
];
// Sem override, o aplicativo usa a propria origem web para o callback.
const redirect = value('SUPABASE_AUTH_REDIRECT_URL');
if (redirect) {
  if (!isHttps(redirect)) fail('SUPABASE_AUTH_REDIRECT_URL deve ser uma URL HTTPS válida.');
  defines.push(`--dart-define=SUPABASE_AUTH_REDIRECT_URL=${redirect}`);
}
// Valida antes de instalar o SDK ou iniciar a compilação.
if (process.argv.includes('--check-config')) process.exit(0);
function run(command, args) {
  // Node on Windows cannot spawn a .bat file directly without a shell.
  // Send arguments on stdin so a public build value cannot become shell code.
  const result = process.platform === 'win32' && command === flutter
    ? spawnSync('powershell.exe', [
      '-NoProfile', '-NonInteractive', '-Command',
      '$irisInvocation = [Console]::In.ReadToEnd() | ConvertFrom-Json; ' +
      '$irisCommand = [string]$irisInvocation.command; ' +
      '$irisArgs = [string[]]$irisInvocation.args; ' +
      '& $irisCommand @irisArgs; exit $LASTEXITCODE',
    ], {
      input: JSON.stringify({ command: command === 'flutter' ? 'flutter.bat' : command, args }),
      stdio: ['pipe', 'inherit', 'inherit'],
    })
    : spawnSync(command, args, { stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
function checkClientBundle(directory) {
  if (!existsSync(directory)) throw new Error(`Bundle não encontrado: ${directory}`);
  const markers = [
    'SUPABASE_SECRET_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'SERVICE_ROLE_KEY',
    'sb_secret_', 'OPENAI_API_KEY', 'OPENAI_ORG_ID', 'sk-proj-',
  ];
  const pending = [directory];
  while (pending.length) {
    const current = pending.pop();
    for (const entry of readdirSync(current, { withFileTypes: true })) {
      const path = join(current, entry.name);
      if (entry.isDirectory()) pending.push(path);
      if (!entry.isFile()) continue;
      if (/^\.env(?:\..*)?$/.test(entry.name)) {
        throw new Error('Falha: arquivo de ambiente encontrado no bundle.');
      }
      const contents = readFileSync(path);
      if (markers.some((marker) => contents.includes(marker))) {
        throw new Error('Falha: marcador de segredo encontrado no bundle.');
      }
    }
  }
  console.log('Bundle sem marcadores conhecidos de segredo.');
}
const flutter = process.env.IRIS_FLUTTER_BIN || 'flutter';
run(flutter, ['pub', 'get', '--enforce-lockfile']);
run(flutter, ['build', 'web', '--release', '--no-pub', ...defines]);
prepareLanding();
if (process.platform === 'win32') checkClientBundle('build/web');
else run('bash', ['scripts/check_client_bundle.sh', 'build/web']);

// Permite publicar somente os arquivos compilados pelo CLI da Vercel.
const config = JSON.parse(readFileSync('vercel.json', 'utf8'));
config.buildCommand = '';
config.outputDirectory = '.';
writeFileSync('build/web/vercel.json', `${JSON.stringify(config, null, 2)}\n`);
writeFileSync('build/web/.vercelignore', '.env*\n.vercel\n.gitignore\n*.map\n');
