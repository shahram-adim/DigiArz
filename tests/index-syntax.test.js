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
test('trade history CSV export respects filters and preserves exact decimal strings', () => {
  assert.match(html, /id="exportHistoryCsvBtn"/);
  const start = html.indexOf('function exportHistoryCsv(){');
  const end = html.indexOf('\nasync function trade(side)', start);
  assert.ok(start >= 0 && end > start, 'CSV export function boundaries found');
  const body = html.slice(start, end);
  assert.ok(body.includes('getFilteredHistoryRows()'), 'the CSV uses the shared current history filters');
  assert.ok(body.includes("String(item.amount??'')"), 'amount stays an exact string');
  assert.ok(body.includes("String(item.price??'')"), 'price stays an exact string');
  assert.ok(body.includes("const csv='\\uFEFF'"), 'UTF-8 BOM is included');
  assert.ok(body.includes("join('\\r\\n')"), 'CSV uses CRLF line endings');
  assert.ok(body.includes('createObjectURL') && body.includes('revokeObjectURL'));
  assert.ok(body.includes('safeCell'), 'CSV cells are protected against formula injection');
});

test('trade history loads older pages without losing exact values or changing records', () => {
  assert.match(html, /id="loadMoreHistoryBtn"/);
  assert.match(html, /historyPageSize=50/);
  const start = html.indexOf('async function loadHistory(){');
  const end = html.indexOf('function exportHistoryCsv(){', start);
  assert.ok(start >= 0 && end > start, 'history loading function boundaries found');
  const body = html.slice(start, end);
  assert.ok(body.includes('.range(0,historyPageSize-1)'), 'first page uses a bounded range');
  assert.ok(body.includes('async function loadMoreHistory()'), 'older page loader exists');
  assert.ok(body.includes('.range(offset,offset+historyPageSize-1)'), 'older pages use stable offsets');
  assert.ok(body.includes("order('id',{ascending:false})"), 'pagination uses a deterministic tie-breaker');
  assert.ok(body.includes('historyRows.push'), 'older rows append instead of replacing current rows');
  assert.ok(body.includes('historyHasMore=next.length===historyPageSize'), 'has-more state follows page size');
  assert.ok(body.includes('historyLoadingMore'), 'duplicate load requests are guarded');
  assert.ok(body.includes('historyRequestId'), 'stale page responses are ignored after refresh');
  assert.ok(html.includes("DigiArz-trades-'+rows.length+'-loaded-"), 'CSV filename reflects all loaded rows');
});

test('trade history date filters apply consistently to the table and CSV export', () => {
  for (const id of ['historyDateFrom', 'historyDateTo', 'clearHistoryFiltersBtn']) {
    assert.match(html, new RegExp('id="' + id + '"'));
  }
  const start = html.indexOf('function getFilteredHistoryRows(){');
  const end = html.indexOf('function renderHistory(){', start);
  assert.ok(start >= 0 && end > start, 'shared history filter helper boundaries found');
  const body = html.slice(start, end);
  assert.ok(body.includes("new Date(fromDate+'T00:00:00')"), 'start date includes the full local day');
  assert.ok(body.includes("new Date(toDate+'T23:59:59.999')"), 'end date includes the full local day');
  assert.ok(body.includes('fromTime') && body.includes('toTime'));
  const exportStart = html.indexOf('function exportHistoryCsv(){');
  const exportEnd = html.indexOf('\\nasync function trade(side)', exportStart);
  assert.ok(html.slice(exportStart, exportEnd).includes('getFilteredHistoryRows()'), 'CSV uses the same filters as the table');
  assert.ok(html.includes("clearHistoryFiltersBtn')?.addEventListener('click'"), 'clear action is wired');
});

test('trade history provides accessible local-date quick presets', () => {
  for (const range of ['0', '7', '30', 'all']) {
    assert.match(html, new RegExp('data-history-range="' + range + '"'));
  }
  const start = html.indexOf('function setHistoryDatePreset(range){');
  const end = html.indexOf('function renderHistory(){', start);
  assert.ok(start >= 0 && end > start, 'date preset helper boundaries found');
  const body = html.slice(start, end);
  assert.ok(body.includes('getFullYear()') && body.includes('getMonth()') && body.includes('getDate()'), 'preset dates use local calendar fields');
  assert.ok(body.includes("start.setDate(start.getDate()-(days-1))"), '7 and 30 day ranges include today');
  assert.ok(body.includes("range==='all'"), 'all-history preset clears only date boundaries');
  assert.ok(body.includes("setAttribute('aria-pressed',String(active))"), 'preset state is exposed accessibly');
  assert.ok(html.includes("historyDatePresets')?.addEventListener('click'"), 'preset buttons are wired');
  assert.ok(html.includes("clearHistoryFiltersBtn')?.addEventListener('click',()=>{['historySearch','historyDateFrom','historyDateTo'].forEach"), 'clear button is wired');
  assert.ok(html.includes("setHistoryDatePreset('all')"), 'clear action resets the selected preset');
});

test('dashboard exposes recent account activity and account alerts', () => {
  const start = html.indexOf('<div class="dashboard-activity-center"');
  const end = html.indexOf('<div class="da-v2-compat hidden"', start);
  assert.ok(start >= 0 && end > start, 'visible dashboard activity center boundaries found');
  const section = html.slice(start, end);
  for (const id of ['dashboardRecentOrders', 'dashboardRecentTrades', 'dashboardAccountAlerts']) {
    assert.match(section, new RegExp('id="' + id + '"'), id + ' is visible in the activity center');
  }
  assert.ok(section.includes('data-dashboard-tab="orders"'), 'orders shortcut is present');
  assert.ok(section.includes('data-dashboard-tab="history"'), 'history shortcut is present');
  assert.ok(section.includes('aria-live="polite"'), 'activity updates are announced politely');
  const compatibility = html.slice(end);
  assert.doesNotMatch(compatibility, /id="dashboard(?:RecentOrders|RecentTrades|AccountAlerts)"/, 'activity roots are not duplicated in hidden compatibility markup');
});

test('market exposes a live-volume trending category and keeps new listings admin-curated', () => {
  assert.match(html, /\{id:'trending',label:'ارزهای ترند',icon:'trending-up'\}/);
  assert.match(html, /\{id:'new',label:'ارزهای جدید',icon:'badge-plus'\}/);
  const start = html.indexOf('function renderMarkets(){');
  const end = html.indexOf('function renderDashboardPortfolio(', start);
  assert.ok(start >= 0 && end > start, 'market renderer boundaries found');
  const body = html.slice(start, end);
  assert.ok(body.includes('const volumeOf=item=>'), 'volume uses the current ticker or fresh stored market data');
  assert.ok(body.includes("activeMarketCategory==='trending')rows=rows.filter(x=>volumeOf(x)!==null&&volumeOf(x)>0)"), 'trending excludes assets without valid volume data');
  assert.ok(body.includes("activeMarketCategory==='trending'||sort==='volume-desc'"), 'trending sorts by descending 24-hour quote volume');
  assert.ok(body.includes("activeMarketCategory==='new'?featuredMarketRows:marketRows"), 'new assets remain sourced from the admin-curated listings');
  assert.ok(body.includes('item.catalogOnly') && body.includes('item.catalogStale'), 'new listings distinguish display-only and stale assets from enabled pairs');
});

test('new market automatically includes unmatched Iranian exchange listings as display-only assets', () => {
  const start = html.indexOf('async function loadFeaturedMarketAssets(){');
  const end = html.indexOf('async function searchAdminAssets()', start);
  assert.ok(start >= 0 && end > start, 'featured market loader boundaries found');
  const body = html.slice(start, end);
  assert.ok(body.includes("rpc('get_admin_market_listings')"), 'verified curated assets remain available');
  assert.ok(body.includes("rpc('get_exchange_discovered_market_assets')"), 'unmatched exchange observations are fetched automatically');
  assert.ok(body.includes('Promise.all(['), 'both sources load together');
  assert.ok(body.includes('exchangeNames={nobitex:') && body.includes("kifpool:'کیف‌پول'"), 'Iranian exchange names are localized');
  assert.ok(body.includes('catalogOnly:true') && body.includes('exchangeSources:sources'), 'unmatched assets are marked display-only with their exchange sources');
  assert.ok(body.includes('featuredMarketRows=listed.concat(discoveredRows.filter(x=>!seen.has(x.symbol)))'), 'duplicate symbols already in the curated list are excluded');
  const marketStart = html.indexOf('function renderMarkets(){');
  const marketEnd = html.indexOf('function renderDashboardPortfolio(', marketStart);
  const marketBody = html.slice(marketStart, marketEnd);
  assert.ok(marketBody.includes('item.exchangeSources'), 'the market explains which Iranian exchanges reported the asset');
  assert.ok(marketBody.includes('معامله هنوز فعال نیست'), 'newly discovered assets are not presented as trade-enabled');
});

test('Iranian exchange discovery RPC is read-only and excludes non-crypto tokenized equities', () => {
  const migration = fs.readFileSync('supabase/migrations/20261116200009_auto_list_unmatched_iran_exchange_assets.sql', 'utf8');
  assert.ok(migration.includes('FUNCTION public.get_exchange_discovered_market_assets()'));
  assert.ok(migration.includes('SECURITY DEFINER') && migration.includes("SET search_path = ''"));
  assert.ok(migration.includes('o.is_active IS TRUE'));
  assert.ok(migration.includes("o.last_seen_at >= pg_catalog.now() - interval '48 hours'"));
  assert.ok(migration.includes('(stock|equity|shares|xstock|tokenized)'));
  assert.ok(migration.includes('public.demo_trading_pairs'));
  assert.ok(migration.includes('GRANT EXECUTE ON FUNCTION public.get_exchange_discovered_market_assets() TO anon, authenticated'));
});


test('market 24h ranking uses one freshness-aware comparator in both directions', () => {
  const start = html.indexOf('function getMarketChange24h(item){');
  const end = html.indexOf('function getTrustedMarketPrice(item){', start);
  assert.ok(start >= 0 && end > start, 'shared 24h ranking helper boundaries found');
  const context = {
    getFreshMarketTicker: item => item.hasLiveTicker ? { change: item.liveChange } : null,
    isMarketTimestampFresh: value => value === 'fresh'
  };
  vm.runInNewContext(
    html.slice(start, end) +
      '\nthis.sortMarketRowsByChange = sortMarketRowsByChange; this.getMarketChange24h = getMarketChange24h;',
    context
  );
  const rows = [
    { symbol: 'ETHUSDT', hasLiveTicker: true, liveChange: '-4.25' },
    { symbol: 'BTCUSDT', hasLiveTicker: true, liveChange: '8.10' },
    { symbol: 'ADAUSDT', hasLiveTicker: true, liveChange: '1.50' },
    { symbol: 'SOLUSDT', hasLiveTicker: true, liveChange: '-0.75' },
    { symbol: 'XRPUSDT', change: '99', updated_at: 'stale' },
    { symbol: 'DOGEUSDT', change: '2.25', updated_at: 'fresh' }
  ];
  assert.deepEqual(
    Array.from(context.sortMarketRowsByChange(rows, 'desc'), item => item.symbol),
    ['BTCUSDT', 'DOGEUSDT', 'ADAUSDT', 'SOLUSDT', 'ETHUSDT']
  );
  assert.deepEqual(
    Array.from(context.sortMarketRowsByChange(rows, 'asc'), item => item.symbol),
    ['ETHUSDT', 'SOLUSDT', 'ADAUSDT', 'DOGEUSDT', 'BTCUSDT']
  );
  assert.equal(context.getMarketChange24h(rows[4]), null, 'stale stored percentages are excluded');
  assert.equal(context.getMarketChange24h(rows[5]), 2.25, 'fresh stored fallback percentages are accepted');
});

test('gainer, loser, volatility and market-list views share the same ranking helpers', () => {
  const gainersStart = html.indexOf('function renderTopGainers(){');
  const losersStart = html.indexOf('function renderTopLosers(){', gainersStart);
  const assetsStart = html.indexOf('function renderTopAssets(){', losersStart);
  const gainers = html.slice(gainersStart, losersStart);
  const losers = html.slice(losersStart, assetsStart);
  const marketStart = html.indexOf('function renderMarkets(){');
  const marketEnd = html.indexOf('function renderDashboardPortfolio(', marketStart);
  const market = html.slice(marketStart, marketEnd);
  assert.ok(gainers.includes("sortMarketRowsByChange(marketRows,'desc')"));
  assert.ok(losers.includes("sortMarketRowsByChange(marketRows,'asc')"));
  assert.ok(market.includes("compareMarketChange(a,b,'desc')"));
  assert.ok(market.includes("compareMarketChange(a,b,'asc')"));
  assert.ok(html.includes("const valid=sortMarketRowsByChange(marketRows,'desc')"));
  const dashboardStart = html.indexOf('function renderDashboardMarketPreview(){');
  const dashboardEnd = html.indexOf('function ', dashboardStart + 10);
  const dashboard = html.slice(dashboardStart, dashboardEnd);
  assert.ok(dashboard.includes('change=getMarketChange24h(item)'), 'dashboard filters use the shared freshness-aware percentage');
  assert.ok(dashboard.includes("compareMarketChange(a.item,b.item,'desc')"), 'dashboard gainers use the shared descending comparator');
  assert.ok(dashboard.includes("compareMarketChange(a.item,b.item,'asc')"), 'dashboard losers use the shared ascending comparator');
});

test('coin logos proxy failed curated CoinGecko images before independent symbol fallbacks', () => {
  assert.match(html, /function getCoinLogoImageUrl\(symbol\)/);
  assert.match(html, /data-custom-image-url=/);
  assert.match(html, /data-image-url=/);
  assert.match(html, /encodeURIComponent\(imageUrl\)/);
  assert.match(html, /coinLogo\(base,'coin-icon',item\.image_url\)/);
  assert.match(html, /coinLogo\(base,'da-market-logo-inner',row\.item\.image_url\)/);
  assert.match(html, /assets\.coincap\.io\/assets\/icons/);
  const edge = fs.readFileSync('supabase/functions/app-assets/index.ts', 'utf8');
  assert.match(edge, /spothq\/cryptocurrency-icons/);
  assert.match(edge, /assets\.coincap\.io\/assets\/icons/);
  assert.match(edge, /coin-images\.coingecko\.com/);
  assert.match(edge, /assets\.coingecko\.com/);
  assert.match(edge, /contentType\.toLowerCase\(\)\.startsWith\("image\/"\)/);
  assert.match(edge, /fetchFirstAvailable/);
});

test('enabled market pairs load logo metadata by exact CoinGecko id, not ambiguous ticker symbol', () => {
  const start = html.indexOf('function attachMarketAssetMetadata(');
  const end = html.indexOf('\nasync function loadMarkets(', start);
  assert.ok(start >= 0 && end > start, 'market metadata helper boundaries found');
  const context = {};
  vm.runInNewContext(html.slice(start, end) + '\nthis.attachMarketAssetMetadata=attachMarketAssetMetadata;', context);
  const rows = context.attachMarketAssetMetadata(
    [{symbol:'CATUSDT',price:'1',updated_at:'fresh'}, {symbol:'BTCUSDT',price:'2',updated_at:'fresh'}],
    [{pair_symbol:'CATUSDT',is_enabled:true,base_coingecko_id:'cat-token-a'}, {pair_symbol:'BTCUSDT',is_enabled:true,base_coingecko_id:'bitcoin'}],
    [{coingecko_id:'cat-token-a',symbol:'cat',name:'Cat Token A',image_url:'https://img.example/cat-a.png',price_change_percentage_24h:4,last_updated:'stale'}, {coingecko_id:'cat-token-b',symbol:'cat',name:'Cat Token B',image_url:'https://img.example/cat-b.png'}]
  );
  assert.equal(rows.length, 2);
  assert.equal(rows[0].name, 'Cat Token A');
  assert.equal(rows[0].image_url, 'https://img.example/cat-a.png');
  assert.equal(rows[0].change_updated_at, 'stale');
  assert.equal(rows[1].image_url, null);
  assert.equal(rows[1].coingecko_id, 'bitcoin');
});

test('market change fallback uses the crypto asset metadata timestamp, not the newer price timestamp', () => {
  const start = html.indexOf('function getMarketChange24h(item){');
  const end = html.indexOf('function compareMarketChange(', start);
  assert.ok(start >= 0 && end > start);
  const context = {
    getFreshMarketTicker: () => null,
    isMarketTimestampFresh: value => value === 'fresh'
  };
  vm.runInNewContext(html.slice(start, end) + '\nthis.getMarketChange24h=getMarketChange24h;', context);
  assert.equal(context.getMarketChange24h({change:12,updated_at:'fresh',change_updated_at:'stale'}), null);
  assert.equal(context.getMarketChange24h({change:12,updated_at:'stale',change_updated_at:'fresh'}), 12);
});

test('24h ticker batches retain successful results when an independent batch fails', () => {
  const start = html.indexOf('function collectMarketTickerBatchResults(');
  const end = html.indexOf('\nasync function fetchBinance24hrTickerRows(', start);
  assert.ok(start >= 0 && end > start, 'ticker batch collector boundaries found');
  const context = {};
  vm.runInNewContext(html.slice(start, end) + '\nthis.collectMarketTickerBatchResults=collectMarketTickerBatchResults;', context);
  const result = context.collectMarketTickerBatchResults([
    {status:'fulfilled',value:[{symbol:'BTCUSDT'},{symbol:'ETHUSDT'}]},
    {status:'rejected',reason:new Error('HTTP 502')},
    {status:'fulfilled',value:[{symbol:'SOLUSDT'}]}
  ]);
  assert.deepEqual(Array.from(result.rows, row => row.symbol), ['BTCUSDT','ETHUSDT','SOLUSDT']);
  assert.equal(result.errors.length, 1);
  assert.match(result.errors[0], /502/);
});

test('ticker fallback coverage is measured across the full enabled market, not only the first dozen pairs', () => {
  const start = html.indexOf('function isValidMarketChangeValue(');
  const end = html.indexOf('\nasync function refreshMarketTickersUnlocked(', start);
  assert.ok(start >= 0 && end > start, 'ticker coverage helpers found');
  const context = {};
  vm.runInNewContext(html.slice(start, end) + '\nthis.isValidMarketChangeValue=isValidMarketChangeValue; this.getMarketTickerCoverageThreshold=getMarketTickerCoverageThreshold;', context);
  assert.equal(context.getMarketTickerCoverageThreshold(398), 398);
  assert.equal(context.getMarketTickerCoverageThreshold(2), 2);
  assert.equal(context.isValidMarketChangeValue(null), false);
  assert.equal(context.isValidMarketChangeValue(undefined), false);
  assert.equal(context.isValidMarketChangeValue('0'), true);
  assert.equal(context.isValidMarketChangeValue('-2.5'), true);
});

test('market list rows use five aligned cells, 40px logos, visible Persian names and an unboxed favorite star', () => {
  const start = html.indexOf('function renderMarkets(){');
  const end = html.indexOf('function renderDashboardPortfolio(', start);
  const market = html.slice(start, end);
  assert.match(market, /persianName=String\(item\.name_fa\|\|persianCoinName\(item\.symbol\)\)/);
  assert.match(market, /class="coin-name-fa"/);
  assert.match(html, /digiarz-market-row-fix-20261119/);
  assert.match(html, /grid-template-columns:34px minmax\(0,1\.2fr\) minmax\(54px,\.55fr\) minmax\(82px,\.72fr\) minmax\(112px,\.86fr\)!important/);
  assert.match(html, /coin-identity \.coin-icon\{[\s\S]{0,100}width:40px!important;height:40px!important/);
  assert.match(html, /coin>\.favorite-btn\{[\s\S]{0,500}border:0!important/);
  assert.match(html, /coin-name-fa\{[\s\S]{0,200}display:block!important/);
  assert.match(html, /@media\(max-width:700px\)[\s\S]{0,900}grid-template-columns:30px minmax\(0,1fr\) minmax\(88px,auto\)!important/);
});


test('login screen uses the scoped premium light-blue-and-gold responsive design', () => {
  assert.match(html, /DigiArz premium authentication refresh/);
  assert.match(html, /#authView\.auth[\s\S]*?background:#fff/);
  assert.match(html, /#authView \.auth-visual[\s\S]*?linear-gradient\(145deg,#102b60 0%,#17458f 52%,#10234a 100%\)/);
  assert.match(html, /#authView #loginBtn[\s\S]*?linear-gradient\(135deg,#1746a2,#2864c7\)/);
  assert.match(html, /#authView #signupBtn[\s\S]*?background:#eef3fb/);
  assert.match(html, /@media\(max-width:700px\)[\s\S]*?#authView\.auth\{grid-template-columns:1fr/);
  assert.match(html, /@media\(prefers-reduced-motion:reduce\)[\s\S]*?#authView \*\{transition:none!important\}/);
  for (const id of ['fullName','email','password','loginBtn','signupBtn','forgotBtn','authMsg','recoveryPanel','newPassword','confirmPassword','saveNewPassword']) {
    assert.match(html, new RegExp('id="' + id + '"'), 'existing auth control remains: ' + id);
  }
});


test('login screen embeds a live market phone preview with rotating crypto tickers', () => {
  assert.match(html, /class="auth-phone-preview"/);
  assert.match(html, /id="authMiniChart"/);
  assert.match(html, /id="authCoinTrack"/);
  assert.match(html, /async function refreshAuthMiniChart\(\)/);
  assert.match(html, /async function refreshAuthCoinPrices\(\)/);
  assert.match(html, /authCoinRotationTimer=setInterval/);
  assert.match(html, /fetchBinanceKlines\('BTCUSDT','5m',36\)/);
  assert.match(html, /fetchBinanceResponse\('\/api\/v3\/ticker\/24hr\?symbol='/);
  assert.match(html, /body:not\(\.light-theme\) #authView\.auth/);
  assert.match(html, /body:not\(\.light-theme\) #authView \.auth-form/);
});

test('login screen has a complete branded header, market feature strip and a working theme switch', () => {
  assert.match(html, /class="auth-top-banner"/);
  assert.match(html, /class="auth-quick-stats"/);
  assert.match(html, /id="authThemeToggle"/);
  assert.match(html, /id="authThemeLabel"/);
  assert.match(html, /\$\('authThemeToggle'\)\?\.addEventListener\('click',cycleTheme\)/);
  assert.match(html, /const authThemeButton=\$\('authThemeToggle'\)/);
  assert.match(html, /body\.auth-page-active \.auth-top-banner/);
  assert.match(html, /@media\(max-width:760px\)[\s\S]*?#authView\.auth\{display:flex;flex-direction:column/);
  assert.match(html, /body:not\(\.light-theme\) #authView \.auth-form\{background:linear-gradient\(155deg,#172b45,#122238\)/);
  for (const id of ['fullName','email','password','loginBtn','signupBtn','forgotBtn','authMsg','recoveryPanel','newPassword','confirmPassword','saveNewPassword']) {
    assert.match(html, new RegExp('id="' + id + '"'), 'existing auth control remains: ' + id);
  }
});


test('daily advertisement module parses and remains a non-clickable image/text display', () => {
  const source = fs.readFileSync('src/daily-ads.js', 'utf8');
  assert.doesNotThrow(() => new vm.Script(source, { filename: 'src/daily-ads.js' }));
  assert.match(html, /id="loginDailyAd"/);
  assert.match(html, /id="dashboardDailyAd"/);
  assert.match(html, /id="adminDailyAdImage"/);
  assert.match(html, /id="adminDailyAdBody"/);
  assert.match(source, /getPublicUrl\(ad\.image_path\)/);
  assert.match(source, /from\('daily_ads'\)/);
  assert.match(source, /86400000/);
  assert.doesNotMatch(source, /createElement\(['"]a['"]\)|\.href\s*=/, 'daily ads must not render clickable links');
});


test('three visual themes are selectable, persisted, and backward-compatible', () => {
  for (const theme of ['light', 'dark', 'luxury']) assert.match(html, new RegExp('data-theme-choice="' + theme + '"'));
  assert.match(html, /function applyTheme\(theme\)/);
  assert.match(html, /document\.body\.classList\.toggle\('luxury-theme',luxury\)/);
  assert.match(html, /localStorage\.setItem\('digiArzTheme',selected\)/);
  assert.match(html, /\['light','dark','luxury'\]\.includes\(stored\)/);
  assert.match(html, /function cycleTheme\(\)/);
  assert.match(html, /body\.luxury-theme/);
  assert.match(html, /@supports not \(\(backdrop-filter:blur\(1px\)\) or \(-webkit-backdrop-filter:blur\(1px\)\)\)/);
  assert.match(html, /prefers-reduced-motion:reduce/);
});


test('approved DigiArz login reference is implemented as a real responsive vertical page', () => {
  const authStart=html.indexOf('<section id="authView" class="card auth login-screen">');
  const authEnd=html.indexOf('</section>\n<section id="loginDailyAd"',authStart);
  const ad=html.indexOf('id="loginDailyAd"',authStart);
  assert.ok(authStart>=0&&authEnd>authStart&&ad>authEnd,'daily ad is placed after the complete login card');
  const auth=html.slice(authStart,authEnd);
  for(const token of ['id="loginBrandbar"','class="login-hero"','class="login-globe-wrap"','class="login-orbit"','class="auth-phone-preview"','id="authMiniChart"','id="authCoinTrack"','class="login-card"']) assert.ok(auth.includes(token),'approved visual component exists: '+token);
  for(const symbol of ['BTCUSDT','ETHUSDT','BNBUSDT','XRPUSDT','SOLUSDT','TRXUSDT','DOGEUSDT','ADAUSDT','LINKUSDT','LTCUSDT']) assert.ok(html.includes("symbol:'"+symbol+"'"),'live ticker candidate exists: '+symbol);
  assert.match(html,/quoteVolume/,'visible market assets are ranked by returned 24h quote volume');
  assert.match(html,/loginEarthSpin/);
  assert.match(html,/loginOrbitSpin/);
  assert.match(html,/@media\(max-width:760px\)[\s\S]*?#authView \.login-market-layout\{grid-template-columns:1fr/);
  assert.match(html,/@media\(prefers-reduced-motion:reduce\)[\s\S]*?login-earth-svg/);
});

test('login password visibility control preserves the entered password and is accessible', () => {
  assert.match(html,/id="togglePasswordVisibility"/);
  assert.match(html,/input\.type=reveal\?'text':'password'/);
  assert.match(html,/button\.setAttribute\('aria-pressed',String\(reveal\)\)/);
  assert.match(html,/digiarz-login-password-toggle-20261119/);
});
