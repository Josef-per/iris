import { copyFileSync, existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

// Keep Flutter at its original base path so assets and existing deep links work.
export function prepareLanding(directory = 'build/web') {
  if (!existsSync(`${directory}/flutter_bootstrap.js`)) {
    throw new Error('Compile o Flutter web antes de preparar a landing page.');
  }
  if (readFileSync(`${directory}/index.html`, 'utf8').includes('flutter_bootstrap.js')) {
    copyFileSync(`${directory}/index.html`, `${directory}/app.html`);
  } else if (!existsSync(`${directory}/app.html`)) {
    throw new Error('O documento de entrada do Flutter não foi encontrado.');
  }
  copyFileSync(`${directory}/landing/index.html`, `${directory}/index.html`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  prepareLanding(process.argv[2]);
}
