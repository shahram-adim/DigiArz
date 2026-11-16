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
