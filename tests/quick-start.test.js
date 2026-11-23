'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const html = fs.readFileSync('index.html', 'utf8');

test('quick-start guide is available from settings and explains the demo-only boundary', () => {
  assert.match(html, /id="quickStartGuide"/);
  assert.match(html, /راهنمای شروع سریع DigiArz/);
  assert.match(html, /Market یا Limit یا Stop-Limit/);
  assert.match(html, /موجودی و معاملات مجازی‌اند/);
});
