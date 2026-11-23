'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const html = fs.readFileSync('index.html', 'utf8');
const script = fs.readFileSync('src/low-power.js', 'utf8');

test('low-power mode is user-controlled from settings and only throttles automatic market refresh', () => {
  assert.match(html, /id="lowPowerModeToggle"/);
  assert.match(html, /id="lowPowerModeMsg"/);
  assert.match(html, /DigiArzLowPower\.shouldRefresh\(\)/);
  assert.match(script, /ticks = \(ticks \+ 1\) % 5/);
  assert.match(script, /localStorage\.setItem\(KEY, value \? 'true' : 'false'\)/);
  assert.match(html, /به‌روزرسانی دستی و عملیات حساب\/سفارش تغییر نمی‌کنند/);
});
