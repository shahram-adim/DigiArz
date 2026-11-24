const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('src/digiarz-independent-ui.css', 'utf8');
const sw = fs.readFileSync('sw.js', 'utf8');

test('independent stylesheet loads after all inline styles and before the document closes', () => {
  const link = '<link rel="stylesheet" href="./src/digiarz-independent-ui.css?v=1">';
  assert.ok(html.includes(link));
  assert.ok(html.indexOf(link) > html.lastIndexOf('</style>'));
  assert.ok(html.indexOf(link) < html.lastIndexOf('</body>'));
});

test('authentication, dashboard, market, wallet, orders and history hooks are preserved', () => {
  for (const id of [
    'authView', 'appView', 'loginBtn', 'signupBtn', 'tradePairBadge',
    'priceChart', 'assetList', 'allOrdersList', 'historyBody', 'marketList'
  ]) {
    assert.match(html, new RegExp('id="' + id + '"'));
  }
  assert.match(html, /function applyTheme\(theme\)/);
  assert.match(html, /\['light','dark','luxury'\]\.includes\(theme\)/);
});

test('three themes use distinct black-gold, translucent light and indigo-glass palettes', () => {
  assert.match(css, /body\.dark-theme\{[\s\S]*?--da-accent:#f0b90b/);
  assert.match(css, /body\.light-theme\{[\s\S]*?--da-surface:rgba\(255,255,255,\.68\)/);
  assert.match(css, /body\.luxury-theme\{[\s\S]*?--da-bg:#111027[\s\S]*?--da-accent:#b7a8ff/);
  assert.match(css, /body\.luxury-theme[\s\S]*?backdrop-filter:blur\(18px\)/);
});

test('market rows and coin logos remain frameless in all themes', () => {
  assert.match(css, /#marketList>\.coin,\.market-list>#marketList>\.coin\{\s*border:0!important;outline:0!important;box-shadow:none!important/);
  assert.match(css, /#marketList>\.coin \.coin-icon,#marketList>\.coin \.coin-icon img\{\s*border:0!important/);
  assert.match(css, /body\.light-theme #marketList>\.coin/);
  assert.match(css, /body\.dark-theme #marketList>\.coin/);
  assert.match(css, /body\.luxury-theme #marketList>\.coin/);
});

test('service worker precaches the new stylesheet under a fresh shell cache', () => {
  assert.match(sw, /digiarz-shell-v59/);
  assert.match(sw, /digiarz-independent-ui\.css\?v=1/);
});

test('mobile layouts and reduced-motion accessibility rules are present', () => {
  assert.match(css, /@media\(max-width:360px\)/);
  assert.match(css, /@media\(max-width:760px\)/);
  assert.match(css, /@media\(prefers-reduced-motion:reduce\)/);
  assert.equal((css.match(/\{/g) || []).length, (css.match(/\}/g) || []).length);
});

test('indigo glass dashboard preview overrides the legacy sky-blue palette', () => {
  const oldBlue = css.indexOf('body.luxury-theme #dashboardMarketPreview .da-market-coin-card{background:linear-gradient(145deg,#102c43,#0b2034)');
  const indigo = css.lastIndexOf('body.luxury-theme #dashboardMarketPreview .da-market-coin-card{');
  assert.ok(oldBlue >= 0, 'legacy dashboard palette remains identifiable');
  assert.ok(indigo > oldBlue, 'final indigo override comes after legacy rules');
  const finalPalette = css.slice(indigo, indigo + 600);
  assert.match(finalPalette, /#30275f/);
  assert.match(finalPalette, /#1b1744/);
  assert.match(finalPalette, /rgba\(183,168,255/);
});

test('hidden authentication view stays hidden despite the ID-based layout rule', () => {
  const layoutRule = css.indexOf('#authView{display:grid!important;');
  const hiddenRule = css.lastIndexOf('#authView.hidden{display:none!important}');
  assert.ok(layoutRule >= 0, 'independent auth layout rule exists');
  assert.ok(hiddenRule > layoutRule, 'hidden-state override follows the layout rule');
});
