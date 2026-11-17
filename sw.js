'use strict';
const CACHE_NAME = 'digiarz-shell-v56';
const APP_ROOT = new URL('./', self.location.href);
const APP_INDEX = new URL('index.html', APP_ROOT).href;
const APP_SHELL = ['./', './index.html', './manifest.webmanifest', './icon.svg', './icon-192.svg', './icon-512.svg', './src/decimal.js', './src/pwa-install.js'];

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

  // Cache only the three known static script assets served by our Supabase
  // asset endpoint. Never cache Supabase API/function requests or arbitrary
  // third-party resources: those remain network-only.
  const isKnownAppAsset =
    url.hostname === 'gfoaubfilhttnwjykaox.supabase.co' &&
    url.pathname === '/functions/v1/app-assets' &&
    ['supabase', 'charts', 'lucide'].includes(url.searchParams.get('asset')) &&
    request.destination === 'script';

  if (isKnownAppAsset) {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE_NAME);
      try {
        const response = await fetch(request);
        if (response && (response.ok || response.type === 'opaque')) {
          await cache.put(request, response.clone());
          return response;
        }
        return (await cache.match(request)) || response;
      } catch (error) {
        const cached = await cache.match(request);
        if (cached) return cached;
        throw error;
      }
    })());
    return;
  }

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
