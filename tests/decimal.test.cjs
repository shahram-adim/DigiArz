'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const D = require('../src/decimal.js');

test('parseDecimal preserves up to 18 fractional digits and canonicalizes zeros', () => {
  assert.equal(D.parseDecimal('00012.340000000000000001'), '12.340000000000000001');
  assert.equal(D.parseDecimal('-000.000000000000000010'), '-0.00000000000000001');
  assert.equal(D.parseDecimal('000.000'), '0');
});

test('parseDecimal rejects excess scale, excess integer range, whitespace, exponent, and non-string input', () => {
  assert.throws(() => D.parseDecimal('1.0000000000000000001'), /fractional precision/);
  assert.throws(() => D.parseDecimal('123456789012345678901.0'), /integer range/);
  assert.throws(() => D.parseDecimal(' 1.2'), /invalid decimal/);
  assert.throws(() => D.parseDecimal('1e-8'), /invalid decimal/);
  assert.throws(() => D.parseDecimal(0.1), /string/);
});

test('parseDecimal supports positive-only validation', () => {
  assert.throws(() => D.parseDecimal('-1', { allowNegative: false }), /negative/);
  assert.equal(D.parseDecimal('1', { allowNegative: false }), '1');
});

test('compareDecimal compares values without Number conversion', () => {
  assert.equal(D.compareDecimal('0.000000000000000011', '0.00000000000000001'), 1);
  assert.equal(D.compareDecimal('001.20', '1.2'), 0);
  assert.equal(D.compareDecimal('-2', '-1.99'), -1);
});

test('add and subtract are exact at a common scale', () => {
  assert.equal(D.addDecimal('0.123456789012345678', '0.000000000000000001'), '0.123456789012345679');
  assert.equal(D.subtractDecimal('1', '0.000000000000000001'), '0.999999999999999999');
});

test('multiply and divide use explicit scale and rounding', () => {
  assert.equal(D.multiplyDecimal('0.123456789012345679', '0.25', 18, 'down'), '0.030864197253086419');
  assert.equal(D.divideDecimal('1', '3', 18, 'down'), '0.333333333333333333');
  assert.equal(D.divideDecimal('1', '8', 8, 'half-up'), '0.125');
  assert.throws(() => D.divideDecimal('1', '0', 8), /division by zero/);
});

test('formatDecimal groups integer digits and trims only requested display zeros', () => {
  assert.equal(D.formatDecimal('1234567.120000000000000001', { maxFractionDigits: 18 }), '1,234,567.120000000000000001');
  assert.equal(D.formatDecimal('1.230000', { maxFractionDigits: 6 }), '1.23');
  assert.equal(D.formatDecimal('0.000000000000000001', { minFractionDigits: 2, maxFractionDigits: 18 }), '0.000000000000000001');
});


test('rounding boundaries are explicit and deterministic', () => {
  assert.equal(D.multiplyDecimal('1.0000000049', '1', 8, 'half-up'), '1');
  assert.equal(D.multiplyDecimal('1.000000005', '1', 8, 'half-up'), '1.00000001');
  assert.equal(D.multiplyDecimal('1.0000000051', '1', 8, 'half-up'), '1.00000001');
  assert.equal(D.divideDecimal('1', '6', 2, 'down'), '0.16');
  assert.equal(D.divideDecimal('1', '6', 2, 'half-up'), '0.17');
});

test('precision limits cannot be widened by caller options', () => {
  assert.throws(() => D.parseDecimal('1', { maxFractionDigits: 19 }), /fractional precision limit/);
  assert.throws(() => D.parseDecimal('1', { maxIntegerDigits: 21 }), /integer precision limit/);
});

test('parse/format and add/subtract invariants hold for exact decimal strings', () => {
  for (let i = 1; i <= 100; i++) {
    const value = `0.${String(i).padStart(3, '0')}123456789012345`;
    assert.equal(D.parseDecimal(D.formatDecimal(value, { maxFractionDigits: 18 })), D.parseDecimal(value));
    assert.equal(D.subtractDecimal(D.addDecimal(value, '0.000000000000000001'), '0.000000000000000001'), D.parseDecimal(value));
    assert.equal(D.compareDecimal(value, value), 0);
  }
});


test('arithmetic rejects results outside numeric(38,18) integer capacity', () => {
  const max = '99999999999999999999';
  assert.throws(() => D.addDecimal(max, '1'), /integer range/);
  assert.throws(() => D.multiplyDecimal(max, '10', 18), /integer range/);
});
