'use strict';
const CACHE_NAME = 'digiarz-shell-v59';
const APP_ROOT = new URL('./', self.location.href);
const APP_INDEX = new URL('index.html', APP_ROOT).href;
const APP_SHELL = ['./', './index.html', './manifest.webmanifest', './icon.svg', './icon-192.svg', './icon-512.svg', './src/decimal.js', './src/market-holdings.js', './src/daily-ads.js', './src/pwa-install.js', './src/digiarz-independent-ui.css'];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    const isAppShellNavigation = url.pathname === APP_ROOT.pathname || url.pathname === new URL('./index.html', APP_ROOT).pathname;
    event.respondWith(
      fetch(request)
        .then(response => {
          if (response && response.ok && isAppShellNavigation) {
            const copy = response.clone();
            return caches.open(CACHE_NAME).then(cache => cache.put(APP_INDEX, copy)).then(() => response);
          }
          return response;
        })
        .catch(() => caches.open(CACHE_NAME).then(cache => cache.match(APP_INDEX)))
    );
    return;
  }

  event.respondWith(
    caches.open(CACHE_NAME).then(cache => cache.match(request)).then(cached => cached || fetch(request))
  );
});
