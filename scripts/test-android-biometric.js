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

test('deferred startup leaves email login available until the user chooses fingerprint', async () => {
  const plugin = makePlugin();
  const original = makeStorage(plugin);
  const value = JSON.stringify({ access_token: 'saved-access', refresh_token: 'saved-refresh' });
  await original.setItem('digiarz.auth.session.v1', value);
  const callsBeforeChoice = plugin.calls.filter(call => call === 'getSecureData').length;
  const deferred = makeStorage(plugin, { deferBiometricPrompt: true });

  assert.equal(await deferred.getItem('digiarz.auth.session.v1'), null);
  assert.equal(plugin.calls.filter(call => call === 'getSecureData').length, callsBeforeChoice);
  assert.equal(await deferred.hasSecureSession(), true);

  assert.equal(await deferred.unlock(), value);
  assert.equal(plugin.calls.filter(call => call === 'getSecureData').length, callsBeforeChoice + 1);
  assert.equal(await deferred.getItem('digiarz.auth.session.v1'), value);
});

test('cancellation preserves encrypted data and explicit retry can unlock', async () => {
  const plugin = makePlugin();
  const storage = makeStorage(plugin);
  const value = '{"access_token":"a","refresh_token":"r"}';
  await storage.setItem('digiarz.auth.session.v1', value);
  plugin.state.failRead = true;
  storage.lock();
  assert.equal(await storage.getItem('digiarz.auth.session.v1'), null);
  assert.equal(storage.isLocked(), true);
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
test('writes arriving after a background lock never repopulate decrypted memory', async () => {
  const plugin = makePlugin();
  const storage = makeStorage(plugin);
  const key = 'digiarz.auth.session.v1';
  await storage.setItem(key, '{"access_token":"before","refresh_token":"before"}');
  storage.lock();
  const rotated = '{"access_token":"after","refresh_token":"rotated"}';
  await storage.setItem(key, rotated);
  assert.equal(storage.isLocked(), true);
  assert.equal(storage.hasCachedSession(), false);
  assert.equal(plugin.state.saved, true);
  assert.equal(plugin.state.value, rotated);
  assert.equal(await storage.unlock(), rotated);
  assert.equal(storage.isLocked(), false);
});

test('a write already in flight cannot undo a background lock', async () => {
  let releaseWrite;
  const gate = new Promise(resolve => { releaseWrite = resolve; });
  const plugin = makePlugin();
  const originalSetData = plugin.setData;
  plugin.setData = async ({ value }) => {
    await gate;
    return originalSetData({ value });
  };
  const storage = makeStorage(plugin);
  const key = 'digiarz.auth.session.v1';
  const write = storage.setItem(key, '{"access_token":"late","refresh_token":"late"}');
  await Promise.resolve();
  storage.lock();
  releaseWrite();
  await write;
  assert.equal(storage.isLocked(), true);
  assert.equal(storage.hasCachedSession(), false);
  assert.equal(plugin.state.saved, true);
});

test('native biometric session writes mark the prompt active until secure storage completes', async () => {
  let releaseWrite;
  let startedWrite;
  const gate = new Promise(resolve => { releaseWrite = resolve; });
  const started = new Promise(resolve => { startedWrite = resolve; });
  const plugin = makePlugin();
  const originalSetData = plugin.setData;
  plugin.setData = async ({ value }) => {
    startedWrite();
    await gate;
    return originalSetData({ value });
  };
  const storage = makeStorage(plugin);
  const write = storage.setItem('digiarz.auth.session.v1', '{"access_token":"a","refresh_token":"r"}');
  await started;
  assert.equal(storage.isPromptInProgress(), true);
  releaseWrite();
  await write;
  assert.equal(storage.isPromptInProgress(), false);
  assert.equal(plugin.state.saved, true);
});
