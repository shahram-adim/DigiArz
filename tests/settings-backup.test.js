'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { validate } = require('../src/settings-backup.js');

test('settings backup accepts only supported preference values', () => {
  assert.deepEqual(validate({
    format: 'DigiArz-settings', version: 1,
    preferences: { theme: 'luxury', currency: 'toman', favorites: ['BTC','ETH','BTC'] }
  }), { theme: 'luxury', currency: 'toman', favorites: ['BTC','ETH'] });
});

test('settings backup rejects unknown format and unsupported theme', () => {
  assert.throws(() => validate({ format: 'other', version: 1, preferences: { theme: 'dark' } }));
  assert.throws(() => validate({ format: 'DigiArz-settings', version: 1, preferences: { theme: 'system' } }));
});

test('settings backup rejects malformed or oversized favorites collections', () => {
  assert.throws(() => validate({ format: 'DigiArz-settings', version: 1, preferences: { favorites: ['BTC/USDT'] } }));
  assert.throws(() => validate({ format: 'DigiArz-settings', version: 1, preferences: { favorites: Array(501).fill('BTC') } }));
});

test('settings backup never accepts account credentials or wallet data as preferences', () => {
  assert.throws(() => validate({ format: 'DigiArz-settings', version: 1, preferences: { password: 'secret', wallet: { balance: 10 } } }));
});
