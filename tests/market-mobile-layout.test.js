import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const style = html.match(/<style id="digiarz-professional-mobile-refresh">([\s\S]*?)<\/style>/)?.[1] ?? '';

test('professional market layout stylesheet is present exactly once', () => {
  assert.ok(style.length > 1000, 'final market layout stylesheet should be present');
  assert.equal((html.match(/digiarz-professional-mobile-refresh/g) ?? []).length, 1);
});

test('all five market-row children have explicit grid positions', () => {
  for (const selector of [
    '.coin>.favorite-btn{grid-column:1',
    '.coin-identity{grid-column:2',
    '.coin-sparkline{grid-column:3',
    '.coin-change-wrap{grid-column:4',
    '.coin>.price-stack{grid-column:5',
  ]) assert.ok(style.includes(selector), `missing explicit market grid placement: ${selector}`);
});

test('mobile market rows use bounded columns and prevent horizontal overflow', () => {
  assert.match(style, /@media\(max-width:700px\)[\s\S]*?#tab-markets \.coin\{grid-template-columns:28px minmax\(0,1fr\) 42px 62px 86px/);
  assert.match(style, /html,body\{max-width:100%;overflow-x:clip\}/);
  assert.match(style, /#tab-markets \.coin\{[^}]*min-width:0!important/);
});

test('dark and light themes both define readable market text', () => {
  assert.match(style, /#tab-markets \.coin-name-fa\{[^}]*color:#eef4fb!important/);
  assert.match(style, /body\.light-theme #tab-markets \.coin-name-fa\{color:#1c2938!important\}/);
  assert.match(style, /body\.light-theme #tab-markets \.price-usd strong\{color:#24364b!important\}/);
});
