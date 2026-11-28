'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const read = (relativePath) => fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8');
const authoritative = read('supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql');
const canonicalCandidate = read('supabase/tests/canonical_asset_identity_candidate.sql');

function functionBody(source, name, label) {
  const pattern = new RegExp(
    'CREATE OR REPLACE FUNCTION\\s+(?:public\\.)?' + name +
    '\\s*\\([\\s\\S]*?\\)\\s*RETURNS[\\s\\S]*?AS\\s+\\$function\\$([\\s\\S]*?)\\$function\\$',
    'i'
  );
  const match = source.match(pattern);
  assert.ok(match, label + ': function ' + name + ' not found');
  return match[1];
}

const market = functionBody(authoritative, 'execute_demo_trade', 'Authoritative migration');
const limitPlacement = functionBody(authoritative, 'place_limit_order', 'Authoritative migration');
const limitWorker = functionBody(authoritative, 'process_limit_orders', 'Authoritative migration');

test('authoritative Market execution retains auth, active-account, enabled-pair and one-minute price gates', () => {
  assert.match(market, /auth\.uid\(\)/);
  assert.match(market, /current_account_is_active\(\)/);
  assert.match(market, /demo_trading_pairs[\s\S]*?pair_symbol\s*=\s*v_symbol[\s\S]*?is_enabled\s+IS\s+TRUE/);
  assert.match(market, /market_prices[\s\S]*?symbol\s*=\s*v_symbol[\s\S]*?updated_at\s*>=\s*now\(\)\s*-\s*interval\s+'1 minute'/);
  assert.match(market, /get_demo_trading_fee_rate\('USDT',\s*'taker'\)/);
});

test('authoritative Market execution preserves eight-decimal gross/fee rounding and all financial ledgers', () => {
  assert.match(market, /v_gross\s*:=\s*round\(p_amount\s*\*\s*v_price,\s*8\)/i);
  assert.match(market, /v_fee\s*:=\s*round\(v_gross\s*\*\s*v_fee_rate,\s*8\)/i);
  assert.match(market, /wallets[\s\S]*?FOR UPDATE/i);
  assert.match(market, /asset_balances/);
  assert.match(market, /INSERT INTO public\.orders/);
  assert.match(market, /INSERT INTO public\.trades/);
  assert.match(market, /INSERT INTO public\.transactions/);
});

test('authoritative Limit placement keeps maker reserve formula and production wallet/base-ledger model', () => {
  assert.match(limitPlacement, /current_account_is_active\(\)/);
  assert.match(limitPlacement, /demo_trading_pairs[\s\S]*?pair_symbol\s*=\s*v_symbol[\s\S]*?is_enabled\s+IS\s+TRUE/);
  assert.match(limitPlacement, /get_demo_trading_fee_rate\('USDT',\s*'maker'\)/);
  assert.match(limitPlacement, /p_amount\s*\*\s*p_limit_price\s*\*\s*\(1\s*\+\s*v_fee_rate\)/);
  assert.match(limitPlacement, /wallets[\s\S]*?FOR UPDATE/i);
  assert.match(limitPlacement, /asset_balances[\s\S]*?FOR UPDATE/i);
  assert.match(limitPlacement, /reserved_amount[\s\S]*?consumed_amount[\s\S]*?released_amount/);
});

test('authoritative Limit worker keeps serialization, active-profile, freshness and 25%-of-original partial fills', () => {
  assert.match(limitWorker, /pg_try_advisory_xact_lock\(739201126\)/);
  assert.match(limitWorker, /FOR UPDATE SKIP LOCKED/);
  assert.match(limitWorker, /profiles[\s\S]*?is_active\s+IS\s+TRUE/);
  assert.match(limitWorker, /market_prices[\s\S]*?updated_at\s*>=\s*now\(\)\s*-\s*interval\s+'1 minute'/);
  assert.match(limitWorker, /v_qty\s*:=\s*LEAST\(v_remaining,\s*v_order\.amount\s*\*\s*0\.25\)/);
  assert.match(limitWorker, /wallets[\s\S]*?FOR UPDATE/i);
  assert.match(limitWorker, /order_reservations[\s\S]*?consumed_amount[\s\S]*?released_amount/);
  assert.match(limitWorker, /INSERT INTO public\.trades/);
  assert.match(limitWorker, /INSERT INTO public\.transactions/);
});

test('authoritative Limit worker has no explicit round(...,8); do not misapply Market rounding semantics', () => {
  assert.doesNotMatch(limitWorker, /\bround\s*\([^)]*,\s*8\s*\)/i);
  assert.match(limitWorker, /v_fee\s*:=\s*v_gross\s*\*\s*v_fee_rate/);
});

test('current canonical identity prototype is explicitly not a financial-source-parity implementation', () => {
  assert.match(canonicalCandidate, /CREATE TABLE canonical_asset_candidate\.balances/);
  assert.doesNotMatch(canonicalCandidate, /CREATE TABLE canonical_asset_candidate\.wallets/);
  assert.match(canonicalCandidate, /v_fee\s*:=\s*v_quote_value\s*\*\s*0\.001/);
  assert.match(canonicalCandidate, /observed_at\s*>=\s*clock_timestamp\(\)\s*-\s*interval\s+'2 minutes'/);
  assert.match(canonicalCandidate, /DELETE FROM canonical_asset_candidate\.reservations/);
  assert.match(canonicalCandidate, /v_qty\s*:=\s*v_order\.remaining_amount/);
  assert.doesNotMatch(canonicalCandidate, /pg_try_advisory_xact_lock\(739201126\)/);
});
