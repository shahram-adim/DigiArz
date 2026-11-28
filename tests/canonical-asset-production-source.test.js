'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const read = (file) => fs.readFileSync(path.join(__dirname, '..', file), 'utf8');

function extractDefinition(source, functionName) {
  const start = source.indexOf('CREATE OR REPLACE FUNCTION public.' + functionName + '(');
  assert.notEqual(start, -1, functionName + ': Production snapshot is missing');
  const opening = source.indexOf('AS $function$', start);
  assert.notEqual(opening, -1, functionName + ': opening delimiter is missing');
  const closing = source.indexOf('$function$', opening + 'AS $function$'.length);
  assert.notEqual(closing, -1, functionName + ': closing delimiter is missing');
  return source.slice(start, closing + '$function$'.length) + '\n';
}

const entries = [
  ['execute_demo_trade', '4289e358b0c7293fc33f86c2511486d7'],
  ['get_demo_trading_fee_rate', '546d80d7105228ed97da26c5ed0c7b7f'],
  ['place_conditional_exit_order', 'e4de4667d89e6663f04d92d47ac4d5cf'],
  ['cancel_conditional_exit_order', 'efa4c8a200d299f76b0d2cbe2d0b49e9'],
  ['process_conditional_orders', '5cfbf0e2e73474ae64e42643b3feb28a'],
  ['place_stop_limit_order', 'd6f4ff7478b83fbabbab519c7c711bcd'],
  ['cancel_stop_limit_order', '82cedc2c442b0c826a8684044aed5f8d'],
  ['admin_disable_market_pair', '07ff2862b133f6dbeb3c0cf5d33c5878'],
  ['refresh_market_prices', '3788666d57957a66bf59031f54ceff03']
];

const definitions = Object.fromEntries(entries.map(([name, fingerprint]) => {
  const snapshot = read('supabase/tests/canonical_identity_live_' + name + '_snapshot.sql');
  const definition = extractDefinition(snapshot, name);
  return [name, { snapshot, definition, fingerprint }];
}));

for (const [name, fingerprint] of entries) {
  test('live Production ' + name + ' snapshot matches its 2026-11-27 catalog fingerprint', () => {
    const { snapshot, definition } = definitions[name];
    assert.equal(createHash('md5').update(definition).digest('hex'), fingerprint);
    assert.match(snapshot, /TEST FIXTURE ONLY\. Never apply this file to Production/i);
    assert.match(definition, /SECURITY DEFINER/i);
    assert.match(definition, /SET search_path TO/i);
  });
}

test('live Production fee helper selects configured maker/taker rates and fails closed', () => {
  const fee = definitions.get_demo_trading_fee_rate.definition;
  assert.match(fee, /p_liquidity_type\s+NOT IN\s*\('maker',\s*'taker'\)/i);
  assert.match(fee, /f\.maker_fee_rate\s+ELSE\s+f\.taker_fee_rate/i);
  assert.match(fee, /FROM public\.demo_trading_fees AS f/i);
  assert.match(fee, /f\.quote_asset\s*=\s*upper\(btrim\(p_quote_asset\)\)/i);
  assert.match(fee, /f\.is_enabled\s+IS TRUE/i);
  assert.match(fee, /Trading fee is not configured for quote asset/i);
  assert.doesNotMatch(fee, /0\.001|0\.1%/i);
});

test('live Market and conditional entrypoints still resolve the trading pair by mutable display ticker', () => {
  const market = definitions.execute_demo_trade.definition;
  const placeTpSl = definitions.place_conditional_exit_order.definition;
  const placeStop = definitions.place_stop_limit_order.definition;

  assert.match(market, /v_base\s*:=\s*left\(v_symbol,\s*length\(v_symbol\)\s*-\s*4\)/i);
  assert.match(market, /dp\.pair_symbol\s*=\s*v_symbol/i);
  assert.match(market, /mp\.symbol\s*=\s*v_symbol/i);
  assert.match(placeTpSl, /p\.pair_symbol\s*=\s*v_symbol/i);
  assert.match(placeStop, /p\.pair_symbol\s*=\s*v_symbol/i);
  assert.doesNotMatch(market, /pair_id|base_asset_id|quote_asset_id/i);
  assert.doesNotMatch(placeTpSl, /pair_id|base_asset_id|quote_asset_id/i);
  assert.doesNotMatch(placeStop, /pair_id|base_asset_id|quote_asset_id/i);
});

test('live TP/SL and Stop-Limit workers resolve prices and child execution through display symbol', () => {
  const conditional = definitions.process_conditional_orders.definition;
  const cancelConditional = definitions.cancel_conditional_exit_order.definition;
  const cancelStop = definitions.cancel_stop_limit_order.definition;

  assert.match(conditional, /mp\.symbol\s*=\s*v_cond\.symbol/i);
  assert.match(conditional, /execute_demo_trade\(v_cond\.symbol/i);
  assert.match(cancelConditional, /WHERE\s+order_id\s*=\s*p_order_id/i);
  assert.match(cancelStop, /v_cond\.execution_order_id/i);
  assert.match(cancelStop, /cancel_limit_order\(v_child\.id\)/i);
  assert.doesNotMatch(conditional, /pair_id|base_asset_id|quote_asset_id/i);
  assert.doesNotMatch(cancelConditional, /pair_id|base_asset_id|quote_asset_id/i);
  assert.doesNotMatch(cancelStop, /pair_id|base_asset_id|quote_asset_id/i);
});

test('live pair-disable cleanup is ticker-scoped and must be replaced with pair_id scope', () => {
  const disable = definitions.admin_disable_market_pair.definition;
  assert.match(disable, /o\.symbol\s*=\s*v_pair\.pair_symbol/i);
  assert.match(disable, /WHERE\s+symbol\s*=\s*v_pair\.pair_symbol/i);
  assert.doesNotMatch(disable, /pair_id|base_asset_id|quote_asset_id/i);
});

test('live market-price refresh upserts by symbol rather than canonical pair identity', () => {
  const refresh = definitions.refresh_market_prices.definition;
  assert.match(refresh, /SELECT\s+dp\.pair_symbol\s+AS\s+symbol/i);
  assert.match(refresh, /INSERT INTO public\.market_prices\(symbol,price,source,updated_at\)/i);
  assert.match(refresh, /ON CONFLICT\(symbol\) DO UPDATE/i);
  assert.doesNotMatch(refresh, /pair_id|base_asset_id|quote_asset_id/i);
});

test('captured function snapshots retain production execution boundaries', () => {
  for (const [name] of entries) {
    const snapshot = definitions[name].snapshot;
    assert.match(snapshot, /owner=postgres; SECURITY DEFINER=true;/i, name + ': owner/security metadata');
    assert.match(snapshot, /EXECUTE anon=false/i, name + ': anon execution must remain denied');
  }
  assert.match(definitions.process_conditional_orders.snapshot, /authenticated=false, service_role=true/i);
  assert.match(definitions.refresh_market_prices.snapshot, /authenticated=false, service_role=false/i);
});
