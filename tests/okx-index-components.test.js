'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { parseOkxIndexComponents } = require('../src/okx-index-components.js');

function fixture(name) {
  return JSON.parse(fs.readFileSync(path.join(__dirname, '../docs/superpowers/fixtures', name), 'utf8'));
}

test('parses captured OKX BTC index components without binary floating point', () => {
  const f = fixture('2026-11-18-okx-index-components-btc-usdt.json');
  const parsed = parseOkxIndexComponents(JSON.stringify(f.response), 'BTC-USDT');
  assert.equal(parsed.provider, 'OKX');
  assert.equal(parsed.schemaVersion, 'okx-index-components-v1');
  assert.equal(parsed.indexPrice, '64372.2');
  assert.equal(parsed.providerTimestampMs, '1794999591686');
  assert.equal(parsed.components.length, 5);
  assert.equal(parsed.componentWeightTotal, '1');
  assert.deepEqual(parsed.components.map(x => x.exchangeLabelRaw), ['Coinbase', 'Bitget', 'Binance', 'OKX', 'Bybit']);
  assert.equal(parsed.components[0].spotPairRaw, 'BTC/USD');
  assert.equal(parsed.components[0].sourcePrice, '64292.37');
  assert.equal(parsed.components[0].convertedPrice, '64367.6801858174063654');
  assert.ok(Object.isFrozen(parsed));
  assert.ok(Object.isFrozen(parsed.components));
});

test('parses captured OKX ETH index components and preserves decimal strings', () => {
  const f = fixture('2026-11-18-okx-index-components-eth-usdt.json');
  const parsed = parseOkxIndexComponents(JSON.stringify(f.response), 'ETH-USDT');
  assert.equal(parsed.indexPrice, '1807.08');
  assert.equal(parsed.componentWeightTotal, '1');
  assert.equal(parsed.components[3].spotPairRaw, 'ETH/USD');
  assert.equal(parsed.components[3].convertedPrice, '1807.0442417628625491');
});

test('rejects invalid status, index mismatch, malformed timestamp and non-exact weights', () => {
  const f = fixture('2026-11-18-okx-index-components-btc-usdt.json');
  const body = f.response;
  assert.throws(() => parseOkxIndexComponents(JSON.stringify({ ...body, code: '500' }), 'BTC-USDT'), /not successful/);
  assert.throws(() => parseOkxIndexComponents(JSON.stringify(body), 'ETH-USDT'), /does not match/);
  assert.throws(() => parseOkxIndexComponents(JSON.stringify({ ...body, data: { ...body.data, ts: '123' } }), 'BTC-USDT'), /13-digit/);
  const badWeights = { ...body, data: { ...body.data, components: body.data.components.map((c, i) => i ? c : { ...c, wgt: '0.2' }) } };
  assert.throws(() => parseOkxIndexComponents(JSON.stringify(badWeights), 'BTC-USDT'), /sum exactly to 1/);
});

test('rejects duplicate exchange/pair rows and array-shaped component objects', () => {
  const f = fixture('2026-11-18-okx-index-components-btc-usdt.json');
  const duplicated = { ...f.response, data: { ...f.response.data, components: [...f.response.data.components, { ...f.response.data.components[0] }] } };
  assert.throws(() => parseOkxIndexComponents(JSON.stringify(duplicated), 'BTC-USDT'), /duplicate exchange and spot pair/);
  const arrayComponent = { ...f.response, data: { ...f.response.data, components: f.response.data.components.map((c, i) => i ? c : []) } };
  assert.throws(() => parseOkxIndexComponents(JSON.stringify(arrayComponent), 'BTC-USDT'), /must be an object/);
  const arrayData = { ...f.response, data: [] };
  assert.throws(() => parseOkxIndexComponents(JSON.stringify(arrayData), 'BTC-USDT'), /not successful/);
});

test('rejects numeric JSON values and malformed component prices instead of coercing them', () => {
  const f = fixture('2026-11-18-okx-index-components-btc-usdt.json');
  const numericPrice = { ...f.response, data: { ...f.response.data, last: 64372.2 } };
  assert.throws(() => parseOkxIndexComponents(JSON.stringify(numericPrice), 'BTC-USDT'), /decimal string/);
  const malformed = { ...f.response, data: { ...f.response.data, components: f.response.data.components.map((c, i) => i ? c : { ...c, cnvPx: '6.4e4' }) } };
  assert.throws(() => parseOkxIndexComponents(JSON.stringify(malformed), 'BTC-USDT'), /decimal string/);
});
