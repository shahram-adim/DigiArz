'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('src/digiarz-independent-ui.css', 'utf8');

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

test('trade history loads older pages with a stable keyset cursor and preserves exact values', () => {
  assert.match(html, /id="loadMoreHistoryBtn"/);
  assert.match(html, /historyPageSize=50/);
  const start = html.indexOf('async function loadHistory(){');
  const end = html.indexOf('function exportHistoryCsv(){', start);
  assert.ok(start >= 0 && end > start, 'history loading function boundaries found');
  const body = html.slice(start, end);
  assert.ok(body.includes('.range(0,historyPageSize-1)'), 'each page uses a bounded range');
  assert.ok(body.includes('historyCursor=historyRows.length?historyRows[historyRows.length-1]:null'), 'first page stores the final row as cursor');
  assert.ok(body.includes('if(!historyCursor?.created_at||!historyCursor?.id)'), 'cursor requires timestamp and ID');
  assert.ok(body.includes('created_at.lt.${cursor.created_at},and(created_at.eq.${cursor.created_at},id.lt.${cursor.id})'), 'older pages use timestamp plus ID tie-breaker');
  assert.ok(body.includes(".order('created_at',{ascending:false}).order('id',{ascending:false})"), 'all pages use deterministic ordering');
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

test('market and dashboard gain/loss filters use freshness-aware ranking; obsolete panels stay removed', () => {
  assert.doesNotMatch(html, /function renderTopGainers|function renderTopLosers/);
  assert.doesNotMatch(html, /topGainersList|topLosersList|allGainersBtn|allLosersBtn/);
  const marketStart = html.indexOf('function renderMarkets(){');
  const marketEnd = html.indexOf('function renderDashboardPortfolio(', marketStart);
  const market = html.slice(marketStart, marketEnd);
  assert.ok(market.includes("activeMarketCategory==='gainers'"), 'market retains its gainers category filter');
  assert.ok(market.includes("activeMarketCategory==='losers'"), 'market retains its losers category filter');
  assert.ok(market.includes("compareMarketChange(a,b,'desc')"), 'market gainers use freshness-aware descending comparison');
  assert.ok(market.includes("compareMarketChange(a,b,'asc')"), 'market losers use freshness-aware ascending comparison');
  const dashboardStart = html.indexOf('function renderDashboardMarketPreview(){');
  const dashboardEnd = html.indexOf('function renderDashboardPortfolio(', dashboardStart);
  const dashboard = html.slice(dashboardStart, dashboardEnd);
  assert.ok(dashboard.includes("dashboardMarketFilter==='gainers'"), 'dashboard keeps a gainers filter');
  assert.ok(dashboard.includes("dashboardMarketFilter==='losers'"), 'dashboard keeps a losers filter');
  assert.ok(dashboard.includes("compareMarketChange(a.item,b.item,'desc')"), 'dashboard gainers use the shared comparator');
  assert.ok(dashboard.includes("compareMarketChange(a.item,b.item,'asc')"), 'dashboard losers use the shared comparator');
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

test('market rows preserve Persian and English identity, 24h change, prices and frameless controls', () => {
  const start = html.indexOf('function renderMarkets(){');
  const end = html.indexOf('function renderDashboardPortfolio(', start);
  const market = html.slice(start, end);
  assert.ok(market.includes('persianName=String(marketPersianName(item))'));
  assert.match(market, /class="coin-name-fa"/);
  assert.match(market, /class="coin-symbol-en"/);
  assert.match(market, /class="coin-english-name"/);
  assert.match(market, /div\.append\(star,identity,sparkline,changeWrap,price\)/);
  assert.match(css, /#marketList>\.coin\{[\s\S]*?grid-template-areas:"fav identity spark change price"/);
  assert.match(css, /#marketList>\.coin>\.favorite-btn\{[\s\S]*?border:0!important/);
  assert.match(css, /#marketList>\.coin \.coin-icon\{[\s\S]*?width:40px!important;height:40px!important[\s\S]*?border:0!important/);
  assert.match(css, /#marketList>\.coin \.coin-name-fa\{[\s\S]*?display:block!important/);
  assert.match(css, /@media\(max-width:760px\)[\s\S]*?grid-template-areas:"fav identity price" "fav change price"/);
});

test('login screen uses the selected Binance-inspired black-and-yellow palette without changing auth behavior', () => {
  const marker = '/* DigiArz selected Binance-inspired black-and-yellow auth palette — 2026-11-21 */';
  const paletteStart = html.lastIndexOf(marker);
  const styleEnd = html.lastIndexOf('</style>');
  assert.ok(paletteStart >= 0 && styleEnd > paletteStart, 'final brand override is present at the end of the stylesheet');
  const palette = html.slice(paletteStart, styleEnd);
  assert.ok(palette.includes('#authView.auth-reference-layout{'), 'final palette scopes to the reference auth layout');
  assert.ok(palette.includes('background:#0b0e11!important'), 'outer auth surface uses black');
  assert.ok(palette.includes('linear-gradient(155deg,#181a20 0%,#0b0e11 60%,#11151c 100%)!important'), 'visual panel uses charcoal and black');
  assert.ok(palette.includes('linear-gradient(145deg,#181a20,#0b0e11 72%)!important'), 'form panel uses charcoal and black');
  assert.ok(palette.includes('#f0b90b'), 'selected brand yellow remains the primary accent');
  assert.ok(palette.includes('background:#252a33!important'), 'signup button remains a secondary charcoal action');
  assert.ok(html.includes('@media(max-width:760px){') && html.includes('#authView.auth-reference-layout{margin:0 auto 18px!important}'), 'existing mobile layout remains');
  for (const id of ['email','password','loginBtn','signupBtn','forgotBtn','authMsg','recoveryPanel','newPassword','confirmPassword','saveNewPassword']) {
    assert.match(html, new RegExp('id="' + id + '"'), 'existing auth control remains: ' + id);
  }
  assert.doesNotMatch(html, /id="fullName"/, 'registration no longer asks for first or last name');
  const signupStart = html.indexOf('async function signup(){');
  const loginStart = html.indexOf('async function login(){', signupStart);
  assert.ok(signupStart >= 0 && loginStart > signupStart, 'signup handler remains separate from login');
  const signupBody = html.slice(signupStart, loginStart);
  assert.ok(signupBody.includes('auth.signUp({email,password,emailRedirectTo:'), 'signup uses email and password only');
  assert.ok(!signupBody.includes('full_name') && !signupBody.includes('fullName'), 'signup does not read or submit a name');
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

test('reference login has its branded market header, live coin list and working theme switch', () => {
  assert.match(html, /class="ref-brandbar"/);
  assert.match(html, /class="ref-live-pill"/);
  assert.match(html, /class="ref-coin-list"/);
  for (const symbol of ['BTCUSDT','ETHUSDT','USDTUSDT','SOLUSDT']) {
    assert.match(html, new RegExp('data-ref-market="' + symbol + '"'));
  }
  assert.match(html, /id="authThemeToggle"/);
  assert.match(html, /id="authThemeLabel"/);
  assert.match(html, /\$\('authThemeToggle'\)\?\.addEventListener\('click',cycleTheme\)/);
  assert.match(html, /const authThemeButton=\$\('authThemeToggle'\)/);
  assert.match(html, /@media\(max-width:760px\)[\s\S]*?#authView\.auth\{display:flex;flex-direction:column/);
  assert.ok(html.lastIndexOf('/* DigiArz selected Binance-inspired black-and-yellow auth palette — 2026-11-21 */') > html.indexOf('/* Faithful reconstruction of the approved DigiArz login reference */'), 'final brand palette overrides the earlier reference colors');
  for (const id of ['email','password','loginBtn','signupBtn','forgotBtn','authMsg','recoveryPanel','newPassword','confirmPassword','saveNewPassword']) {
    assert.match(html, new RegExp('id="' + id + '"'), 'existing auth control remains: ' + id);
  }
  assert.doesNotMatch(html, /id="fullName"/, 'registration no longer asks for first or last name');
  assert.match(html, /async function signup\(\)[\s\S]*?auth\.signUp\(\{email,password,emailRedirectTo:/, 'signup uses email and password only');
  assert.doesNotMatch(html, /full_name:name|\$\('fullName'\)/, 'signup does not read or submit a name');
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


test('reference login hero keeps the globe, handset and floating branded crypto coins together', () => {
  assert.match(html, /class="auth-scene ref-scene"/);
  assert.match(html, /class="auth-earth ref-earth"/);
  assert.match(html, /id="refGlobeClip"/);
  assert.match(html, /class="auth-phone-device ref-phone"/);
  assert.match(html, /class="auth-floating-coin auth-floating-coin-btc ref-gold-coin"/);
  assert.match(html, /class="auth-floating-coin auth-floating-coin-eth ref-gold-coin"/);
  assert.match(html, /class="ref-usdt-coin"/);
  assert.match(html, /assets\.coincap\.io\/assets\/icons\/(?:btc|eth|sol|usdt)@2x\.png/);
  assert.match(html, /authCoinLogoUrl\(coin\.label\)/);
  assert.match(html, /auth-coin-chip img/);
});

test('login mini chart renders real five-minute candles without depending on a chart CDN', () => {
  assert.match(html, /function renderAuthMiniChart\(candles\)/);
  assert.match(html, /۳۶ کندل واقعی پنج دقیقه‌ای بیت‌کوین/);
  assert.match(html, /renderAuthMiniChart\(candles\)/);
  assert.match(html, /renderAuthMiniChart\(\[\]\)/);
  assert.match(html, /fetchBinanceKlines\('BTCUSDT','5m',36\)/);
  assert.match(html, /<svg viewBox=/);
});

test('Toman market summary reports observed sources, freshness, and source timestamps', () => {
  const start = html.indexOf('function summarizeTomanMarketRows(rows){');
  const end = html.indexOf("function showTomanStatus(message,type=''){", start);
  assert.ok(start >= 0 && end > start, 'Toman summary helper boundaries found');
  const sandbox = {};
  vm.runInNewContext(html.slice(start, end) + '\nglobalThis.summarizeTomanMarketRows=summarizeTomanMarketRows;', sandbox);
  const summary = sandbox.summarizeTomanMarketRows([
    { exchange: 'Nobitex', is_stale: false, fetched_at: '2026-11-23T10:00:00.000Z' },
    { exchange: 'wallex', is_stale: false, fetched_at: '2026-11-23T10:01:00.000Z' },
    { exchange: 'WALLEX', is_stale: true, fetched_at: '2026-11-23T10:02:00.000Z' },
    { exchange: 'bit24', is_stale: true, fetched_at: '2026-11-23T10:03:00.000Z' },
    { exchange: '', is_stale: true, fetched_at: 'invalid' },
    { exchange: 'bit24', is_stale: null, fetched_at: '2026-11-23T10:04:00.000Z' },
    { exchange: 'kifpool', fetched_at: '2026-11-23T10:05:00.000Z' }
  ]);
  assert.deepEqual(JSON.parse(JSON.stringify(summary)), {
    rowCount: 7,
    sourceCount: 4,
    freshRowCount: 2,
    freshSourceCount: 2,
    latestFetchedAt: '2026-11-23T10:05:00.000Z'
  });
  const loadStart = html.indexOf('async function loadTomanMarket(){');
  const loadEnd = html.indexOf('async function refreshTomanMarket()', loadStart);
  assert.ok(loadStart >= 0 && loadEnd > loadStart, 'Toman loader boundaries found');
  const loader = html.slice(loadStart, loadEnd);
  assert.ok(loader.includes('summarizeTomanMarketRows(filtered)'), 'loader uses the tested summary');
  assert.ok(loader.includes('summary.latestFetchedAt'), 'loader displays the real source timestamp');
  assert.ok(loader.includes('rows.some(r=>r.is_stale===false)'), 'only an explicit fresh flag counts as fresh');
  assert.ok(loader.includes("r.is_stale!==false"), 'unknown row freshness is not displayed as fresh');
  assert.match(loader, /catch\(_\)[\s\S]*?return false;/, 'Supabase read failures return an explicit error state');
  assert.doesNotMatch(loader, /Object\.keys\(tomanExchangeNames\)\.length/, 'configured labels are not reported as active sources');
});


test('Toman market loader renders a safe error state when the Supabase read fails', async () => {
  const start = html.indexOf('async function loadTomanMarket(){');
  const end = html.indexOf('async function refreshTomanMarket()', start);
  assert.ok(start >= 0 && end > start, 'Toman loader boundaries found');
  const body = { innerHTML: '' };
  const status = { message: '', type: '' };
  const context = {
    $: id => id === 'tomanMarketBody' ? body : id === 'tomanSearch' ? { value: '' } : null,
    fetchAllSupabaseRows: async () => { throw new Error('private database detail'); },
    showTomanStatus: (message, type) => { status.message = message; status.type = type; }
  };
  vm.runInNewContext(html.slice(start, end) + '\nthis.loadTomanMarket=loadTomanMarket;', context);
  const loaded = await context.loadTomanMarket();
  assert.equal(loaded, false);
  assert.equal(status.type, 'err');
  assert.match(status.message, /تازگی داده‌ها قابل تأیید نیست/);
  assert.match(body.innerHTML, /دریافت داده‌های بازار تومانی ناموفق بود/);
  assert.doesNotMatch(body.innerHTML, /private database detail/);
  assert.equal(context.tomanMarketHasFreshRows, false);
});

test('Toman refresh distinguishes a successful write from a failed table reload', async () => {
  const start = html.indexOf('async function refreshTomanMarket(){');
  const end = html.indexOf('\nfunction formatExchangeSyncDate', start);
  assert.ok(start >= 0 && end > start, 'Toman refresh boundaries found');
  const button = { disabled: false };
  const status = { message: '', type: '' };
  const context = {
    $: id => id === 'tomanRefreshBtn' ? button : null,
    showTomanStatus: (message, type) => { status.message = message; status.type = type; },
    supabaseClient: {
      auth: { getSession: async () => ({ data: { session: { access_token: 'test-token' } }, error: null }) },
      functions: { invoke: async () => ({ data: { success: true, saved: 373, sources: { nobitex: { ok: true, count: 221 } } }, error: null }) }
    },
    loadTomanMarket: async () => false,
    tomanExchangeNames: { nobitex: 'نوبیتکس' }
  };
  vm.runInNewContext(html.slice(start, end) + '\nthis.refreshTomanMarket=refreshTomanMarket;', context);
  await context.refreshTomanMarket();
  assert.equal(button.disabled, false);
  assert.equal(status.type, 'err');
  assert.match(status.message, /ذخیره 373 قیمت انجام شد، اما بازخوانی جدول ناموفق بود/);
});


test('market metadata batch failures do not reject the entire market load', () => {
  const start = html.indexOf('async function loadMarkets(');
  const end = html.indexOf('\nlet marketExtrasLoaded=', start);
  assert.ok(start >= 0 && end > start, 'market loader boundaries found');
  const loader = html.slice(start, end);
  assert.match(loader, /Promise\.allSettled\(metadataChunks\.map/);
  assert.match(loader, /collectMarketTickerBatchResults\(metadataResults\)/);
  assert.match(loader, /metadataCollected\.rows/);
  assert.match(loader, /Some market asset metadata batches failed/);
});
