const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('src/digiarz-independent-ui.css', 'utf8');
const sw = fs.readFileSync('sw.js', 'utf8');

test('independent stylesheet loads after all inline styles and before the document closes', () => {
  const link = '<link rel="stylesheet" href="./src/digiarz-independent-ui.css?v=3">';
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

test('Android screenshot correction uses a two-row mobile market layout and compact opaque app chrome', () => {
  const marker = 'DigiArz mobile screenshot correction v5';
  const rules = css.slice(css.lastIndexOf(marker));
  assert.ok(rules.length > 0);
  assert.match(rules, /grid-template-areas:[\s\S]*"fav identity change price"[\s\S]*"\. spark change price"/);
  assert.match(rules, /grid-template-columns:27px minmax\(82px,1fr\) minmax\(68px,auto\) minmax\(108px,auto\)/);
  assert.match(rules, /height:76px!important;min-height:76px!important;max-height:76px!important/);
  assert.match(rules, /background:var\(--da-surface\)!important/);
  assert.match(rules, /padding-bottom:150px!important/);
});

test('service worker precaches the new stylesheet under a fresh shell cache', () => {
  assert.match(sw, /digiarz-shell-v61/);
  assert.match(sw, /digiarz-independent-ui\.css\?v=3/);
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

test('mobile market grid areas match the actual rendered row element order and data fields', () => {
  const rowStart = html.indexOf("const star=document.createElement('button')");
  const rowEnd = html.indexOf('renderLucideIcons();', rowStart);
  assert.ok(rowStart >= 0 && rowEnd > rowStart, 'market row renderer exists');
  const renderer = html.slice(rowStart, rowEnd);
  assert.match(renderer, /div\.append\(star,identity,sparkline,changeWrap,price\)/);
  assert.match(renderer, /coin-name-fa/);
  assert.match(renderer, /coin-symbol-en/);
  assert.match(renderer, /coin-english-name/);
  assert.match(renderer, /coin-change-wrap/);
  assert.match(renderer, /price-stack/);
  // Price markup is built by the shared market formatter outside the row renderer.
  assert.match(html, /class="price-usd"/);
  assert.match(html, /class="price-toman"/);
  assert.match(renderer, /observeMarketSparklines\(list\)/);

  const mobile = css.slice(css.lastIndexOf('DigiArz mobile screenshot correction v5'));
  assert.match(mobile, /grid-template-areas:[\s\S]*"fav identity change price"[\s\S]*"\. spark change price"/);
  for (const [selector, area] of [
    ['.favorite-btn', 'fav'],
    ['.coin-identity', 'identity'],
    ['.coin-sparkline', 'spark'],
    ['.coin-change-wrap', 'change'],
    ['.price-stack', 'price']
  ]) {
    assert.ok(mobile.includes(selector), 'mobile row styles include ' + selector);
    assert.ok(mobile.includes('grid-area:' + area + '!important'), 'mobile row maps ' + selector + ' to ' + area);
  }
});


test('three themes apply distinct accents and premium surfaces across shared app controls', () => {
  const marker = '/* 2026-11-24 premium theme system: shared controls and page surfaces use each theme\'s own accent. */';
  const themeCss = css.slice(css.lastIndexOf(marker));
  assert.ok(themeCss.length > 0, 'cross-page theme system exists');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    assert.ok(themeCss.includes('body.' + theme + '{'), theme + ' defines its own palette');
    assert.ok(themeCss.includes('body.' + theme + ' .card'), theme + ' styles page cards');
    assert.ok(themeCss.includes('body.' + theme + ' .tabs'), theme + ' styles navigation');
    assert.ok(themeCss.includes('body.' + theme + ' button:not('), theme + ' styles primary controls');
  }
  assert.match(themeCss, /--da-accent:#e7b94d!important/);
  assert.match(themeCss, /--da-accent:#176fc1!important/);
  assert.match(themeCss, /--da-accent:#aebaff!important/);
  assert.match(themeCss, /body\.light-theme[\s\S]*?--da-bg:#fff!important;--da-bg2:#fff!important/);
  assert.match(themeCss, /linear-gradient\(145deg,rgba\(37,47,105/);
});


test('theme identity carries through dashboard, market, trade and authentication hero surfaces', () => {
  const marker = '/* 2026-11-24 theme identity pass: unify the hero, auth and dashboard focal surfaces. */';
  const identity = css.slice(css.lastIndexOf(marker));
  assert.ok(identity.length > 0, 'theme identity layer exists');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    assert.ok(identity.includes('body.' + theme + '{'), theme + ' defines hero tokens');
    assert.ok(identity.includes('body.' + theme + ' .da-v2-hero'), theme + ' styles dashboard hero');
    assert.ok(identity.includes('body.' + theme + ' .market-hero-v34'), theme + ' styles market hero');
    assert.ok(identity.includes('body.' + theme + ' .trade-workspace-banner-v35'), theme + ' styles trade hero');
    assert.ok(identity.includes('body.' + theme + ' #authView .auth-visual'), theme + ' styles authentication visual');
    assert.ok(identity.includes('body.' + theme + ' #authView .auth-form'), theme + ' styles authentication form');
    assert.ok(identity.includes('body.' + theme + ' .da-v2-account-card'), theme + ' styles dashboard account surface');
  }
  assert.match(identity, /--da-hero-accent:#e7b94d/);
  assert.match(identity, /--da-hero-accent:#176fc1/);
  assert.match(identity, /--da-hero-accent:#b9c5ff/);
  assert.match(identity, /body\.light-theme[\s\S]*?--da-hero-bg:linear-gradient\(118deg,#ffffff 0%,#ffffff/);
  assert.match(html, /class="da-v2-hero"/);
  assert.match(html, /class="market-hero-v34"/);
  assert.match(html, /class="trade-workspace-banner-v35"/);
  assert.match(html, /class="auth-visual\b/);
});


test('wallet, orders, history and settings use all three theme identities', () => {
  const marker = '/* 2026-11-24 theme identity pass: wallet, orders, history and settings pages. */';
  const identity = css.slice(css.lastIndexOf(marker));
  assert.ok(identity.length > 0, 'page theme identity layer exists');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    for (const selector of ['.orders-center-v36', '.advanced-order-form-v36', '.advanced-order-list-v36',
      '.settings-grid .setting-row', '.history-date-presets button.active', '.toman-table th',
      '.toman-table td', '.asset-detail-head .detail-price']) {
      assert.ok(identity.includes('body.' + theme + ' ' + selector), theme + ' styles ' + selector);
    }
  }
  assert.match(identity, /body\.light-theme[\s\S]*?background:#fff!important/);
  assert.match(identity, /body\.dark-theme[\s\S]*?background:#242019!important/);
  assert.match(identity, /body\.luxury-theme[\s\S]*?background:#35418d!important/);
  for (const id of ['tab-assets', 'tab-orders', 'tab-history', 'tab-settings']) {
    assert.ok(html.includes('id="' + id + '"'), 'page exists: ' + id);
  }
  assert.ok(html.includes('da-v2-account-card'), 'wallet/account card markup exists');
});


test('admin workspace panels and account-adjustment controls follow all three theme identities', () => {
  const marker = '/* 2026-11-24 admin workspace theme pass: isolate admin panels and user adjustment cards. */';
  const adminTheme = css.slice(css.lastIndexOf(marker));
  assert.ok(adminTheme.length > 0, 'admin theme layer exists');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    for (const selector of ['#tab-admin .detail-section', '#tab-admin .admin-user-card',
      '#tab-admin .daily-ad-admin-item', '#tab-admin .admin-user-card input',
      '#tab-admin .admin-user-card select', '#tab-admin .daily-ad-admin-grid textarea']) {
      assert.ok(adminTheme.includes('body.' + theme + ' ' + selector),
        theme + ' styles ' + selector);
    }
  }
  assert.match(adminTheme, /body\.dark-theme[\s\S]*?rgba\(231,185,77/);
  assert.match(adminTheme, /body\.light-theme[\s\S]*?background:#fff!important/);
  assert.match(adminTheme, /body\.luxury-theme[\s\S]*?rgba\(48,59,132/);
  assert.match(html, /id="tab-admin"/);
  assert.match(html, /class="card admin-user-card"/);
  assert.match(html, /class="admin-adjust-grid"/);
  assert.match(html, /class="daily-ad-admin-grid"/);
  // daily-ad-admin-item is rendered by daily-ads.js at runtime, not static index.html.
  assert.ok(adminTheme.includes('.daily-ad-admin-item'), 'runtime daily-ad item receives theme styling');
});


test('login hero, market copy and authentication form preserve all three final theme identities', () => {
  const marker = '/* 2026-11-24 auth final theme pass: make login surfaces follow the selected product theme. */';
  const authTheme = css.slice(css.lastIndexOf(marker));
  assert.ok(authTheme.length > 0, 'final auth theme layer exists');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    for (const selector of ['#authView.auth-reference-layout', '#authView .auth-reference-visual', '#authView .ref-market-copy h1', '#authView .ref-coin-row', '#authView .auth-form', '#authView .auth-form input']) {
      assert.ok(authTheme.includes('body.' + theme + ' ' + selector), theme + ' styles ' + selector);
    }
  }
  assert.match(authTheme, /body\.dark-theme[\s\S]*?linear-gradient\(145deg,#090b10/);
  assert.match(authTheme, /body\.light-theme[\s\S]*?background:#fff!important/);
  assert.match(authTheme, /body\.luxury-theme[\s\S]*?linear-gradient\(145deg,#11183f/);
  assert.match(html, /id="authView" class="card auth auth-reference-layout"/);
  assert.match(html, /class="auth-form"/);
});


test('Toman market, asset detail and trading data panels keep distinct premium surfaces in all themes', () => {
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    for (const selector of [
      '#tab-toman .toman-table-wrap',
      '#tab-toman .toman-table th',
      '#tab-toman .toman-toolbar input',
      '#tab-chart .asset-detail-head',
      '#tab-chart .detail-section',
      '#tab-chart .review-form textarea',
      '#tab-trade .orderbook-side',
      '#tab-trade .timeframes button'
    ]) {
      assert.ok(css.includes('body.' + theme + ' ' + selector), theme + ' styles ' + selector);
    }
  }
  assert.match(css, /body\.light-theme #tab-toman \.toman-table th\{background:#fff!important/);
  assert.ok(css.includes('body.luxury-theme #tab-chart .detail-section,'), 'luxury detail panel participates in grouped glass-surface rules');
  assert.match(css, /@media\(max-width:720px\)[\s\S]*?#tab-toman \.toman-toolbar/);
  assert.match(html, /id="tab-toman"/);
  assert.match(html, /id="tab-chart"/);
  assert.match(html, /id="tab-trade"/);
});


test('remaining app pages keep usable layouts at narrow mobile widths', () => {
  const audit = css.slice(css.lastIndexOf('/* 2026-11-24 responsive audit: assets, orders, history, settings, admin and trade on narrow screens. */'));
  assert.ok(audit.length > 0, 'narrow-screen audit layer exists');
  for (const selector of [
    '#tab-assets .asset-tools',
    '#tab-orders .market-tools',
    '#tab-history .history-filters',
    '#tab-history .table-wrap table',
    '#tab-settings .settings-grid .setting-row',
    '#tab-settings .theme-choice-group',
    '#tab-admin .section-title',
    '#tab-admin #exchangeSyncStats',
    '#tab-trade .orderbook-grid',
    '#tab-chart .trade-grid'
  ]) {
    assert.ok(audit.includes(selector), 'responsive layout exists for ' + selector);
  }
  assert.match(audit, /@media\(max-width:560px\)/);
  assert.match(audit, /#tab-history \.table-wrap table\{min-width:540px\}/);
  assert.match(audit, /#tab-admin \.daily-ad-admin-grid>button\{width:100%;min-height:44px\}/);
  for (const id of ['tab-assets','tab-orders','tab-history','tab-settings','tab-admin','tab-trade','tab-chart']) {
    assert.match(html, new RegExp('id="' + id + '"'), 'page root exists: ' + id);
  }
});


test('account pages receive a premium theme-specific surface and responsive layout', () => {
  const marker = '/* 2026-11-24 premium account-page pass: assets, orders, history and settings. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'account-page polish layer exists');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    for (const selector of [
      '#tab-assets #assetSummary .stat',
      '#tab-assets #assetList .asset-row',
      '#tab-orders .order-history-card',
      '#tab-history .table-wrap',
      '#tab-history .table-wrap th',
      '#tab-settings .setting-row',
      '#tab-settings .theme-choice-group button[aria-pressed=true]'
    ]) {
      assert.ok(pass.includes('body.' + theme + ' ' + selector), theme + ' styles ' + selector);
    }
  }
  assert.match(pass, /@media\(max-width:720px\)/);
  assert.match(pass, /@media\(max-width:420px\)/);
  assert.match(pass, /#tab-assets #assetList \.asset-row\{[\s\S]*?border:0!important/);
  assert.match(html, /id="assetSummary"/);
  assert.match(html, /id="assetList"/);
  assert.match(html, /id="allOrdersList"/);
  assert.match(html, /id="historyBody"/);
  assert.match(html, /data-theme-choice="luxury"/);
});


test('trade and admin workspaces retain premium three-theme and narrow-screen coverage', () => {
  const marker = '/* 2026-11-24 premium trading and admin workspace pass. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'trade/admin polish layer exists');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    for (const selector of [
      '#tab-trade .trade-workspace-banner-v35',
      '#tab-trade #chartSection',
      '#tab-trade .orderbook-side',
      '#tab-admin .detail-section',
      '#tab-admin .admin-user-card'
    ]) assert.ok(pass.includes('body.' + theme + ' ' + selector), theme + ' styles ' + selector);
  }
  assert.match(pass, /#tab-trade \.trade-market-grid\{grid-template-columns:minmax\(0,1fr\)\}/);
  assert.match(pass, /#tab-admin \.daily-ad-admin-grid\{grid-template-columns:minmax\(0,1fr\)\}/);
  assert.match(pass, /@media\(max-width:380px\)/);
  for (const id of ['tab-trade','tab-admin','orderBookBids','orderBookAsks','dailyAdAdminPanel','exchangeAssetSyncPanel','adminUsersList']) {
    assert.ok(html.includes('id="' + id + '"'), 'HTML contains ' + id);
  }
});


test('dashboard market identity restores visible favorites, frameless logos and premium theme-specific rows', () => {
  const marker = '/* 2026-11-24 dashboard identity restoration: premium framed rows, visible favorites and richer theme depth. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'dashboard identity restoration layer exists');
  for (const selector of [
    '#dashboardMarketPreview.dashboard-market-preview.da-v2-market-list>.da-market-coin-card',
    '#dashboardMarketPreview .da-market-favorite',
    '#dashboardMarketPreview .da-market-logo',
    '#dashboardMarketPreview .da-market-logo-inner',
    '#tab-dashboard .da-v2-hero:before',
    '#tab-dashboard .da-v2-hero-art:before',
    '#tab-dashboard .da-v2-quick-grid button'
  ]) assert.ok(pass.includes(selector), 'dashboard identity selector exists: ' + selector);
  assert.match(pass, /#dashboardMarketPreview\s+\.da-market-favorite\s*\{[\s\S]*?border:1px solid!important/);
  assert.match(pass, /#dashboardMarketPreview\s+\.da-market-logo,#dashboardMarketPreview\s+\.da-market-logo-inner\s*\{[^}]*border:0!important/);
  assert.match(pass, /#dashboardMarketPreview\s+\.da-market-favorite\s*\{[^}]*border:1px solid!important/);
  assert.match(pass, /#dashboardMarketPreview\.dashboard-market-preview\.da-v2-market-list>\.da-market-coin-card\s*\{[\s\S]*?border:1px solid!important/);
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #dashboardMarketPreview .da-market-favorite'), theme + ' favorite frame exists');
    assert.ok(pass.includes('body.' + theme + ' #dashboardMarketPreview .da-market-logo'), theme + ' logo styling exists');
    assert.ok(pass.includes('body.' + theme + ' #dashboardMarketPreview .da-market-coin-card'), theme + ' market row has theme identity');
  }
});

test('asset detail workspace keeps premium hierarchy and responsive review/news layout', () => {
  const marker = '/* 2026-11-24 premium asset detail workspace: hierarchy, review/news cards and responsive flow. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'asset detail visual layer exists');
  for (const selector of [
    '#tab-chart .asset-detail-head',
    '#tab-chart .asset-detail-head>.asset-logo',
    '#tab-chart .asset-detail-head>.detail-price',
    '#tab-chart .detail-description',
    '#tab-chart .detail-trade .trade-box',
    '#tab-chart #reviewList',
    '#tab-chart #coinNewsList',
    '#tab-chart .review-row',
    '#tab-chart .news-item'
  ]) assert.ok(pass.includes(selector), 'asset detail selector exists: ' + selector);
  for (const theme of ['dark-theme','light-theme','luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #tab-chart'), theme + ' asset detail theme exists');
  }
  assert.match(pass, /@media\(max-width:560px\)/);
  assert.match(pass, /@media\(max-width:380px\)/);
  for (const id of ['tab-chart','detailLogo','detailName','chartSymbol','chartLastPrice','detailDescription','detailBuyBtn','detailSellBtn','reviewList','coinNewsList']) {
    assert.ok(html.includes('id="' + id + '"'), 'asset detail markup contains ' + id);
  }
});


test('Toman market table keeps price and asset identity visible while scrolling on mobile', () => {
  const marker = '/* 2026-11-24 Toman market table refinement: readable horizontal data rail on phones. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'Toman market refinement layer exists');
  for (const selector of [
    '#tab-toman .toman-table-wrap',
    '#tab-toman .toman-table thead th',
    '#tab-toman .toman-table th:first-child',
    '#tab-toman .toman-table td:first-child',
    '#tab-toman .toman-table th:nth-child(2)',
    '#tab-toman .toman-table td:nth-child(2)'
  ]) assert.ok(pass.includes(selector), 'Toman table selector exists: ' + selector);
  for (const theme of ['dark-theme','light-theme','luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #tab-toman'), theme + ' sticky cells have opaque surfaces');
  }
  assert.match(pass, /@media\(max-width:720px\)/);
  assert.match(pass, /@media\(max-width:380px\)/);
  assert.match(html, /id="tomanMarketBody"/);
  assert.match(html, /class="toman-table-wrap"/);
});


test('orders, trade history and theme settings remain usable on narrow RTL screens', () => {
  const marker = '/* 2026-11-24 order and history mobile refinement: action clarity and RTL scanability. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'orders/history responsive refinement exists');
  for (const selector of [
    '#tab-orders .order-history-card',
    '#tab-orders .order-history-card>button',
    '#tab-history .history-filters',
    '#tab-history .table-wrap',
    '#tab-history .table-wrap td:first-child',
    '#tab-settings .theme-setting-row .theme-choice-group'
  ]) assert.ok(pass.includes(selector), 'account workflow selector exists: ' + selector);
  for (const theme of ['dark-theme','light-theme','luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #tab-history .table-wrap td:first-child'), theme + ' sticky history cell surface exists');
  }
  assert.match(pass, /@media\(max-width:720px\)/);
  assert.match(pass, /@media\(max-width:380px\)/);
  for (const id of ['allOrdersList','historyBody','historySearch','historyDateFrom','historyDateTo','theme-choice']) {
    if (id !== 'theme-choice') assert.ok(html.includes('id="' + id + '"'), 'expected page control exists: ' + id);
  }
  assert.ok(html.includes('data-theme-choice="light"'));
  assert.ok(html.includes('data-theme-choice="dark"'));
  assert.ok(html.includes('data-theme-choice="luxury"'));
});


test('trading terminal keeps chart, order book and demo order forms usable on narrow RTL screens', () => {
  const marker = '/* 2026-11-24 trading terminal refinement: chart controls, depth book and demo order forms. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'trading terminal refinement layer exists');
  for (const selector of [
    '#tab-trade .timeframes',
    '#tab-trade .indicator-grid',
    '#tab-trade .market-summary',
    '#tab-trade .orderbook-side',
    '#tab-trade .orderbook-mid',
    '#tab-trade .advanced-order-form-v36 .trade-box',
    '#tab-trade .advanced-order-form-v36 .trade-box .trade-grid'
  ]) assert.ok(pass.includes(selector), 'trading terminal selector exists: ' + selector);
  for (const theme of ['dark-theme','light-theme','luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #tab-trade .indicator-panel'), theme + ' indicator surface exists');
    assert.ok(pass.includes('body.' + theme + ' #tab-trade .orderbook-side'), theme + ' order book surface exists');
  }
  assert.match(pass, /@media\(max-width:720px\)/);
  assert.match(pass, /@media\(max-width:560px\)/);
  assert.match(pass, /@media\(max-width:380px\)/);
  for (const id of ['chartTypes','timeframes','indicatorRsi','indicatorMacd','orderBookBids','orderBookAsks','buyAmount','sellAmount','placeLimitBtn','placeConditionalBtn','stopLimitSide']) {
    assert.ok(html.includes('id="' + id + '"'), 'trading control exists: ' + id);
  }
});


test('authentication hero stays visually rich and readable across all three themes', () => {
  const markerCss = '/* 2026-11-24 authentication hero refinement: cinematic responsive device/globe composition. */';
  const pass = css.slice(css.lastIndexOf(markerCss));
  assert.ok(pass.length > 0, 'authentication hero refinement layer exists');
  for (const selector of [
    '#authView .auth-visual:before',
    '#authView .auth-visual:after',
    '#authView .auth-benefits',
    '#authView .auth-benefit'
  ]) assert.ok(pass.includes(selector), 'authentication hero selector exists: ' + selector);
  for (const theme of ['dark-theme','light-theme','luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #authView .auth-visual:before'), theme + ' globe treatment exists');
    assert.ok(pass.includes('body.' + theme + ' #authView .auth-visual:after'), theme + ' device treatment exists');
    assert.ok(pass.includes('body.' + theme + ' #authView .auth-benefit'), theme + ' benefit surfaces exist');
  }
  assert.match(pass, /@media\(max-width:720px\)/);
  assert.match(pass, /@media\(max-width:560px\)/);
  assert.match(pass, /prefers-reduced-motion:reduce/);
  for (const id of ['authView','email','password','loginBtn','signupBtn']) {
    assert.ok(html.includes('id="' + id + '"'), 'authentication control exists: ' + id);
  }
});


test('dashboard workspace keeps premium hierarchy and independent surfaces across all three themes', () => {
  const marker = '/* 2026-11-24 premium dashboard pass: elevated hero, market rail, wallet and activity hierarchy. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'dashboard refinement layer exists');
  for (const selector of [
    '#tab-dashboard .da-v2-hero',
    '#tab-dashboard .da-v2-hero-art',
    '#tab-dashboard .da-v2-quick-grid',
    '#tab-dashboard .da-market-glass',
    '#tab-dashboard .da-v2-account-card',
    '#tab-dashboard .dashboard-activity-grid'
  ]) assert.ok(pass.includes(selector), 'dashboard selector exists: ' + selector);
  for (const theme of ['dark-theme','light-theme','luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #tab-dashboard .da-v2-hero'), theme + ' hero theme exists');
    assert.ok(pass.includes('body.' + theme + ' #tab-dashboard .da-market-glass'), theme + ' market surface exists');
    assert.ok(pass.includes('body.' + theme + ' #tab-dashboard .da-v2-account-card'), theme + ' wallet surface exists');
  }
  assert.match(pass, /@media\(max-width:900px\)/);
  assert.match(pass, /@media\(max-width:720px\)/);
  assert.match(pass, /@media\(max-width:560px\)/);
  assert.match(pass, /@media\(max-width:380px\)/);
  for (const id of ['tab-dashboard','dashboardMarketPreview','dashboardMarketSearch','dashboardMarketSort','usdtBalance','dashboardRecentOrders','dashboardRecentTrades','dashboardAccountAlerts']) {
    assert.ok(html.includes('id="' + id + '"'), 'dashboard markup preserves ' + id);
  }
});


test('admin operations panels preserve responsive controls and all key data regions', () => {
  const marker = '/* 2026-11-24 premium trading and admin workspace pass. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'admin responsive workspace layer exists');
  for (const selector of [
    '#tab-admin #exchangeSyncStats',
    '#tab-admin #exchangeSyncSources',
    '#tab-admin #exchangeSyncIssues',
    '#tab-admin #adminUsersList',
    '#tab-admin #adminAssetCandidates',
    '#tab-admin #adminAssetListings',
    '#tab-admin #adminPairReview',
    '#tab-admin #adminDailyAdList',
    '#tab-admin .daily-ad-admin-grid',
    '#tab-admin .detail-section .market-tools'
  ]) assert.ok(pass.includes(selector), 'admin data/control region is styled: ' + selector);
  for (const id of [
    'dailyAdAdminPanel','adminDailyAdTitle','adminDailyAdImage','adminDailyAdBody',
    'adminSaveDailyAdBtn','exchangeAssetSyncPanel','exchangeSyncStats','exchangeSyncSources',
    'exchangeSyncIssues','adminUsersList','adminAssetSearch','adminAssetCandidates',
    'adminAssetListings','adminPairReview'
  ]) assert.ok(html.includes('id="' + id + '"'), 'admin markup preserves ' + id);
  assert.ok(pass.includes('@media(max-width:560px)'), 'admin 560px breakpoint exists');
  assert.ok(pass.includes('@media(max-width:380px)'), 'admin 380px breakpoint exists');
  assert.ok(pass.includes('#tab-admin .detail-section .market-tools{display:grid'), 'admin controls stack on mobile');
  assert.ok(pass.includes('#tab-admin #exchangeSyncStats{grid-template-columns:minmax(0,1fr)}'), 'sync stats stack on narrow phones');
});


test('all active market assets receive Persian display names from curated names or English-name transliteration', () => {
  assert.match(html, /function transliterateAssetNameToPersian\(value\)/);
  assert.match(html, /function persianCoinName\(symbol,englishName=''/);
  assert.match(html, /transliterateAssetNameToPersian\(englishName\|\|coinInfo\[base\]\?\.name\|\|''\)/);
  assert.match(html, /persianCoinName\(symbol,row\.item\.name_fa\|\|row\.item\.asset_name_fa\|\|row\.item\.name_en\|\|row\.item\.asset_name_en/);
  assert.match(html, /persianCoinName\(item\.symbol,englishName\)/);
  assert.match(html, /persianCoinName\(symbol,englishName\)/);
  assert.match(html, /persianCoinName\(symbol,x\.name_fa\|\|x\.asset_name_fa/);
  assert.match(html, /asset_name_fa/);
  assert.match(html, /asset_name_en/);
});


test('dashboard hides account activity from regular users and keeps it available to admins', () => {
  assert.match(html, /id="dashboardAdminActivity"[^>]*hidden/);
  assert.match(html, /function renderDashboardActivity\(\)\{\s*const adminActivity=\$\('dashboardAdminActivity'\);if\(adminActivity\)adminActivity\.hidden=!isSuperAdmin;/);
  assert.match(html, /const englishName=String\(row\.item\.name_en\|\|row\.item\.asset_name_en\|\|row\.item\.english_name\|\|row\.item\.name\|\|coinInfo\[base\]\?\.name\|\|base\)/);
  assert.match(html, /className='da-market-name-en'/);
  assert.match(html, /name\.textContent=String\(row\.item\.name_fa\|\|row\.item\.asset_name_fa\|\|persianCoinName\(symbol,englishName\)/);
  assert.match(html, /englishName=String\(item\.name_en\|\|item\.asset_name_en\|\|item\.english_name\|\|coinInfo\[base\]\?\.name\|\|item\.name\|\|base\)/);
  assert.match(html, /class="da-v2-bottom"/);
});


test('top asset cards and wallet rows show Persian and full English names alongside the ticker', () => {
  assert.match(html, /class="top-asset-name-fa"/);
  assert.match(html, /class="top-asset-name-en" dir="ltr"/);
  assert.match(html, /const englishName=asset==='USDT'\?'Tether':String\(market\?\.name_en/);
  assert.match(html, /className='asset-name-en'/);
  assert.match(html, /label\.append\(name,english,ticker\)/);
  assert.match(css, /\.top-asset-card \.top-asset-name-en/);
  assert.match(css, /#tab-assets #assetList \.asset-row-main \.asset-name-en/);
});
