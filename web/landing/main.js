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

// Animate only when content enters the viewport; it stays visible if animation
// APIs are unavailable, JavaScript fails, or the user prefers reduced motion.
(() => {
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  if (motion.matches || typeof IntersectionObserver === 'undefined' ||
      typeof Element === 'undefined' || !Element.prototype.animate) return;

  const animations = new Set();
  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      const element = entry.target;
      observer.unobserve(element);
      // Keyboard navigation should never focus an invisible, delayed control.
      if (motion.matches || element.contains(document.activeElement)) continue;

      const isCard = element.matches('.feature, .screen-card');
      const index = isCard ? [...element.parentElement.children].indexOf(element) : 0;
      const animation = element.animate([
        { opacity: 0, transform: 'translateY(20px)' },
        { opacity: 1, transform: 'translateY(0)' },
      ], {
        duration: 650,
        delay: (index % 3) * 70,
        easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
        fill: 'backwards',
      });
      animations.add(animation);
      const finish = () => animations.delete(animation);
      animation.addEventListener('finish', finish, { once: true });
      animation.addEventListener('cancel', finish, { once: true });
      element.addEventListener('focusin', () => animation.cancel(), { once: true });
    }
  }, { threshold: 0.08 });

  document.querySelectorAll(
    '.hero-copy, .hero-art, .section-heading, .feature, .screen-card, ' +
    '.about-art, .about-copy, .install-panel, .install-guide',
  ).forEach(element => observer.observe(element));

  motion.addEventListener('change', event => {
    if (!event.matches) return;
    observer.disconnect();
    for (const animation of animations) animation.cancel();
    animations.clear();
  });
})();
