'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createSecureStorage, MAX_SECURE_BYTES } = require('../src/android-biometric-lock.js');

function makePlugin(overrides) {
  const calls = [];
  const state = { saved: false, value: null, available: true, failRead: false, failWrite: false };
  const plugin = {
    calls,
    state,
    async isAvailable() { calls.push('isAvailable'); return { isAvailable: state.available, strongBiometryIsAvailable: state.available }; },
    async isDataSaved() { calls.push('isDataSaved'); return { isSaved: state.saved }; },
    async getSecureData() {
      calls.push('getSecureData');
      if (state.failRead) throw new Error('cancelled');
      if (!state.saved) throw new Error('missing');
      return { value: state.value };
    },
    async setData({ value }) {
      calls.push('setData');
      if (state.failWrite) throw new Error('keystore failure');
      state.value = value;
      state.saved = true;
    },
    async deleteData() { calls.push('deleteData'); state.value = null; state.saved = false; }
  };
  return Object.assign(plugin, overrides || {});
}

function makeStorage(plugin, extra) {
  const local = new Map();
  const localStorage = {
    getItem: key => local.has(key) ? local.get(key) : null,
    setItem: (key, value) => local.set(key, value),
    removeItem: key => local.delete(key)
  };
  return createSecureStorage(Object.assign({
    plugin, localStorage, storageKey: 'digiarz.auth.session.v1',
    secureKey: 'digiarz.auth.session.v1'
  }, extra || {}));
}

test('stores the Supabase session using strong biometric protection', async () => {
  const plugin = makePlugin();
  const storage = makeStorage(plugin);
  const value = JSON.stringify({ access_token: 'a', refresh_token: 'r' });
  await storage.setItem('digiarz.auth.session.v1', value);
  assert.equal(plugin.state.saved, true);
  assert.equal(plugin.state.value, value);
  assert.equal(await storage.getItem('digiarz.auth.session.v1'), value);
  assert.ok(plugin.calls.includes('setData'));
});

test('cancellation preserves encrypted data and explicit retry can unlock', async () => {
  const plugin = makePlugin();
  const storage = makeStorage(plugin);
  const value = '{"access_token":"a","refresh_token":"r"}';
  await storage.setItem('digiarz.auth.session.v1', value);
  plugin.state.failRead = true;
  storage.lock();
  assert.equal(await storage.getItem('digiarz.auth.session.v1'), null);
  assert.equal(plugin.state.saved, true);
  plugin.state.failRead = false;
  assert.equal(await storage.unlock(), value);
  assert.equal(plugin.state.saved, true);
});

test('does not persist plaintext when strong biometrics are unavailable', async () => {
  const plugin = makePlugin();
  plugin.state.available = false;
  const storage = makeStorage(plugin);
  await storage.setItem('digiarz.auth.session.v1', '{"token":"x"}');
  assert.equal(plugin.state.saved, false);
  assert.equal(storage.hasCachedSession(), true);
});

test('does not persist oversized sessions and does not silently downgrade', async () => {
  const plugin = makePlugin();
  const storage = makeStorage(plugin);
  const oversized = 'x'.repeat(MAX_SECURE_BYTES + 1);
  await storage.setItem('digiarz.auth.session.v1', oversized);
  assert.equal(plugin.state.saved, false);
  assert.equal(storage.hasCachedSession(), true);
});

test('explicit logout deletes the protected session; lock preservation does not', async () => {
  const plugin = makePlugin();
  const storage = makeStorage(plugin);
  await storage.setItem('digiarz.auth.session.v1', '{"token":"x"}');
  storage.preserveDeletes(true);
  await storage.removeItem('digiarz.auth.session.v1');
  assert.equal(plugin.state.saved, true);
  storage.preserveDeletes(false);
  await storage.removeItem('digiarz.auth.session.v1');
  assert.equal(plugin.state.saved, false);
});

test('auxiliary Supabase PKCE keys stay separate from the encrypted session', async () => {
  const plugin = makePlugin();
  const storage = makeStorage(plugin);
  await storage.setItem('digiarz.auth.session.v1-code-verifier', 'verifier');
  assert.equal(await storage.getItem('digiarz.auth.session.v1-code-verifier'), 'verifier');
  assert.equal(plugin.calls.includes('setData'), false);
});
