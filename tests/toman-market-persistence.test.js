'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

let persistencePromise;
const persistence = () => persistencePromise ??= import('../supabase/functions/refresh-toman-market-prices/persistence.mjs');

test('deduplicates rows by the live exchange/asset/quote unique key and keeps the first row', async () => {
  const { dedupeTomanPriceRows } = await persistence();
  const first = { exchange: 'Nobitex', asset_symbol: 'btc', quote_currency: 'toman', price_toman: 100 };
  const duplicate = { exchange: 'nobitex', asset_symbol: 'BTC', quote_currency: 'TOMAN', price_toman: 101 };
  const separateExchange = { exchange: 'wallex', asset_symbol: 'BTC', quote_currency: 'TOMAN', price_toman: 102 };
  const separateQuote = { exchange: 'nobitex', asset_symbol: 'BTC', quote_currency: 'USDT', price_toman: 103 };
  const result = dedupeTomanPriceRows([first, duplicate, separateExchange, separateQuote]);
  assert.equal(result.rows.length, 3);
  assert.equal(result.duplicateCount, 1);
  assert.equal(result.rows[0], first);
  assert.equal(result.rows[1], separateExchange);
  assert.equal(result.rows[2], separateQuote);
});

test('rejects rows without a complete unique key instead of silently collapsing them', async () => {
  const { dedupeTomanPriceRows } = await persistence();
  assert.throws(() => dedupeTomanPriceRows([{ exchange: 'nobitex', asset_symbol: 'BTC' }]), /unique key/);
});

test('builds a PostgREST merge-duplicates request matching the current-price unique constraint', async () => {
  const { buildTomanPriceUpsertRequest } = await persistence();
  const rows = [{ exchange: 'nobitex', asset_symbol: 'BTC', quote_currency: 'TOMAN', price_toman: 123 }];
  const request = buildTomanPriceUpsertRequest('https://example.supabase.co', rows);
  const url = new URL(request.url);
  assert.equal(url.pathname, '/rest/v1/market_toman_prices');
  assert.equal(url.searchParams.get('on_conflict'), 'exchange,asset_symbol,quote_currency');
  assert.equal(request.headers.Prefer, 'resolution=merge-duplicates,return=minimal');
  assert.deepEqual(JSON.parse(request.body), rows);
  assert.throws(() => buildTomanPriceUpsertRequest('https://example.supabase.co', []), /At least one/);
});

test('provider summaries expose stable error codes without raw upstream messages', async () => {
  const { summarizeProviderResults } = await persistence();
  const summary = summarizeProviderResults([
    { status: 'fulfilled', value: [{}, {}] },
    { status: 'rejected', reason: new Error('Wallex HTTP 429 secret=do-not-log') },
    { status: 'rejected', reason: new Error('AbortError: request timed out') },
    { status: 'rejected', reason: new Error('invalid markets response') },
  ], ['nobitex', 'wallex', 'bitpin', 'other']);
  assert.deepEqual(summary, [
    { provider: 'nobitex', ok: true, count: 2 },
    { provider: 'wallex', ok: false, count: 0, error_code: 'http_429' },
    { provider: 'bitpin', ok: false, count: 0, error_code: 'timeout' },
    { provider: 'other', ok: false, count: 0, error_code: 'invalid_or_empty_response' },
  ]);
  assert.equal(JSON.stringify(summary).includes('do-not-log'), false);
});

test('the Edge Function handler uses the tested upsert and de-duplication helpers', () => {
  const source = fs.readFileSync(path.join(__dirname, '../supabase/functions/refresh-toman-market-prices/index.ts'), 'utf8');
  assert.match(source, /buildTomanPriceUpsertRequest/);
  assert.match(source, /dedupeTomanPriceRows/);
  assert.match(source, /toman_market_provider_results/);
});

test('the refresh handler never deletes current-price rows from a partial provider snapshot', () => {
  const source = fs.readFileSync(path.join(__dirname, '../supabase/functions/refresh-toman-market-prices/index.ts'), 'utf8');
  assert.doesNotMatch(source, /\bDELETE\b/i);
  assert.doesNotMatch(source, /current_price_cleanup/);
  assert.match(source, /Retain omitted rows/);
  assert.match(source, /old fetched_at values as stale/);
});
