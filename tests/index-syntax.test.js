'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('index.html', 'utf8');

test('all inline JavaScript blocks in index.html parse successfully', () => {
  const scripts = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)]
    .filter(([, attrs, body]) => !/\bsrc\s*=/.test(attrs) && !/application\/(?:ld\+)?json/i.test(attrs) && body.trim());
  assert.ok(scripts.length > 0, 'expected inline JavaScript');
  scripts.forEach(([, attrs, body], index) => {
    const filename = 'index.html:inline-script-' + (index + 1);
    try {
      new vm.Script(body, { filename });
    } catch (error) {
      throw new Error(filename + ': ' + (error.stack || error.message), { cause: error });
    }
  });
});

test('trading RPC call sites preserve decimal strings and avoid floating-point conversions', () => {
  const flows = [
    ['async function trade(side){', '\n\nlet orderBookTimer', ['p_amount:amount', 'p_price:price']],
    ['async function placeLimitOrder(){', '\nasync function placeConditionalExitOrder()', ['p_amount:amount', 'p_limit_price:price']],
    ['async function placeConditionalExitOrder(){', '\nasync function loadConditionalOrders()', ['p_amount:amount', 'p_trigger_price:trigger']],
    ['async function placeStopLimitOrder(){', '\nasync function loadStopLimitOrders()', ['p_amount:amount', 'p_stop_price:stop', 'p_limit_price:limit']]
  ];
  for (const [startToken, endToken, expected] of flows) {
    const start = html.indexOf(startToken);
    const end = html.indexOf(endToken, start);
    assert.ok(start >= 0 && end > start, 'function boundary found: ' + startToken);
    const body = html.slice(start, end);
    for (const field of expected) assert.ok(body.includes(field), 'expected RPC argument ' + field);
    assert.doesNotMatch(body, /\b(?:Number|parseFloat)\s*\(|\.toFixed\s*\(/);
  }
});

test('the current production schema compatibility gate stays at 8 fractional digits', () => {
  assert.match(html, /const ORDER_INPUT_MAX_FRACTION_DIGITS=8/);
  assert.match(fs.readFileSync('sw.js', 'utf8'), /'\.\/src\/decimal\.js'/);
});