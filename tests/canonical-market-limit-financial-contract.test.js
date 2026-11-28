'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const read = (relativePath) => fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8');
const authoritative = read('supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql');
const canonicalCandidate = read('supabase/tests/canonical_asset_identity_candidate.sql');
const authoritativeIntegration = read('supabase/tests/authoritative_market_limit_source_parity.sql');
const feeHelperSnapshot = read('supabase/tests/canonical_identity_live_public_get_demo_trading_fee_rate_snapshot.sql');
const financialContract = read('docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md');

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
  assert.match(canonicalCandidate, /SET status='filled',price=v_price,filled_amount=amount,remaining_amount=0/);
  assert.doesNotMatch(canonicalCandidate, /pg_try_advisory_xact_lock\(739201126\)/);
});
test('authoritative Limit placement serializes wallet before base-ledger reservation and persists the full reservation lifecycle', () => {
  const walletLock = limitPlacement.indexOf('FROM public.wallets AS w');
  const baseLock = limitPlacement.indexOf('FROM public.asset_balances AS ab');
  assert.ok(walletLock >= 0, 'wallet row lock must exist');
  assert.ok(baseLock > walletLock, 'wallet must be locked before the base-asset row');
  assert.match(limitPlacement, /SUM\(GREATEST\([\s\S]*?reserved_amount\s*-\s*r\.consumed_amount\s*-\s*r\.released_amount/);
  assert.match(limitPlacement, /INSERT INTO public\.orders/);
  assert.match(limitPlacement, /INSERT INTO public\.order_reservations/);
  assert.match(limitPlacement, /released_amount,\s*consumed_amount,\s*status/);
});

test('authoritative Limit worker preserves cumulative reservation accounting and wallet-first settlement', () => {
  assert.match(limitWorker, /v_consumed\s*:=\s*v_reservation\.consumed_amount\s*\+\s*v_total/);
  assert.match(limitWorker, /v_target_remaining_reserve\s*:=\s*v_new_remaining\s*\*\s*v_order\.price\s*\*\s*\(1\s*\+\s*v_fee_rate\)/);
  assert.match(limitWorker, /v_released\s*:=\s*GREATEST\([\s\S]*?reserved_amount[\s\S]*?v_consumed[\s\S]*?v_target_remaining_reserve/);
  assert.match(limitWorker, /v_released\s*:=\s*LEAST\([\s\S]*?reserved_amount\s*-\s*v_consumed/);
  assert.match(limitWorker, /status\s*=\s*CASE[\s\S]*?WHEN v_new_remaining <= 0 THEN[\s\S]*?'released'[\s\S]*?'consumed'[\s\S]*?ELSE 'reserved'/);
  const walletLock = limitWorker.indexOf('FROM public.wallets AS w');
  const baseSettlement = limitWorker.indexOf('UPDATE public.asset_balances');
  assert.ok(walletLock >= 0, 'wallet row lock must exist');
  assert.ok(baseSettlement > walletLock, 'wallet must be locked before base-ledger settlement');
});


test('authoritative Market execution locks the wallet before sell-side base-ledger settlement', () => {
  const walletLock = market.indexOf('FROM public.wallets');
  const baseLock = market.indexOf('FROM public.asset_balances');
  assert.ok(walletLock >= 0, 'wallet row lock must exist');
  assert.ok(baseLock > walletLock, 'wallet must be locked before base-asset settlement');
  assert.match(market, /SUM\(r\.reserved_amount\s*-\s*r\.released_amount\s*-\s*r\.consumed_amount\)/);
  assert.match(market, /INSERT INTO public\.transactions/);
});

test('authoritative Market and Limit entrypoints subtract outstanding reservations before spending', () => {
  assert.match(market, /SUM\(r\.reserved_amount\s*-\s*r\.released_amount\s*-\s*r\.consumed_amount\)/);
  assert.match(market, /v_available\s*:=\s*v_balance\s*-\s*v_reserved/);
  assert.match(market, /v_available\s*:=\s*COALESCE\(v_asset_balance,\s*0\)\s*-\s*v_reserved/);
  assert.match(limitPlacement, /SUM\(GREATEST\([\s\S]*?r\.reserved_amount\s*-\s*r\.consumed_amount\s*-\s*r\.released_amount/);
  assert.match(authoritativeIntegration, /Existing USDT reservations must reduce available Market-buy funds/);
  assert.match(authoritativeIntegration, /Existing base-asset reservations must reduce available Market-sell funds/);
  assert.match(authoritativeIntegration, /Existing USDT reservations must reduce available Limit-buy funds/);
  assert.match(authoritativeIntegration, /Existing base-asset reservations must reduce available Limit-sell funds/);
  assert.equal((authoritativeIntegration.match(/INSERT INTO public\.orders\(id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status\)/g) || []).length, 4, 'each reservation regression must be backed by a pending order fixture');
  assert.equal((authoritativeIntegration.match(/DELETE FROM public\.orders WHERE id=/g) || []).length, 4, 'each synthetic pending order must be cleaned up');
});


test('captured Production fee helper NULL-liquidity gap remains explicit and cannot be mistaken for fail-closed behavior', () => {
  const feeGuard = feeHelperSnapshot.match(/IF\s+([\s\S]*?)\s+THEN\s+RAISE\s+EXCEPTION\s+'Invalid liquidity type'/i);
  assert.ok(feeGuard, 'captured Production fee helper validation guard must remain inspectable');
  assert.match(feeGuard[1], /p_liquidity_type\s+NOT\s+IN\s*\('maker',\s*'taker'\)/i);
  assert.doesNotMatch(feeGuard[1], /p_liquidity_type\s+IS\s+NULL/i);
  assert.match(feeHelperSnapshot, /ELSE\s+f\.taker_fee_rate/i);
  assert.match(financialContract, /NULL is accepted as taker instead of being rejected/);
  assert.match(financialContract, /must explicitly reject NULL/);
});

test('disposable fee-helper regression characterizes captured NULL behavior and requires explicit candidate rejection', () => {
  const feeRegression = read('supabase/tests/canonical_fee_helper_null_regression.sql');
  assert.match(feeRegression, /public\.get_demo_trading_fee_rate\('USDT',\s*NULL\)/);
  assert.match(feeRegression, /v_null_liquidity\s+IS\s+DISTINCT\s+FROM\s+v_taker/);
  assert.match(feeRegression, /p_liquidity_type\s+IS\s+NULL\s+OR\s+p_liquidity_type\s+NOT\s+IN\s*\('maker',\s*'taker'\)/);
  assert.match(feeRegression, /get_demo_trading_fee_rate\('USDT',\s*NULL\)/);
  assert.match(feeRegression, /get_demo_trading_fee_rate\('USDT',\s*'unknown'\)/);
  assert.match(feeRegression, /upper\(btrim\(p_quote_asset\)\)/);
});
