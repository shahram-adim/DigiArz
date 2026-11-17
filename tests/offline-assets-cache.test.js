'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const sw = fs.readFileSync('sw.js', 'utf8');

test('offline cache is versioned and only covers approved static app scripts', () => {
  assert.match(sw, /digiarz-shell-v56/);
  assert.match(sw, /url\.hostname === 'gfoaubfilhttnwjykaox\.supabase\.co'/);
  assert.match(sw, /url\.pathname === '\/functions\/v1\/app-assets'/);
  assert.match(sw, /\['supabase', 'charts', 'lucide'\]\.includes\(url\.searchParams\.get\('asset'\)\)/);
  assert.match(sw, /request\.destination === 'script'/);
});

test('approved app scripts use network-first with cached offline fallback', () => {
  assert.match(sw, /const response = await fetch\(request\)/);
  assert.match(sw, /await cache\.put\(request, response\.clone\(\)\)/);
  assert.match(sw, /const cached = await cache\.match\(request\);\s*if \(cached\) return cached;/);
});

test('other cross-origin requests are not intercepted or cached', () => {
  assert.match(sw, /if \(url\.origin !== self\.location\.origin\) return;/);
  assert.match(sw, /Never cache Supabase API\/function requests or arbitrary/);
});
