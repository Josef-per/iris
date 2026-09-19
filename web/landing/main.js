// Preserve existing auth callbacks and bookmarked Flutter hash routes.
const authKeys = ['code', 'access_token', 'refresh_token', 'error', 'error_code', 'token_hash'];
const query = new URLSearchParams(location.search);
const fragment = new URLSearchParams(location.hash.slice(1));
if (authKeys.some(key => query.has(key) || fragment.has(key)) || location.hash.startsWith('#/')) {
  location.replace(`/app${location.search}${location.hash}`);
}

const installButton = document.querySelector('#install-button');
const status = document.querySelector('#install-status');
const dialog = document.querySelector('#install-dialog');
let installPrompt;

function markInstalled() {
  installButton.textContent = 'Íris adicionado à tela inicial';
  installButton.disabled = true;
  status.textContent = 'Tudo pronto! Abra o aplicativo para continuar.';
}

if (matchMedia('(display-mode: standalone)').matches || navigator.standalone) markInstalled();

window.addEventListener('beforeinstallprompt', event => {
  event.preventDefault();
  installPrompt = event;
});
window.addEventListener('appinstalled', () => {
  installPrompt = undefined;
  markInstalled();
});

function showInstructions() {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const isAndroid = /Android/.test(navigator.userAgent);
  document.querySelector('#dialog-instructions').textContent = isIOS
    ? 'Abra o Íris no Safari. Toque em Compartilhar, escolha Adicionar à Tela de Início e confirme em Adicionar.'
    : isAndroid
      ? 'Abra o Íris no Chrome. Toque no menu ⋮ e escolha Adicionar à tela inicial ou Instalar aplicativo, se disponível. Confirme para criar o atalho.'
      : 'Abra o Íris no Chrome ou Edge e procure a opção de instalar aplicativo na barra de endereços ou no menu do navegador. No celular, use as instruções para Android ou iPhone nesta página.';
  dialog.showModal();
}

installButton.addEventListener('click', async () => {
  if (!installPrompt) return showInstructions();
  const prompt = installPrompt;
  installPrompt = undefined;
  try {
    await prompt.prompt();
    const { outcome } = await prompt.userChoice;
    if (outcome === 'accepted') markInstalled();
    else status.textContent = 'Você pode adicionar depois ou abrir o app no navegador.';
  } catch {
    showInstructions();
  }
});
dialog.querySelector('.dialog-close').addEventListener('click', () => dialog.close());
dialog.addEventListener('click', event => {
  if (event.target === dialog) {
    const bounds = dialog.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
  }
});
