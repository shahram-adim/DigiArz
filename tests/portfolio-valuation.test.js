'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const D = require('../src/decimal.js');
globalThis.DigiDecimal = D;
const P = require('../src/portfolio-valuation.js');

test('portfolio market value multiplies precise quantity and price without binary float drift', () => {
  assert.equal(P.value('0.12345678', '12345.678901234567890123'), '1524.15787515');
  assert.equal(P.value('0.00000001', '0.00000001'), '0');
});

test('portfolio total sums wallet and asset values at the database-supported eight decimals', () => {
  assert.equal(P.sum(['0.1', '0.2', '0.00000001', '999999999999.12345678']), '999999999999.42345679');
});

test('invalid and negative balances are never counted as positive holdings', () => {
  assert.equal(P.positiveOrZero('-12.5'), '0');
  assert.equal(P.positiveOrZero('NaN'), '0');
  assert.equal(P.positiveOrZero('0.00000001'), '0.00000001');
});

test('malformed market values are rejected instead of contaminating portfolio totals', () => {
  assert.equal(P.value('1.25', 'invalid'), null);
  assert.throws(() => P.sum(['1', 'bad']), /Invalid portfolio amount/);
});

test('portfolio valuation retains the expected eight-place precision', () => {
  assert.equal(P.value('1.23456789', '2.00000001'), '2.46913590');
});
