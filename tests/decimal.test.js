'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const D = require('../src/decimal.js');

test('parses and canonicalizes decimal strings without precision loss', () => {
  assert.equal(D.toString(D.parseDecimal('000')), '0');
  assert.equal(D.toString(D.parseDecimal('00012.340000')), '12.34');
  assert.equal(D.toString(D.parseDecimal('0.000000000000000001')), '0.000000000000000001');
  assert.equal(D.toString(D.parseDecimal('9999999999999999.123456789012345678')), '9999999999999999.123456789012345678');
});
test('rejects malformed, exponent, whitespace, negative and excessive precision inputs', () => {
  for (const value of ['', ' 1', '1 ', '1e-8', '.1', '1.', '+1', '--1']) assert.throws(() => D.parseDecimal(value));
  assert.throws(() => D.parseDecimal('-1'));
  assert.throws(() => D.parseDecimal('0.1234567890123456789'));
  assert.throws(() => D.parseDecimal('10000000000000000'));
  assert.throws(() => D.parseDecimal('0.123456789', { maxFractionDigits: 8 }));
  assert.equal(D.toString(D.parseDecimal('-1.25', { allowNegative: true })), '-1.25');
});
test('compares, adds and subtracts exactly at 18 places', () => {
  assert.equal(D.compareDecimal('0.000000000000000009', '0.000000000000000010'), -1);
  assert.equal(D.addDecimal('0.000000000000000009', '0.000000000000000001'), '0.00000000000000001');
  assert.equal(D.subtractDecimal('1.000000000000000001', '0.000000000000000001'), '1');
});
test('multiplies and divides using integer arithmetic with half-away-from-zero rounding', () => {
  assert.equal(D.multiplyDecimal('1.23456789', '2', 8), '2.46913578');
  assert.equal(D.multiplyDecimal('1.005', '1', 2), '1.01');
  assert.equal(D.multiplyDecimal('-1.005', '1', 2), '-1.01');
  assert.equal(D.divideDecimal('1', '3', 8), '0.33333333');
  assert.equal(D.divideDecimal('1', '6', 2), '0.17');
  assert.throws(() => D.divideDecimal('1', '0', 8), /zero/);
});
test('formats exact values without binary floating point', () => {
  assert.equal(D.formatDecimal('1234567.123456789012345678'), '1,234,567.123456789012345678');
  assert.equal(D.formatDecimal('1.123456789012345678', { maxFractionDigits: 8 }), '1.12345679');
  assert.equal(D.formatDecimal('1', { minFractionDigits: 2 }), '1.00');
});
test('property-style arithmetic invariants hold for a deterministic value set', () => {
  const values = ['0', '0.1', '1.000000000000000001', '999.999999999999999999', '123456789.123456789123456789'];
  for (const a of values) for (const b of values) {
    assert.equal(D.compareDecimal(a, b) + D.compareDecimal(b, a), 0);
    assert.equal(D.subtractDecimal(D.addDecimal(a, b, 18), b, 18), D.formatDecimal(a, { maxFractionDigits: 18, grouping: false }));
  }
});
test('canonical RPC arguments remain decimal strings and obey the current 8-place database gate', () => {
  const amount = D.toString(D.parseDecimal('0001.23000000', { maxFractionDigits: 8, maxIntegerDigits: 16 }));
  const price = D.toString(D.parseDecimal('0.00000001', { maxFractionDigits: 8, maxIntegerDigits: 16 }));
  const payload = JSON.parse(JSON.stringify({ p_amount: amount, p_limit_price: price }));
  assert.equal(payload.p_amount, '1.23');
  assert.equal(payload.p_limit_price, '0.00000001');
  assert.equal(typeof payload.p_amount, 'string');
  assert.equal(typeof payload.p_limit_price, 'string');
});
