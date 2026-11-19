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

test('mobile bottom navigation allocates one column per six app sections', () => {
  assert.ok(style.includes('.mobile-bottom-nav{position:fixed!important;z-index:130!important;inset:auto 0 0!important;display:grid!important;grid-template-columns:repeat(6,minmax(0,1fr))!important;'));
});

test('failed coin logos render a deliberate branded fallback instead of broken-image chrome', () => {
  assert.ok(style.includes('.coin-identity .coin-icon.coin-logo-fallback{display:grid!important;place-items:center'));
  assert.ok(style.includes('color:#f3ca70!important'));
});

test('English DigiArz wordmark remains left-to-right inside the RTL header', () => {
  assert.ok(html.includes('<div class="brand"><bdi dir="ltr">Digi<span>Arz</span></bdi><span class="tag">DEMO</span></div>'));
  assert.ok(style.includes('.brand>bdi{direction:ltr;unicode-bidi:isolate'));
});

test('dashboard market preview keeps long prices inside the card on mobile', () => {
  assert.match(html, /#dashboardMarketPreview\.dashboard-market-preview\.da-v2-market-list>\.da-market-coin-card\{[\s\S]*?minmax\(120px,1\.4fr\)/);
  assert.match(html, /#dashboardMarketPreview \.da-market-price,[\s\S]*?min-width:0!important;max-width:100%!important;overflow:hidden!important/);
  assert.match(html, /@media\(max-width:390px\)[\s\S]*?minmax\(110px,1\.5fr\)/);
});

test('dashboard market preview has readable colors in light theme', () => {
  assert.match(html, /body\.light-theme #dashboardMarketPreview \.da-market-name-wrap b\{color:#1c2938!important\}/);
  assert.match(html, /body\.light-theme #dashboardMarketPreview \.da-market-price\{color:#26364b!important\}/);
  assert.match(html, /body\.light-theme #dashboardMarketPreview \.da-market-toman\{color:#13835f!important\}/);
});

test('no JavaScript or markup is appended after the closing HTML document', () => {
  const closingTag = html.toLowerCase().lastIndexOf('</html>');
  assert.notEqual(closingTag, -1, 'document must contain a closing html tag');
  assert.match(html.slice(closingTag + '</html>'.length), /^\\s*$/, 'nothing may render after the document and appear as raw source text');
});
