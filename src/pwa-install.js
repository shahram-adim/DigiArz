'use strict';
(() => {
  const banner = document.getElementById('pwaInstallBanner');
  const button = document.getElementById('pwaInstallBtn');
  if (!banner || !button) return;

  let deferredInstallPrompt = null;
  const hideBanner = () => banner.classList.add('hidden');

  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault();
    deferredInstallPrompt = event;
    button.disabled = false;
    banner.classList.remove('hidden');
  });

  button.addEventListener('click', async () => {
    if (!deferredInstallPrompt || button.disabled) return;
    const installEvent = deferredInstallPrompt;
    deferredInstallPrompt = null;
    button.disabled = true;
    try {
      await installEvent.prompt();
      await installEvent.userChoice;
    } catch (error) {
      console.warn('DigiArz install prompt was not completed:', error);
    } finally {
      button.disabled = false;
      hideBanner();
    }
  });

  window.addEventListener('appinstalled', hideBanner);
})();
