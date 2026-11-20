'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const workerSource = fs.readFileSync('sw.js', 'utf8');
const manifest = JSON.parse(fs.readFileSync('manifest.webmanifest', 'utf8'));

function createHarness(fetchImpl = async () => ({ ok: true, clone() { return this; } })) {
  const listeners = new Map();
  const stored = new Map();
  const added = [];
  const deleted = [];
  const cacheNames = ['digiarz-shell-v53', 'digiarz-shell-v54', 'digiarz-shell-v55', 'digiarz-shell-v56', 'digiarz-shell-v57', 'digiarz-shell-v58', 'digiarz-shell-v59', 'digiarz-shell-v60', 'digiarz-shell-v61', 'digiarz-shell-v62', 'digiarz-shell-v63', 'digiarz-shell-v64', 'digiarz-shell-v65', 'digiarz-shell-v66', 'digiarz-shell-v67', 'digiarz-shell-v68', 'digiarz-shell-v69', 'digiarz-shell-v70', 'digiarz-shell-v71', 'digiarz-shell-v72'];
  const workerUrl = 'https://app.example/DigiArz/sw.js';
  const resolveKey = request => typeof request === 'string'
    ? new URL(request, workerUrl).href
    : request.url;
  const cache = {
    async addAll(urls) {
      for (const item of urls) {
        const key = resolveKey(item);
        added.push(key);
        stored.set(key, { ok: true, cachedShellAsset: key });
      }
    },
    async match(request) { return stored.get(resolveKey(request)) || null; },
    async put(request, response) { stored.set(resolveKey(request), response); }
  };
  let skipped = false;
  let claimed = false;
  const self = {
    location: { origin: 'https://app.example', href: workerUrl },
    registration: { scope: 'https://app.example/DigiArz/' },
    clients: { async claim() { claimed = true; } },
    async skipWaiting() { skipped = true; },
    addEventListener(type, callback) { listeners.set(type, callback); }
  };
  const caches = {
    async open() { return cache; },
    async keys() { return [...cacheNames]; },
    async delete(name) { deleted.push(name); return true; }
  };
  vm.runInNewContext(workerSource, { self, caches, fetch: fetchImpl, URL, Promise }, { filename: 'sw.js' });
  return { listeners, stored, added, deleted, cacheNames, get skipped() { return skipped; }, get claimed() { return claimed; } };
}

function dispatchFetch(harness, request) {
  let responsePromise;
  harness.listeners.get('fetch')({ request, respondWith(value) { responsePromise = Promise.resolve(value); } });
  return responsePromise;
}

test('PWA manifest keeps the app installable as a Persian RTL standalone experience', () => {
  assert.equal(manifest.lang, 'fa');
  assert.equal(manifest.dir, 'rtl');
  assert.equal(manifest.display, 'standalone');
  assert.equal(manifest.orientation, 'portrait-primary');
  for (const icon of ['./icon-192.svg', './icon-512.svg']) {
    assert.ok(manifest.icons.some(item => item.src === icon), 'manifest includes ' + icon);
  }
});

test('install precaches the complete offline shell, including Android manifest icons', async () => {
  const harness = createHarness();
  let installPromise;
  harness.listeners.get('install')({ waitUntil(value) { installPromise = Promise.resolve(value); } });
  await installPromise;
  assert.equal(harness.added.length, 11);
  assert.ok(harness.added.includes('https://app.example/DigiArz/icon-192.svg'));
  assert.ok(harness.added.includes('https://app.example/DigiArz/icon-512.svg'));
  assert.ok(harness.added.includes('https://app.example/DigiArz/src/market-holdings.js'));
  assert.ok(harness.added.includes('https://app.example/DigiArz/src/daily-ads.js'));
  assert.ok(harness.added.includes('https://app.example/DigiArz/src/pwa-install.js'));
  assert.ok(harness.added.includes('https://app.example/DigiArz/src/digiarz-independent-ui.css?v=16'));
  assert.equal(harness.skipped, true);
});

test('external Supabase/API requests and non-GET requests bypass the worker cache', () => {
  const harness = createHarness();
  assert.equal(dispatchFetch(harness, { method: 'GET', mode: 'cors', url: 'https://project.supabase.co/rest/v1/orders' }), undefined);
  assert.equal(dispatchFetch(harness, { method: 'POST', mode: 'cors', url: 'https://app.example/DigiArz/submit' }), undefined);
});

test('unlisted same-origin GET responses are fetched but never written to Cache Storage', async () => {
  const response = { ok: true, body: 'user-specific response', clone() { return this; } };
  const harness = createHarness(async () => response);
  const result = await dispatchFetch(harness, { method: 'GET', mode: 'cors', url: 'https://app.example/DigiArz/private-profile.json' });
  assert.equal(result, response);
  assert.equal(harness.stored.has('https://app.example/DigiArz/private-profile.json'), false);
});

test('successful app navigation refreshes only the canonical offline index shell', async () => {
  const response = { ok: true, body: 'latest index', clone() { return { ok: true, body: this.body }; } };
  const harness = createHarness(async () => response);
  const result = await dispatchFetch(harness, { method: 'GET', mode: 'navigate', url: 'https://app.example/DigiArz/' });
  assert.equal(result, response);
  assert.equal(harness.stored.get('https://app.example/DigiArz/index.html').body, 'latest index');
  assert.equal(harness.stored.has('https://app.example/DigiArz/private-profile.json'), false);
});

test('offline navigation falls back to the cached app shell', async () => {
  const harness = createHarness(async () => { throw new Error('offline'); });
  const cachedIndex = { ok: true, body: 'cached shell' };
  harness.stored.set('https://app.example/DigiArz/index.html', cachedIndex);
  const result = await dispatchFetch(harness, { method: 'GET', mode: 'navigate', url: 'https://app.example/DigiArz/' });
  assert.equal(result, cachedIndex);
});

test('activation removes old shell caches and claims clients', async () => {
  const harness = createHarness();
  let activatePromise;
  harness.listeners.get('activate')({ waitUntil(value) { activatePromise = Promise.resolve(value); } });
  await activatePromise;
  assert.deepEqual(harness.deleted, ['digiarz-shell-v53', 'digiarz-shell-v54', 'digiarz-shell-v55', 'digiarz-shell-v56', 'digiarz-shell-v57', 'digiarz-shell-v58', 'digiarz-shell-v59', 'digiarz-shell-v60', 'digiarz-shell-v61', 'digiarz-shell-v62', 'digiarz-shell-v63', 'digiarz-shell-v64', 'digiarz-shell-v65', 'digiarz-shell-v66', 'digiarz-shell-v67', 'digiarz-shell-v68', 'digiarz-shell-v69', 'digiarz-shell-v70', 'digiarz-shell-v71', 'digiarz-shell-v72']);
  assert.equal(harness.claimed, true);
});
