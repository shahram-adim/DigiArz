'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const read = (file) => fs.readFileSync(path.join(__dirname, '..', file), 'utf8');

function extractDefinition(source, schema, functionName) {
  const marker = 'CREATE OR REPLACE FUNCTION ' + schema + '.' + functionName + '(';
  const start = source.indexOf(marker);
  assert.notEqual(start, -1, schema + '.' + functionName + ': Production snapshot is missing');
  const opening = source.indexOf('AS $function$', start);
  assert.notEqual(opening, -1, schema + '.' + functionName + ': opening delimiter is missing');
  const closing = source.indexOf('$function$', opening + 'AS $function$'.length);
  assert.notEqual(closing, -1, schema + '.' + functionName + ': closing delimiter is missing');
  return source.slice(start, closing + '$function$'.length) + '\n';
}

const entries = [
  ['private','auto_activate_verified_exchange_pairs','fd177baeee1a5bdd927458413f69bfb6'],
  ['private','auto_list_verified_exchange_asset','49880c0892cad6081acb6ce071090a5d'],
  ['private','enforce_unique_admin_market_listing_symbol','6e9a7e9f7d8cd5f0ac20f3216ee5f0b3'],
  ['private','request_market_price_overflow','e6ed136175b0d340c9a86e51f7917a76'],
  ['private','guard_active_account_writes','29b8e23c1de8eb4762a8cf1a9c9343ce'],
  ['public','admin_add_market_listing','8b3d0c18e54b08f01c27bc24491e3448'],
  ['public','admin_enable_market_pair','848f7c1ebe114c558c1ce73e76dd13bd'],
  ['public','admin_review_market_listings','93e96328ff9b8d8f3739b57ce49eb397'],
  ['public','admin_search_market_assets','f5dfc59bd5c47065692601c46590cffc'],
  ['public','get_admin_market_listings','3b9243af942acf73ad72ab17faafda41'],
  ['public','get_crypto_assets','b85d4a1073e425c2ac29899152168cf2'],
  ['public','get_crypto_market','6cf991bfee5e7fb759fec4112962f788'],
  ['public','get_exchange_discovered_market_assets','87f9f56829abb50b2ff1fb878684e89c'],
  ['public','process_bit24_exchange_sync','9f3e6d7e20586ea79b7c021eebc6ab62'],
  ['public','process_iran_exchange_asset_sync','889c3728e54154a799e55ed8b9bc2edb'],
  ['public','recover_stale_crypto_assets_sync','9ab6efcdb72cce454244f81aecc1da86'],
  ['public','refresh_crypto_assets_toman','bc9daf5e57307e82fd5188798624b116'],
  ['public','refresh_crypto_assets','f14765ffd1166380f58e391b34163259'],
  ['public','request_market_price_refresh','140cb90d5a73059155d04fac4b309f4e']
];

const definitions = Object.fromEntries(entries.map(([schema,name,fingerprint]) => {
  const safe = schema + '_' + name;
  const snapshot = read('supabase/tests/canonical_identity_live_' + safe + '_snapshot.sql');
  return [safe, {
    snapshot,
    definition: extractDefinition(snapshot,schema,name),
    fingerprint
  }];
}));

for (const [schema,name,fingerprint] of entries) {
  const key = schema + '_' + name;
  test('live Production ' + key + ' matches its 2026-11-27 catalog fingerprint', () => {
    const item = definitions[key];
    assert.equal(createHash('md5').update(item.definition).digest('hex'), fingerprint);
    assert.match(item.snapshot, /TEST FIXTURE ONLY\. Never apply this file to Production/i);
    assert.match(item.snapshot, /owner=postgres/i);
  });
}

test('live active-account write guard remains attached to orders, trades and transactions', () => {
  const snapshot = definitions.private_guard_active_account_writes.snapshot;
  const definition = definitions.private_guard_active_account_writes.definition;
  assert.match(snapshot, /Attached BEFORE INSERT to public\.orders, public\.trades and public\.transactions/i);
  assert.match(definition, /current_account_is_active\(\)/i);
  assert.match(definition, /Account is inactive/i);
});

test('catalog refresh treats CoinGecko ID as conflict key but mutates the ticker field', () => {
  const source = definitions.public_refresh_crypto_assets.definition;
  assert.match(source, /ON CONFLICT\s*\(coingecko_id\)/i);
  assert.match(source, /symbol\s*=\s*EXCLUDED\.symbol/i);
  assert.match(source, /coingecko_id/i);
});

test('automatic exchange listing is blocked by ticker uniqueness and curated/pair collisions', () => {
  const autoList = definitions.private_auto_list_verified_exchange_asset.definition;
  const uniqueListing = definitions.private_enforce_unique_admin_market_listing_symbol.definition;
  assert.match(autoList, /count\(\*\)[\s\S]*?upper\(c2\.symbol\)[\s\S]*?=\s*1/i);
  assert.match(autoList, /dp\.pair_symbol\s*=\s*upper\(ca\.symbol\)\s*\|\|\s*'USDT'/i);
  assert.match(uniqueListing, /Another curated asset already uses this ticker/i);
  assert.match(uniqueListing, /Ticker conflicts with an existing demo trading pair/i);
});

test('automatic pair activation keeps curation, volume, rank and ticker-price gates', () => {
  const activation = definitions.private_auto_activate_verified_exchange_pairs.definition;
  const adminEnable = definitions.public_admin_enable_market_pair.definition;
  assert.match(activation, /JOIN public\.admin_market_listings/i);
  assert.match(activation, /mp\.symbol\s*=\s*pg_catalog\.upper\(ca\.symbol\)\s*\|\|\s*'USDT'/i);
  assert.match(activation, /ca\.total_volume_usd\s*>=\s*1000000/i);
  assert.match(activation, /ca\.market_cap_rank\s+IS\s+NULL[\s\S]*?ca\.market_cap_rank\s*<=\s*2000/i);
  assert.match(adminEnable, /admin-curated market list/i);
  assert.match(adminEnable, /total_volume_usd\s*<\s*1000000/i);
  assert.match(adminEnable, /market_cap_rank[\s\S]*?>\s*2000/i);
  assert.match(adminEnable, /market_prices/i);
});

test('market read API derives trade_enabled from a fresh ticker-keyed price alone, not enabled pair identity', () => {
  const market = definitions.public_get_crypto_market.definition;
  assert.match(market, /market_prices/i);
  assert.match(market, /mp\.symbol\s*=\s*ca\.symbol\s*\|\|\s*'USDT'/i);
  assert.match(market, /mp\.updated_at\s*>=\s*NOW\(\)\s*-\s*INTERVAL '1 minute'/i);
  assert.match(market, /trade_enabled/i);
  assert.doesNotMatch(market, /demo_trading_pairs|pair_id|base_asset_id|quote_asset_id/i);
});
test('exchange discovery/matching remains a separate staged process with ambiguous status', () => {
  const sync = definitions.public_process_iran_exchange_asset_sync.definition;
  const discovered = definitions.public_get_exchange_discovered_market_assets.definition;
  assert.match(sync, /exchange_asset_observations/i);
  assert.match(sync, /match_status\s*=\s*case[\s\S]*?'ambiguous'/i);
  assert.match(sync, /upper\(ca\.symbol\)\s*=\s*upper\(o\.base_symbol\)/i);
  assert.match(discovered, /exchange_asset_observations/i);
  assert.match(discovered, /match_status/i);
});

test('market-price refresh orchestration and overflow are included in the catalog dependency boundary', () => {
  assert.match(definitions.private_request_market_price_overflow.definition, /market_price_sync_requests/i);
  assert.match(definitions.public_request_market_price_refresh.definition, /refresh_market_prices/i);
});
