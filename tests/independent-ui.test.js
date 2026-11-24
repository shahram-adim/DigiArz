const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('src/digiarz-independent-ui.css', 'utf8');
const sw = fs.readFileSync('sw.js', 'utf8');

test('independent stylesheet loads after all inline styles and before the document closes', () => {
  const link = '<link rel="stylesheet" href="./src/digiarz-independent-ui.css?v=2">';
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

test('obsolete five-gainer and five-loser panels are removed while market summaries and asset lists remain', () => {
  assert.doesNotMatch(html, /topGainersList|topLosersList|allGainersBtn|allLosersBtn/);
  assert.doesNotMatch(html, /<section class="gainers-panel/);
  assert.doesNotMatch(html, /function renderTopGainers|function renderTopLosers|function showAllGainers|function showAllLosers/);
  assert.match(html, /id="marketAvgChange"/);
  assert.match(html, /id="marketTopGain"/);
  assert.match(html, /id="marketTopLoss"/);
  assert.match(html, /id="topAssetsList"/);
  assert.match(html, /id="marketList"/);
  assert.match(html, /id="dashboardMarketPreview"/);
});

test('premium mobile refinement prevents market price collisions and gives the three themes distinct identities', () => {
  const marker = 'DigiArz premium mobile refinement v4';
  const finalRules = css.slice(css.lastIndexOf(marker));
  assert.ok(finalRules.length > 0, 'device-driven premium refinement exists');
  for (const token of [
    'grid-template-areas:"fav identity spark change price"',
    'grid-area:change!important',
    'grid-area:price!important',
    'display:none!important',
    'border-bottom:1px solid var(--da-line)!important',
    'body.dark-theme #marketList>.coin',
    'body.light-theme #marketList>.coin',
    'body.luxury-theme #marketList>.coin',
    'max(7px,env(safe-area-inset-bottom))',
    'grid-template-columns:28px minmax(94px,1.16fr)'
  ]) assert.ok(finalRules.includes(token), 'premium mobile rules include ' + token);
  assert.match(finalRules, /--da-accent:#e7b94d!important/);
  assert.match(finalRules, /--da-bg:#fff!important/);
  assert.match(finalRules, /--da-accent:#a9b7ff!important/);
});

test('service worker precaches the new stylesheet under a fresh shell cache', () => {
  assert.match(sw, /digiarz-shell-v60/);
  assert.match(sw, /digiarz-independent-ui\.css\?v=1/);
});

test('mobile layouts and reduced-motion accessibility rules are present', () => {
  assert.match(css, /@media\(max-width:360px\)/);
  assert.match(css, /@media\(max-width:760px\)/);
  assert.match(css, /@media\(prefers-reduced-motion:reduce\)/);
  assert.equal((css.match(/\{/g) || []).length, (css.match(/\}/g) || []).length);
});

test('indigo glass dashboard preview overrides legacy cards with refined frameless rows', () => {
  const oldBlue = css.indexOf('body.luxury-theme #dashboardMarketPreview .da-market-coin-card{background:linear-gradient(145deg,#102c43,#0b2034)');
  const premium = css.lastIndexOf('body.dark-theme #dashboardMarketPreview .da-market-coin-card,');
  assert.ok(oldBlue >= 0, 'legacy dashboard palette remains identifiable');
  assert.ok(premium > oldBlue, 'premium row refinement comes after legacy rules');
  const finalPalette = css.slice(premium, premium + 900);
  assert.match(finalPalette, /border:0!important/);
  assert.match(finalPalette, /border-bottom:1px solid var\(--da-line\)!important/);
  assert.match(finalPalette, /background:transparent!important/);
});

test('hidden authentication view stays hidden despite the ID-based layout rule', () => {
  const layoutRule = css.indexOf('#authView{display:grid!important;');
  const hiddenRule = css.lastIndexOf('#authView.hidden{display:none!important}');
  assert.ok(layoutRule >= 0, 'independent auth layout rule exists');
  assert.ok(hiddenRule > layoutRule, 'hidden-state override follows the layout rule');
});

test('history and order feeds use stable keyset pagination with timestamp and ID tie-breakers', () => {
  assert.match(html, /historyCursor=historyRows\.length\?historyRows\[historyRows\.length-1\]:null/);
  assert.match(html, /created_at\.lt\.\\?\$\{cursor\.created_at\},and\(created_at\.eq\.\\?\$\{cursor\.created_at\},id\.lt\.\\?\$\{cursor\.id\}\)/);
  assert.match(html, /allOrdersPageSize=100/);
  assert.match(html, /id="loadMoreOrdersBtn"/);
  assert.match(html, /loadMoreAllOrders\(\)/);
  assert.doesNotMatch(html, /range\(offset,offset\+historyPageSize-1\)/);
  assert.doesNotMatch(html, /\.limit\(200\)/);
});

test('luxury theme final overrides neutralize legacy sky-blue auth and dashboard accents', () => {
  const marker = '/* Final luxury palette harmonization: neutralize legacy sky-blue login and dashboard accents. */';
  const finalRules = css.slice(css.lastIndexOf(marker));
  assert.ok(finalRules.length > 0, 'final palette harmonization block exists');
  for (const token of [
    'rgba(43,37,91,.82)', 'rgba(183,168,255,.30)', '#30275f',
    '#b7a8ff', '#d0c6ff', 'body.luxury-theme .da-v2-coin',
    'body.luxury-theme .mobile-bottom-nav button.active'
  ]) assert.ok(finalRules.includes(token), 'final indigo rules include ' + token);
  assert.ok(css.lastIndexOf('body.luxury-theme #authView.auth-reference-layout') > css.indexOf('background:rgba(239,249,255,.92)'));
});

test('full indigo-glass foundation covers trading wallet and navigation surfaces', () => {
  const marker = '/* Full indigo-glass theme foundation for every application surface. */';
  const foundation = css.slice(css.lastIndexOf(marker));
  assert.ok(foundation.length > 0);
  for (const token of [
    '--bg:#111027!important', '--panel:rgba(31,26,72,.78)!important',
    'body.luxury-theme .tabs', 'body.luxury-theme .mobile-bottom-nav',
    'body.luxury-theme .trade-box', 'body.luxury-theme .asset-row',
    'body.luxury-theme .advanced-order-form-v36',
    'body.luxury-theme .orders-center-v36',
    'body.luxury-theme input', 'body.luxury-theme #priceChart'
  ]) assert.ok(foundation.includes(token), 'indigo foundation includes ' + token);
  assert.match(html, /luxury\?\{bg:'#111027',text:'#f3f0ff',grid:'#30275f',line:'#7565c4'\}/);
  assert.match(html, /luxury\?'#111027'/);
  assert.ok(!html.includes('لوکس شیشه‌ای'));
});

test('light theme stays pure white across app surfaces with no grey backgrounds', () => {
  const marker = '/* DigiArz theme 2 final correction: pure-white glass, no grey/blue-grey surfaces. */';
  const finalRules = css.slice(css.lastIndexOf(marker));
  assert.ok(finalRules.length > 0, 'pure-white theme override exists');
  for (const token of [
    'background:#ffffff!important', 'background-color:#ffffff!important',
    'background:rgba(255,255,255,.94)!important', 'background:#ffffff!important;border:1px solid',
    'body.light-theme input', 'body.light-theme #authView .auth-form',
    'body.light-theme #marketList>.coin'
  ]) assert.ok(finalRules.includes(token), 'pure-white override includes ' + token);
  assert.match(finalRules, /--da-bg:#ffffff;--da-bg2:#ffffff/);
  assert.doesNotMatch(finalRules, /background(?:-color)?:\s*#(?:eef3fb|e5edf8|edf4f6|e8f1f4|f7faff|eaf1fa|f3f6fc|d1e1e5|d4e3e7)/i);
});
