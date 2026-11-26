const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('src/digiarz-independent-ui.css', 'utf8');
const sw = fs.readFileSync('sw.js', 'utf8');

test('independent stylesheet loads after all inline styles and before the document closes', () => {
  const link = '<link rel="stylesheet" href="./src/digiarz-independent-ui.css?v=3">';
  assert.ok(html.includes(link));
  assert.ok(html.lastIndexOf(link) > html.lastIndexOf('</style>'));
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

test('three themes resolve to distinct black-gold, white-glass and bright indigo-glass palettes', () => {
  assert.match(css, /body\.dark-theme\{[\s\S]*?--da-accent:#f0b90b/);
  assert.match(css, /body\.light-theme\{[\s\S]*?--da-surface:rgba\(255,255,255,\.68\)/);
  const luxuryBlocks = [...css.matchAll(/body\.luxury-theme\{[^}]*\}/gs)];
  const finalLuxury = luxuryBlocks.at(-1)?.[0] || '';
  assert.match(finalLuxury, /color-scheme:light!important/);
  assert.match(finalLuxury, /--da-bg:#e5eaff!important/);
  assert.match(finalLuxury, /--da-accent:#405bd0!important/);
  assert.match(css, /body\.luxury-theme[\s\S]*?backdrop-filter:blur\(18px\)/);
});

test('chart canvas and Android theme-color metadata follow the bright indigo-glass palette', () => {
  assert.match(html, /document\.documentElement\.style\.colorScheme=\(light\|\|luxury\)\?'light':'dark'/);
  assert.match(html, /meta\.content=light\?'#ffffff':luxury\?'#edf2ff':'#090b10'/);
  assert.match(html, /bg:'#ffffff',text:'#152b40',grid:'#eaf2f8',line:'#d8e7f2'/);
  assert.match(html, /bg:'#edf2ff',text:'#202b55',grid:'#dbe4ff',line:'#b9c7ef'/);
  assert.match(html, /bg:'#090b10',text:'#f7f4eb',grid:'#272b34',line:'#5b4b2a'/);
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
  assert.match(sw, /digiarz-shell-v62/);
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
  assert.match(finalPalette, /border:0!important/);
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
  assert.ok(html.includes("luxury?{bg:'#edf2ff',text:'#202b55',grid:'#dbe4ff',line:'#b9c7ef'}"));
  assert.ok(html.includes("luxury?'#edf2ff'"));
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


test('dashboard market identity keeps visible favorites and frameless logos and rows in all themes', () => {
  const marker = '/* 2026-11-24 dashboard market correction: remove favorite and row frames in every theme. */';
  const pass = css.slice(css.lastIndexOf(marker));
  assert.ok(pass.length > 0, 'dashboard frameless correction exists');
  for (const selector of [
    '#dashboardMarketPreview .da-market-favorite',
    '#dashboardMarketPreview .da-market-logo',
    '#dashboardMarketPreview .da-market-logo-inner',
    '#dashboardMarketPreview .da-market-coin-card',
    '#dashboardMarketPreview.dashboard-market-preview.da-v2-market-list>.da-market-coin-card'
  ]) assert.ok(pass.includes(selector), 'dashboard selector exists: ' + selector);
  assert.ok(pass.includes('#dashboardMarketPreview .da-market-favorite{\n  border:0!important;outline:0!important;box-shadow:none!important;\n  background:transparent!important;border-radius:0!important;'), 'favorite has no frame');
  assert.ok(pass.includes('#dashboardMarketPreview .da-market-coin-card,\n#dashboardMarketPreview.dashboard-market-preview.da-v2-market-list>.da-market-coin-card{\n  border:0!important;outline:0!important;box-shadow:none!important;'), 'market rows have no frame');
  for (const theme of ['dark-theme', 'light-theme', 'luxury-theme']) {
    assert.ok(pass.includes('body.' + theme + ' #dashboardMarketPreview .da-market-favorite'), theme + ' favorite remains visible');
    assert.ok(pass.includes('body.' + theme + ' #dashboardMarketPreview .da-market-logo'), theme + ' logo styling remains');
    assert.ok(pass.includes('body.' + theme + ' #dashboardMarketPreview .da-market-coin-card'), theme + ' frameless row theme exists');
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
  assert.match(html, /englishName=String\(row\.item\.name_en\|\|row\.item\.asset_name_en\|\|row\.item\.english_name\|\|row\.item\.name\|\|coinInfo\[base\]\?\.name\|\|base\)/);
  assert.match(html, /persianCoinName\(symbol,englishName\)/);
  assert.match(html, /class="top-asset-name-en" dir="ltr"/);
  assert.match(html, /function marketPersianName\(item\)/);
  assert.match(html, /const explicit=\[item\?\.name_fa,item\?\.asset_name_fa\]\.map\(value=>String\(value\|\|''\)\.trim\(\)\)\.find\(Boolean\)\|\|''/);
  assert.ok(html.includes('marketPersianName(x)'), 'market search uses the shared Persian-name resolver');
  assert.match(html, /persianName=String\(marketPersianName\(item\)\)/);
  assert.match(html, /if\(sortMode==='name'\)return String\(marketPersianName\(a\.item\)\|\|a\.item\.symbol\)\.localeCompare\(String\(marketPersianName\(b\.item\)\|\|b\.item\.symbol\),'fa'\)/);
  assert.match(html, /asset_name_fa/);
  assert.match(html, /asset_name_en/);
});

test('dashboard hides account activity from regular users and keeps it available to admins', () => {
  assert.match(html, /id="dashboardAdminActivity"[^>]*hidden/);
  assert.match(html, /function renderDashboardActivity\(\)\{\s*const adminActivity=\$\('dashboardAdminActivity'\);if\(adminActivity\)adminActivity\.hidden=!isSuperAdmin;/);
  assert.match(html, /const englishName=String\(row\.item\.name_en\|\|row\.item\.asset_name_en\|\|row\.item\.english_name\|\|row\.item\.name\|\|coinInfo\[base\]\?\.name\|\|base\)/);
  assert.match(html, /className='da-market-name-en'/);
  assert.match(html, /name\.textContent=String\(row\.item\.name_fa\|\|row\.item\.asset_name_fa\|\|persianCoinName\(symbol,englishName\)/);
  assert.match(html, /fa=marketPersianName\(x\.item\)\|\|''/);
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


test('active wallet and market renderers preserve bilingual names and clean price markup', () => {
  const assetsStart = html.lastIndexOf('function renderAssets()');
  const assetsEnd = html.indexOf('async function loadAssets()', assetsStart);
  const activeAssets = html.slice(assetsStart, assetsEnd);
  assert.ok(assetsStart >= 0 && assetsEnd > assetsStart, 'active wallet renderer is located');
  assert.match(activeAssets, /englishName=asset==='USDT'\?'Tether':String\(market\?\.name_en/);
  assert.ok(activeAssets.includes("english.className='asset-name-en'"));
  assert.ok(activeAssets.includes('label.append(name,english,ticker)'));

  const marketsStart = html.lastIndexOf('function renderMarkets()');
  const marketsEnd = html.indexOf('function renderDashboardPortfolio', marketsStart);
  const activeMarkets = html.slice(marketsStart, marketsEnd);
  assert.ok(marketsStart >= 0 && marketsEnd > marketsStart, 'active market renderer is located');
  assert.ok(activeMarkets.includes('priceMarkup=usdMarkup+tomanMarkup;'));
  assert.doesNotMatch(activeMarkets, /coin-source fresh|coin-source stale|freshnessMarkup/);
  assert.ok(activeMarkets.includes('coin-english-name'));
});

test('market asset rows omit source and freshness labels while retaining USD and Toman prices', () => {
  assert.match(html, /const priceMarkup=usdMarkup\+tomanMarkup;/);
  assert.doesNotMatch(html, /coin-source fresh|coin-source stale|زمان منبع حداکثر ۲ دقیقه/);
});


test('dashboard sections follow a clear visual order and stay responsive without horizontal overflow', () => {
  assert.match(css, /#tab-dashboard\{[\s\S]*?max-width:1440px!important/);
  assert.match(css, /#tab-dashboard>\.da-v2-topline\{order:0/);
  assert.match(css, /#tab-dashboard>\.da-v2-hero\{order:1/);
  assert.match(css, /#tab-dashboard>\.da-v2-account-card\{order:2/);
  assert.match(css, /#tab-dashboard>\.da-v2-quick-grid\{order:3/);
  assert.match(css, /#tab-dashboard>\.da-market-glass\{order:5/);
  assert.match(css, /@media\(max-width:560px\)[\s\S]*?#tab-dashboard \.da-v2-account-stats\{grid-template-columns:repeat\(2,minmax\(0,1fr\)\)!important\}/);
  assert.match(css, /#tab-dashboard \.da-market-toolbar\{grid-template-columns:minmax\(0,1fr\)!important\}/);
  assert.match(html, /id="dashboardMarketPreview"/);
  assert.match(html, /id="usdtBalance"/);
});


test('cross-page premium surfaces keep responsive hierarchy and usable data tables', () => {
  for (const id of ['tab-markets','tab-toman','tab-chart','tab-trade','tab-assets','tab-orders','tab-history','tab-admin','tab-settings']) {
    assert.match(css, new RegExp('#' + id + '[,{]'));
  }
  for (const token of [
    'grid-template-columns:repeat(auto-fit,minmax(min(100%,180px),1fr))!important',
    '#tab-toman .toman-table-wrap',
    '#tab-history .table-wrap',
    '#tab-chart .asset-detail-head',
    '#tab-settings .theme-choice-group',
    'prefers-reduced-motion:reduce'
  ]) assert.ok(css.includes(token), 'missing cross-page polish rule: ' + token);
});


test('document remains a single well-formed page with no payload after the closing html tag', () => {
  assert.equal(html.split('</body>').length - 1, 1);
  assert.equal(html.split('</html>').length - 1, 1);
  const bodyClose = html.lastIndexOf('</body>');
  const htmlClose = html.lastIndexOf('</html>');
  assert.ok(bodyClose >= 0 && htmlClose > bodyClose, 'body closes before html');
  assert.equal(html.slice(htmlClose + '</html>'.length).trim(), '', 'nothing follows the document');
});

test('dashboard activity and account alerts remain restricted to the primary administrator', () => {
  assert.ok(html.includes('id="dashboardAdminActivity"'));
  assert.ok(html.includes('adminActivity.hidden=!isSuperAdmin'));
});

test('document IDs are not duplicated', () => {
  const ids = html.match(/id="[^"]+"/g) || [];
  assert.equal(new Set(ids).size, ids.length, 'all document IDs are unique');
});


test('dashboard hides the duplicated legacy header and uses the intended flex section order', () => {
  assert.match(css, /#appView:has\(#tab-dashboard:not\(\.hidden\)\) > \.hero/);
  assert.match(css, /#appView:has\(#tab-dashboard:not\(\.hidden\)\) > \.market-announcement/);
  assert.match(css, /#tab-dashboard\{[\s\S]*?display:flex!important;[\s\S]*?flex-direction:column!important/);
  assert.match(css, /#tab-dashboard>\.da-v2-account-card\{order:2\}/);
  assert.match(css, /#tab-dashboard>\.da-v2-quick-grid\{order:3\}/);
  assert.match(css, /#tab-dashboard \.da-v2-quick-grid button b\{color:var\(--da-text\)!important\}/);
});

test('dashboard is hidden when any other app tab is selected despite its flex layout override', () => {
  assert.ok(css.includes('#tab-dashboard.hidden{display:none!important}'));
  assert.ok(css.includes('#tab-dashboard{\n  display:flex!important;'));
});


test('dashboard removes its repeated brand masthead and keeps indigo glass account controls legible', () => {
  assert.ok(css.includes('#tab-dashboard>.da-v2-topline{display:none!important}'));
  assert.match(css, /body\.luxury-theme #tab-dashboard \.da-v2-account-stats>div\{[\s\S]*?rgba\(65,78,157/);
  assert.match(css, /body\.luxury-theme #tab-dashboard \.da-market-glass input,[\s\S]*?color:#f3f0ff!important/);
});


test('dashboard no longer leaves excessive mobile bottom whitespace and keeps the fixed nav clear', () => {
  const v6 = css.slice(css.lastIndexOf('dashboard bottom-space and universal frameless logo correction v6'));
  assert.ok(v6.length > 0);
  assert.ok(v6.includes('padding-bottom:calc(88px + env(safe-area-inset-bottom))!important'));
  assert.ok(v6.includes('min-height:0!important;height:auto!important'));
  assert.ok(v6.includes('padding-bottom:12px!important;margin-bottom:0!important'));
  assert.ok(!v6.includes('padding-bottom:150px!important'));
});

test('brand, dashboard, market, wallet and asset-detail logos have no visible frame in any theme', () => {
  const v6 = css.slice(css.lastIndexOf('dashboard bottom-space and universal frameless logo correction v6'));
  for (const selector of [
    '#tab-dashboard .da-v2-logo',
    '#dashboardMarketPreview .da-market-logo',
    '#tab-markets #marketList .coin-icon',
    '#tab-assets #assetList .asset-row .asset-logo',
    '#tab-chart .asset-detail-head .asset-logo'
  ]) assert.ok(v6.includes(selector), 'missing frameless logo selector: ' + selector);
  assert.ok(v6.includes('border:0!important;outline:0!important;box-shadow:none!important;'));
  assert.ok(v6.includes('background:transparent!important;'));
});


test('v7 dashboard footer spacing and theme-specific logo overrides stay compact and frameless', () => {
  const v7 = css.slice(css.lastIndexOf('dashboard compact footer and theme-proof frameless marks v7'));
  assert.ok(v7.includes('padding-bottom:calc(68px + env(safe-area-inset-bottom))!important'));
  assert.ok(v7.includes('margin-top:6px!important;padding:10px 10px 12px!important'));
  assert.ok(v7.includes('body.dark-theme #tab-dashboard .da-v2-logo'));
  assert.ok(v7.includes('body.light-theme #tab-dashboard .da-v2-logo'));
  assert.ok(v7.includes('body.luxury-theme #tab-dashboard .da-v2-logo'));
  assert.ok(v7.includes('border:0!important;outline:0!important;box-shadow:none!important;'));
  assert.ok(v7.includes('background:transparent!important;border-radius:0!important;'));
});

test('mobile header wordmark removes its legacy blue D tile and restores fixed-nav scroll clearance', () => {
  const audit = css.slice(css.lastIndexOf('final mobile dashboard audit'));
  assert.ok(audit.includes('.top .brand::before{'));
  assert.ok(audit.includes('content:none!important;'));
  assert.ok(audit.includes('padding-bottom:calc(96px + env(safe-area-inset-bottom))!important'));
  assert.ok(audit.includes('.mobile-bottom-nav{'));
});


test('dashboard light theme uses clean white glass surfaces without grey wash and keeps market controls coherent', () => {
  const v8 = css.slice(css.lastIndexOf('dashboard visual correction v8'));
  assert.ok(v8.includes('body.light-theme{'));
  assert.ok(v8.includes('background:#fff!important'));
  assert.ok(v8.includes('body.light-theme #tab-dashboard .da-market-glass'));
  assert.ok(v8.includes('body.light-theme #tab-dashboard .da-market-filters button.active'));
  assert.ok(v8.includes('body.luxury-theme #tab-dashboard .da-market-filters button'));
  assert.ok(v8.includes('body.luxury-theme #tab-dashboard .da-market-glass select option'));
  assert.ok(v8.includes('min-height:0!important;padding:clamp(16px,3vw,26px)!important'));
});


test('dashboard toolbar styles the real search and sort label shells in light and indigo themes', () => {
  const v9 = css.slice(css.lastIndexOf('dashboard visual audit v9'));
  assert.ok(v9.includes('.da-market-glass .da-market-search'));
  assert.ok(v9.includes('.da-market-glass .da-market-sort'));
  assert.ok(v9.includes('background:rgba(9,16,58,.72)!important'));
  assert.ok(v9.includes('background:#fff!important'));
  assert.ok(v9.includes('input::placeholder'));
});

test('mobile dashboard hero is compact and hides decorative art without removing its actions', () => {
  const v9 = css.slice(css.lastIndexOf('dashboard visual audit v9'));
  assert.ok(v9.includes('#tab-dashboard .da-v2-hero-art{display:none!important}'));
  assert.ok(v9.includes('min-height:0!important;display:block!important'));
  assert.ok(v9.includes('#tab-dashboard .da-v2-primary{padding:9px 14px!important}'));
});


test('mobile bottom navigation adapts to six user tabs or seven admin tabs', () => {
  const v10 = css.slice(css.lastIndexOf('dashboard visual audit v10'));
  assert.ok(v10.includes('grid-template-columns:repeat(auto-fit,minmax(0,1fr))!important'));
  assert.ok(v10.includes('.mobile-bottom-nav button{'));
  assert.ok(v10.includes('min-width:0!important'));
});

test('mobile dashboard wallet block uses compact spacing without hiding balances or actions', () => {
  const v10 = css.slice(css.lastIndexOf('dashboard visual audit v10'));
  assert.ok(v10.includes('#tab-dashboard .da-v2-account-card'));
  assert.ok(v10.includes('#tab-dashboard .da-v2-balance-main'));
  assert.ok(v10.includes('#tab-dashboard .da-v2-wallet-link'));
});


test('mobile wallet metrics stay in one compact row above the fixed navigation', () => {
  const v11 = css.slice(css.lastIndexOf('mobile wallet/nav overlap correction v11'));
  assert.ok(v11.includes('grid-template-columns:repeat(3,minmax(0,1fr))!important'));
  assert.ok(v11.includes('#tab-dashboard .da-v2-account-stats small'));
  assert.ok(v11.includes('#tab-dashboard .da-v2-wallet-link'));
  assert.ok(v11.includes('min-height:34px!important'));
});


test('v12 frameless dashboard logo rules override theme-specific tile shadows and borders', () => {
  const v12 = css.slice(css.lastIndexOf('corrective dashboard pass v12'));
  assert.ok(v12.includes('body.light-theme #dashboardMarketPreview .da-market-logo-inner img'));
  assert.ok(v12.includes('box-shadow:none!important'));
  assert.ok(v12.includes('background:transparent!important'));
  assert.ok(v12.includes('border-radius:0!important'));
  assert.ok(v12.includes('grid-template-columns:repeat(3,minmax(0,1fr))!important'));
  assert.ok(v12.includes('#tab-dashboard .da-v2-quick-grid'));
});


test('v13 mobile dashboard compacts hero, wallet and quick actions before market section', () => {
  const v13 = css.slice(css.lastIndexOf('mobile dashboard viewport balance v13'));
  assert.ok(v13.includes('#tab-dashboard .da-v2-hero-foot{display:none!important}'));
  assert.ok(v13.includes('#tab-dashboard .da-v2-account-stats>div{min-height:43px!important'));
  assert.ok(v13.includes('#tab-dashboard .da-v2-quick-grid button{'));
  assert.ok(v13.includes('min-height:40px!important'));
});


test('v14 mobile dashboard compresses top sections so market controls clear the fixed navigation', () => {
  const v14 = css.slice(css.lastIndexOf('mobile dashboard viewport balance v14'));
  assert.ok(v14.includes('#tab-dashboard .da-v2-hero{'));
  assert.ok(v14.includes('font-size:16px!important'));
  assert.ok(v14.includes('#tab-dashboard .da-v2-account-card{'));
  assert.ok(v14.includes('min-height:38px!important'));
  assert.ok(v14.includes('#tab-dashboard .da-v2-quick-grid button{'));
  assert.ok(v14.includes('min-height:34px!important'));
  assert.ok(v14.includes('#tab-dashboard .da-market-glass{padding:7px!important}'));
});


test('2026-11-26 signature UI layer establishes the dashboard hierarchy and premium three-theme surfaces',()=>{
  const marker='DigiArz Signature UI 2026-11-26';
  const finalCss=css.slice(css.lastIndexOf(marker));
  assert.ok(finalCss.length>5000,'signature redesign layer is present');
  for(const token of ['#tab-dashboard>.da-v2-hero{order:1!important}',
    '#tab-dashboard>.da-v2-wallet-card{order:2!important}',
    '#tab-dashboard>.da-v2-quick-grid{order:3!important}',
    '#tab-dashboard>.da-market-glass{order:5!important}',
    'body.dark-theme{','body.light-theme{','body.luxury-theme{',
    'grid-template-areas:"fav identity change price" ". spark change price"',
    '#tab-markets #marketList>.coin','--da-radius-xl:26px'])
    assert.ok(finalCss.includes(token),'signature layer includes '+token);
});

test('all visible cryptocurrency logo holders are fully transparent and frameless across app sections',()=>{
  const marker='DigiArz Signature UI 2026-11-26';
  const finalCss=css.slice(css.lastIndexOf(marker));
  for(const token of ['#tab-markets #marketList .coin-icon',
    '#tab-dashboard .da-market-logo','#tab-assets #assetList .asset-logo',
    '#tab-chart .asset-detail-head .asset-logo','#tab-toman .coin-icon',
    'background:transparent!important','background-color:transparent!important',
    'border:0!important','box-shadow:none!important','object-fit:contain!important'])
    assert.ok(finalCss.includes(token),'frameless logo coverage includes '+token);
});

test('market and dashboard retain their live data and interaction hooks after the visual-only redesign',()=>{
  for(const token of ['id="dashboardMarketPreview"','id="dashboardMarketSearch"',
    'id="dashboardMarketSort"','id="dashboardMarketFilters"','id="marketList"',
    'id="marketSearch"','id="marketCategories"','id="marketSort"',
    'id="marketCurrencyMode"','id="refreshMarketPageBtn"'])
    assert.ok(html.includes(token),'required market hook remains: '+token);
  assert.match(html,/function renderMarkets\(/);
  assert.match(html,/function renderDashboardMarketPreview\(/);
});


test('logo tile removal also covers top-volume assets, trade previews and fallback marks throughout the app',()=>{
  const finalCss=css.slice(css.lastIndexOf('Signature logo normalization'));
  for(const token of ['.coin-icon,.coin-icon img,.asset-logo,.asset-logo img,.coin-logo-fallback',
    '.top-asset-card .coin-icon','.trade-asset-preview .asset-logo',
    'background:transparent!important','background-image:none!important',
    'box-shadow:none!important','object-fit:contain!important'])
    assert.ok(finalCss.includes(token),'global logo reset includes '+token);
});


test('final universal logo-card override removes all logo backgrounds and frames across the app',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Final universal logo-card transparency override'));
  for(const selector of ['.da-v2-logo','.coin-icon','.asset-logo','.coin-logo',
    '.da-market-logo','.da-market-logo-inner','#tab-dashboard .da-v2-logo',
    '#tab-markets #marketList .coin-icon','#tab-assets #assetList .asset-row .asset-logo',
    '#tab-chart .asset-detail-head .asset-logo','#tab-toman .coin-icon']){
    assert.ok(final.includes(selector),'final override covers '+selector);
  }
  for(const token of ['background:transparent!important','background-color:transparent!important',
    'background-image:none!important','border:0!important','box-shadow:none!important']){
    assert.ok(final.includes(token),'final override removes '+token);
  }
});



test('visual screenshots seed DOM-only synthetic market rows without depending on private app functions',()=>{
  const harness=fs.readFileSync('tests/ui-visual-screenshots.cjs','utf8');
  assert.match(harness,/async function seedVisualFixtures\(page\)/);
  assert.ok(harness.includes('if (market) market.innerHTML = tetherRow + rows.map'));
  assert.match(harness,/dashboard\.innerHTML = rows\.map/);
  assert.match(harness,/await seedVisualFixtures\(page\)/);
  assert.doesNotMatch(harness,/renderMarkets\(\)/);
  assert.doesNotMatch(harness,/renderDashboardSummary\(\)/);
});


test('theme-qualified logo transparency overrides legacy theme tile rules with stronger selectors',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Theme-specific high-specificity reset'));
  for(const theme of ['dark-theme','light-theme','luxury-theme']){
    assert.ok(final.includes('body.'+theme+' #tab-dashboard #dashboardMarketPreview .da-market-logo'));
    assert.ok(final.includes('body.'+theme+' #tab-markets #marketList>.coin .coin-icon'));
    assert.ok(final.includes('body.'+theme+' #tab-assets #assetList .asset-row .asset-logo'));
  }
  assert.ok(final.includes('background:transparent!important;'));
  assert.ok(final.includes('background-image:none!important;'));
  assert.ok(final.includes('border:0!important;'));
});


test('theme-specific logo override contains valid CSS line breaks and no escaped newline sequences',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Theme-specific high-specificity reset'));
  assert.ok(final.includes('body.dark-theme .da-v2-logo,\nbody.dark-theme .coin-icon'));
  assert.ok(final.includes('body.light-theme .da-v2-logo,\nbody.light-theme .coin-icon'));
  assert.ok(final.includes('body.luxury-theme .da-v2-logo,\nbody.luxury-theme .coin-icon'));
  assert.equal(final.includes('\\n'),false,'CSS selectors must use real newlines, not escaped backslash-n');
});


test('market and dashboard logo identity buttons do not inherit primary-button gradients',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Logo identity buttons must not inherit'));
  for(const theme of ['dark-theme','light-theme','luxury-theme']){
    assert.ok(final.includes('body.'+theme+' #tab-dashboard #dashboardMarketPreview .da-market-identity'));
    assert.ok(final.includes('body.'+theme+' #tab-markets #marketList>.coin .coin-identity'));
  }
  assert.ok(final.includes('background:transparent!important;'));
  assert.ok(final.includes('background-image:none!important;'));
  assert.ok(final.includes('box-shadow:none!important;'));
});


test('layout correction hides inactive dashboard and market tabs despite their explicit display rules',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('DigiArz layout correction + luminous indigo glass theme'));
  assert.ok(final.includes('#appView [id^="tab-"].hidden{'));
  assert.ok(final.includes('display:none!important;'));
  assert.ok(final.includes('#appView #tab-dashboard.hidden'));
  assert.ok(final.includes('#appView #tab-markets.hidden'));
  assert.ok(final.includes('#appView #tab-dashboard:not(.hidden){display:flex!important}'));
  assert.ok(final.includes('#appView #tab-markets:not(.hidden){display:block!important}'));
});

test('market row grid uses five matching columns and named areas at desktop and mobile widths',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('DigiArz layout correction + luminous indigo glass theme'));
  assert.ok(final.includes('grid-template-areas:"fav identity spark change price"!important;'));
  assert.ok(final.includes('grid-template-areas:"fav identity spark change price" ". identity spark change price"!important;'));
  assert.ok(final.includes('grid-template-columns:22px minmax(0,1fr) 34px 48px 76px!important;'));
});


test('market asset rows remain frameless across all themes while retaining a subtle hover state',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Market asset rows: preserve spacing and hover feedback without card frames.'));
  assert.ok(final.includes('#appView #tab-markets #marketList>.coin:not(.tether-pinned)'));
  assert.ok(final.includes('border:0!important;'));
  assert.ok(final.includes('outline:0!important;'));
  assert.ok(final.includes('box-shadow:none!important;'));
  assert.ok(final.includes('background:transparent!important;'));
});


test('dashboard coin logos and favorite stars stay completely frameless in every theme',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Final identity polish: coin logos and favorite stars have no decorative frames.'));
  for(const token of [
    '#dashboardMarketPreview .da-market-logo',
    '#dashboardMarketPreview .da-market-logo-inner',
    'box-shadow:none!important;',
    'background:transparent!important;',
    '#dashboardMarketPreview .da-market-favorite',
    '#dashboardMarketPreview .da-market-favorite[aria-pressed="true"]',
    'body.dark-theme #dashboardMarketPreview .da-market-favorite[aria-pressed="true"]',
    'body.light-theme #dashboardMarketPreview .da-market-favorite[aria-pressed="true"]',
    'body.luxury-theme #dashboardMarketPreview .da-market-favorite[aria-pressed="true"]',
    '#tab-markets #marketList .favorite-btn'
  ]) assert.ok(final.includes(token),'frameless identity treatment includes '+token);
});


test('coin logo failures render a visible branded SVG fallback instead of hiding the asset mark',()=>{
  const html=fs.readFileSync('index.html','utf8');
  const start=html.indexOf('function renderCoinLogoFallback(');
  const end=html.indexOf('function coinLogo(',start);
  const fallback=html.slice(start,end);
  assert.ok(start>=0&&end>start,'coin logo fallback helper exists before coinLogo');
  for(const token of ['const colors={BTC:','ETH:','#627eea','SOL:','BNB:','XRP:','DOGE:','ADA:',
    'holder.innerHTML=','<svg viewBox="0 0 48 48"','aria-label','function handleCoinLogoError'])
    assert.ok(fallback.includes(token),'logo fallback includes '+token);
  assert.ok(fallback.includes('if(holder)renderCoinLogoFallback(holder,symbol)'),
    'failed remote logo is replaced with a visible SVG mark');
  assert.ok(!fallback.includes('img.style.display=\'none\';if(holder)'),
    'failed logo must not be hidden leaving an empty slot');
});

test('catalog coin logos always use the validated app-assets proxy and skip empty metadata URLs',()=>{
  const html=fs.readFileSync('index.html','utf8');
  assert.ok(html.includes("item=>cleanCoinSymbol(item.symbol||item.asset||'')===clean&&safeCoinImageUrl(item.image_url)"),
    'logo lookup skips empty or invalid image metadata rows');
  const logoStart=html.indexOf('function coinLogo(');
  const logoEnd=html.indexOf('function updateQuickTradeEstimate(',logoStart);
  const logoBlock=html.slice(logoStart,logoEnd);
  assert.ok(logoBlock.includes('initial=logoUrl(clean,custom)'),
    'catalog metadata image is sent through the server-side allowlisted proxy');
  const errorStart=html.indexOf('function handleCoinLogoError(');
  const errorEnd=html.indexOf('function coinLogo(',errorStart);
  const errorBlock=html.slice(errorStart,errorEnd);
  assert.ok(errorBlock.includes('const fallbacks=[logoUrl(symbol),'),
    'failed curated logo falls back to the proxy provider chain');
  const chartStart=html.indexOf('async function openChart(');
  const chartEnd=html.indexOf('function ',chartStart+20);
  const chartBlock=html.slice(chartStart,chartEnd);
  assert.ok(chartBlock.includes("const detailImageUrl=getCoinLogoImageUrl(base)"),
    'asset detail reads catalog logo metadata');
  assert.ok(chartBlock.includes("$('detailLogo').src=logoUrl(base,detailImageUrl)"),
    'asset detail never loads catalog-supplied image URLs directly');
});

test('third luxury theme is a bright ice-blue indigo glass palette, distinct from the black-gold dark theme',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('DigiArz layout correction + luminous indigo glass theme'));
  for(const token of ['color-scheme:light!important','--da-bg:#e5eaff!important',
    '--da-surface:rgba(255,255,255,.94)!important','--da-accent:#405bd0!important',
    'linear-gradient(145deg,#f7f8ff 0%,#edf2ff 52%,#e9f4ff 100%)',
    'body.luxury-theme .top','body.luxury-theme #tab-markets .market-categories .category-btn.active'])
    assert.ok(final.includes(token),'bright luxury palette includes '+token);
});


test('bright indigo dashboard overrides inherited dark account and market surfaces',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Bright-theme contrast pass 2'));
  for(const token of [
    'body.luxury-theme #tab-dashboard .da-v2-account-card',
    'body.luxury-theme #tab-dashboard .da-market-glass',
    'linear-gradient(145deg,rgba(255,255,255,.98),rgba(239,245,255,.98))',
    'body.luxury-theme #tab-dashboard .da-v2-balance-main',
    'body.luxury-theme #tab-dashboard .da-market-coin-card',
    'background:#fff!important;',
    'color:#202b55!important;'
  ]) assert.ok(final.includes(token),'bright dashboard override includes '+token);
});


test('mobile dashboard asset rows preserve readable identity and dual-currency prices',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Mobile composition pass 3'));
  assert.ok(final.includes('grid-template-columns:25px minmax(112px,1.35fr) minmax(48px,.58fr) minmax(86px,.95fr)!important;'));
  assert.ok(final.includes('white-space:normal!important;overflow:visible!important;text-overflow:clip!important;'));
  assert.ok(final.includes('#dashboardMarketPreview .da-market-sparkline{display:none!important}'));
  assert.ok(final.includes('#dashboardMarketPreview .da-market-toman'));
});

test('mobile market hero and category navigation use compact spacing',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Mobile composition pass 3'));
  for(const token of ['#tab-markets .market-hero-v34','min-height:0!important;padding:12px 13px!important',
    '#tab-markets .market-categories{gap:5px!important;margin:8px 0!important;overflow-x:auto!important;flex-wrap:nowrap!important}',
    '#tab-markets .market-board-v34{margin-top:8px!important}'])
    assert.ok(final.includes(token),'mobile market layout includes '+token);
});


test('bright indigo market hero actions and mobile navigation retain readable light-theme contrast',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Visual review follow-up: brighten indigo market controls'));
  for(const token of ['body.luxury-theme #tab-markets .market-hero-v34 *',
    'color:#26345f!important','body.luxury-theme #tab-markets .market-hero-actions button',
    'background:linear-gradient(145deg,#fff,#edf2ff)!important',
    'body.luxury-theme .mobile-bottom-nav button','body.luxury-theme .mobile-bottom-nav button.active'])
    assert.ok(final.includes(token),'bright indigo contrast rule includes '+token);
});


test('mobile visual review captures dashboard and market asset rows after scrolling into view',()=>{
  const harness=fs.readFileSync('tests/ui-visual-screenshots.cjs','utf8');
  assert.match(harness,/marketPreview\.scrollIntoViewIfNeeded\(\)/);
  assert.match(harness,/marketRows\.scrollIntoViewIfNeeded\(\)/);
  assert.match(harness,/dashboard-marketrows/);
  assert.match(harness,/markets-assetrows/);
  assert.match(harness,/files\.length!==66/);
});


test('third theme market price text and bottom navigation use high-contrast light surfaces',()=>{
 const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
 const final=css.slice(css.lastIndexOf('High-specificity visual-review correction'));
 for(const token of ['#appView #tab-markets #marketList>.coin .price-stack .price-usd strong',
  'color:#1c2b50!important;opacity:1!important',
  '#appView .mobile-bottom-nav','background:rgba(255,255,255,.98)!important',
  '#appView .mobile-bottom-nav button.active'])
  assert.ok(final.includes(token),'third-theme contrast correction includes '+token);
});


test('market category icons are positioned directly below the asset-list heading',()=>{
  const html=fs.readFileSync('index.html','utf8');
  const heading=html.indexOf('<strong>فهرست دارایی‌ها</strong>');
  const categories=html.indexOf('id="marketCategories"');
  const list=html.indexOf('id="marketList"');
  assert.ok(heading>=0&&categories>heading&&list>categories,
    'market category icons must follow the asset heading and precede the asset rows');
  assert.equal((html.match(/id="marketCategories"/g)||[]).length,1,
    'category navigation must have one live mount point');
});

test('USDT is pinned first in the market list with a dedicated Tether logo and peg display',()=>{
  const html=fs.readFileSync('index.html','utf8');
  const start=html.indexOf('function renderMarkets(){');
  const end=html.indexOf('function renderDashboardPortfolio(',start);
  const market=html.slice(start,end);
  assert.ok(market.indexOf("tether.className='coin tether-pinned'")>=0);
  assert.ok(market.indexOf("fragment.appendChild(tether)")<market.indexOf('for(const item of visibleRows)'),
    'the Tether row must be inserted before all filtered market assets');
  assert.ok(market.includes("coinLogo('USDT','coin-icon')"));
  assert.ok(market.includes("currentFxIsValid?formatNum(currentFxRate,0)+' تومان'"));
  assert.ok(html.includes('function coinLogo(symbol,sizeClass='));
  assert.ok(html.includes('if(clean===\'USDT\')return'));
  assert.ok(html.includes('fill="#26A17B"'));
});

test('pinned Tether market row keeps the same frameless responsive treatment in all themes',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const rules=css.slice(css.lastIndexOf('Market asset hierarchy: category shortcuts'));
  for(const token of ['#tab-markets #marketList>.coin.tether-pinned',
    'border-color:transparent!important',
    'body.dark-theme #tab-markets #marketList>.coin.tether-pinned',
    'body.light-theme #tab-markets #marketList>.coin.tether-pinned',
    'body.luxury-theme #tab-markets #marketList>.coin.tether-pinned',
    '.tether-logo svg'])
    assert.ok(rules.includes(token),'pinned Tether styling includes '+token);
});



test('visual review fixture renders the pinned Tether row and its dedicated green SVG logo first', () => {
  const harness = fs.readFileSync('tests/ui-visual-screenshots.cjs', 'utf8');
  assert.match(harness, /class="coin tether-pinned"/);
  assert.match(harness, /aria-label="لوگوی تتر USDT"/);
  assert.match(harness, /fill="#26A17B"/);
  assert.match(harness, /counts\.marketCards!==9/);
  assert.match(harness, /tetherRow \+ rows\.map/);
});

test('Android biometric login is opt-in and uses the native encrypted credential vault', () => {
  assert.match(html, /id="saveCredentialsForBiometric"[^>]*type="checkbox"/);
  assert.match(html, /id="biometricLoginBtn"/);
  assert.match(html, /id="clearBiometricCredentialsBtn"/);
  assert.match(html, /vault\.clearCredentials\(\)/);
  assert.match(html, /vault\.saveCredentials\(\{email,password\}\)/);
  assert.match(html, /vault\.getCredentials\(\)/);
  assert.doesNotMatch(html, /localStorage\.setItem\([^,]*(?:password|credential)/i);
});

test('native Android build registers a biometric credential plugin backed by Android Keystore', () => {
  const plugin = fs.readFileSync('android-native/BiometricCredentialPlugin.java', 'utf8');
  const script = fs.readFileSync('scripts/prepare-android-native.sh', 'utf8');
  assert.match(plugin, /AndroidKeyStore/);
  assert.match(plugin, /setUserAuthenticationRequired\(true\)/);
  assert.match(plugin, /BiometricPrompt/);
  assert.match(plugin, /AES\/GCM\/NoPadding/);
  assert.match(script, /BiometricCredentialPlugin\.java/);
  assert.match(script, /androidx\.biometric:biometric/);
});


test('final icy-indigo override neutralizes legacy dark asset, history, settings and sky-blue hero surfaces',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Final icy-indigo surfaces: remove legacy dark/sky-blue overrides'));
  assert.ok(final.length>0,'final icy-indigo correction layer exists');
  for(const token of [
    'body.luxury-theme #appView #tab-assets #assetSummary .stat',
    'body.luxury-theme #appView #tab-settings .setting-row',
    'body.luxury-theme #appView #tab-history .table-wrap',
    'background:linear-gradient(145deg,rgba(255,255,255,.98),rgba(235,241,255,.96))!important;',
    'body.luxury-theme #appView #tab-history .table-wrap th',
    'body.luxury-theme #appView #tab-settings .theme-choice-group button[aria-pressed=true]',
    'body.luxury-theme #appView .da-v2-hero',
    'linear-gradient(125deg,#f8faff 0%,#e6edff 55%,#dceaff 100%)',
    'body.luxury-theme #authView .auth-reference-visual',
    'body.luxury-theme #authView .auth-form input'
  ]) assert.ok(final.includes(token),'final icy-indigo correction includes '+token);
});


test('visual screenshot harness preserves light color scheme for both white and icy-indigo themes', () => {
  const harness = fs.readFileSync('tests/ui-visual-screenshots.cjs', 'utf8');
  assert.ok(harness.includes("document.documentElement.style.colorScheme = selected==='dark'?'dark':'light';"));
});


test('icy-indigo trading theme also neutralizes nested order-book headers and rows',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Order-book header/rows: finish the icy-indigo treatment'));
  for(const token of [
    'body.luxury-theme #appView #tab-trade .orderbook-head',
    'body.luxury-theme #appView #tab-trade .orderbook-row',
    'background:rgba(255,255,255,.88)!important;',
    'color:#52618b!important;'
  ]) assert.ok(final.includes(token),'icy-indigo order-book correction includes '+token);
});


test('offline icon fallback renders vector artwork and exposes a clear active navigation state',()=>{
  const html=fs.readFileSync('index.html','utf8');
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const rendererStart=html.indexOf('function renderLucideIcons()');
  const rendererEnd=html.indexOf('function showMessage',rendererStart);
  assert.ok(rendererStart>=0&&rendererEnd>rendererStart,'icon renderer is located');
  const renderer=html.slice(rendererStart,rendererEnd);
  assert.ok(renderer.includes('const iconPaths='),'offline vector path library exists');
  assert.ok(renderer.includes('viewBox="0 0 24 24"'),'fallback renders scalable SVG');
  assert.ok(renderer.includes("paths.map(d=>'<path d=\"'+d+'\"/>').join('')"),'fallback renders vector paths');
  assert.doesNotMatch(renderer,/glyphs|textContent=/,'fallback does not regress to Unicode placeholder glyphs');
  assert.match(html,/<button type="button" class="active" data-tab="dashboard" aria-current="page">/,'home is selected on initial dashboard render');
  assert.ok(html.includes("b.setAttribute('aria-current','page')"),'tab changes announce the selected page');
  assert.ok(html.includes("b.removeAttribute('aria-current')"),'inactive tabs clear current-page semantics');
  const final=css.slice(css.lastIndexOf('Final icon finish: quieter inactive glyphs'));
  for(const token of ['stroke-width:2.35','button.active:after','body.dark-theme #appView .mobile-bottom-nav button.active','body.light-theme #appView .mobile-bottom-nav button.active','body.luxury-theme #appView .mobile-bottom-nav button.active']) {
    assert.ok(final.includes(token),'active icon treatment includes '+token);
  }
});


test('all dynamically rendered market categories have dedicated offline vector icons',()=>{
  const html=fs.readFileSync('index.html','utf8');
  const rendererStart=html.indexOf('function renderLucideIcons()');
  const rendererEnd=html.indexOf('function showMessage',rendererStart);
  const renderer=html.slice(rendererStart,rendererEnd);
  const categories=['layout-grid','wallet','trending-up','badge-plus','star','trending-down','bar-chart-3','trophy','landmark','smile','globe-2','shield-check','brain-circuit','gamepad-2'];
  for(const name of categories) {
    assert.match(renderer,new RegExp("(?:['\"])?"+name+"(?:['\"])?\\s*:"),'dedicated offline SVG path exists for '+name);
  }
  assert.ok(html.includes("item.setAttribute('aria-pressed',active?'true':'false')"),'selected category exposes pressed state');
});


test('market loads Iranian-exchange Persian asset names before the Toman tab is opened',()=>{
  assert.match(html,/function buildTomanAssetNameIndex\(rows\)/);
  assert.match(html,/is_stale===false/);
  assert.match(html,/function loadTomanAssetNameIndex\(\)/);
  assert.match(html,/market_toman_performance'\)\.select\('asset_symbol,asset_name_fa,exchange,is_stale,fetched_at'\)/);
  assert.match(html,/loadTomanAssetNameIndex\(\)\.then\(loaded=>\{if\(loaded\)\{renderMarkets\(\);renderDashboardMarketPreview\(\);renderDashboardSummary\(\)\}\}\)/);
  assert.match(html,/tomanAssetNames=buildTomanAssetNameIndex\(rows\)/);
});


test('icy-indigo premium identity is visibly distinct from white while remaining light and glassy',()=>{
  const css=fs.readFileSync('src/digiarz-independent-ui.css','utf8');
  const final=css.slice(css.lastIndexOf('Premium identity pass: make icy-indigo clearly distinct'));
  for(const token of [
    '--da-bg:#e5eaff!important;',
    'linear-gradient(145deg,#eef1ff 0%,#e3e9ff 48%,#e7f0ff 100%)',
    'body.luxury-theme .top',
    'linear-gradient(115deg,rgba(231,237,255,.94),rgba(215,226,255,.86))',
    'body.luxury-theme #appView .hero',
    'linear-gradient(125deg,#dce5ff 0%,#cbd8ff 48%,#e4edff 100%)',
    'body.luxury-theme #appView .mobile-bottom-nav button.active',
    'color:#fff!important;'
  ]) assert.ok(final.includes(token),'premium icy-indigo layer includes '+token);
  assert.ok(final.includes('color-scheme:light!important;'),'third theme retains a light color scheme');
});
