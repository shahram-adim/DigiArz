'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const read = (name) => fs.readFileSync(name, 'utf8');
const worker = read('supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql');
const entrypoints = read('supabase/drafts/2026-11-15_exact_decimal_entrypoint_candidates.sql');
const widening = read('supabase/drafts/2026-11-15_exact_decimal_type_widening.sql');
const stopLimitSync = read('supabase/drafts/2026-11-16_exact_decimal_process_stop_limit_orders.sql');
const rollout = read('supabase/drafts/2026-11-16_exact_decimal_rollout_candidate.sql');
const livePreflight = read('supabase/drafts/2026-11-16_exact_decimal_live_preflight.sql');

test('candidate SQL remains explicitly draft-only and outside migrations', () => {
  for (const sql of [worker, entrypoints, widening, stopLimitSync, rollout]) {
    assert.match(sql, /DRAFT ONLY — DO NOT APPLY TO PRODUCTION/);
  }
  assert.ok(fs.existsSync('supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql'));
  assert.ok(!fs.existsSync('supabase/migrations/20261115_exact_decimal_process_limit_orders.sql'));
  assert.ok(!fs.existsSync('supabase/migrations/20261116_exact_decimal_rollout_candidate.sql'));
  assert.match(rollout, /SET LOCAL lock_timeout = '5s'/);
  assert.match(rollout, /SET LOCAL statement_timeout = '30s'/);
  assert.match(rollout, /REVOKE ALL ON FUNCTION public\.process_limit_orders/);
  assert.match(rollout, /FOR UPDATE OF c,parent,child SKIP LOCKED/);
  assert.doesNotMatch(livePreflight, /\b(INSERT|UPDATE|DELETE|ALTER|DROP|CREATE|TRUNCATE|CALL)\b/i);
});

test('atomic rollout locks target tables before preflight and verifies every numeric column', () => {
  const preflightMarker = 'DO ' + String.fromCharCode(36) + 'preflight' + String.fromCharCode(36);
  assert.ok(rollout.indexOf('LOCK TABLE public.orders') >= 0);
  assert.ok(rollout.indexOf('LOCK TABLE public.orders') < rollout.indexOf(preflightMarker));
  assert.match(rollout, /filled_amount \+ remaining_amount <> amount/);
  assert.match(rollout, /consumed_amount \+ released_amount > reserved_amount/);
  for (const [table, column, type] of [
    ['orders','amount','numeric(34,18)'], ['orders','price','numeric(34,18)'],
    ['orders','filled_amount','numeric(34,18)'], ['orders','remaining_amount','numeric(34,18)'],
    ['trades','amount','numeric(34,18)'], ['trades','price','numeric(34,18)'],
    ['asset_balances','balance','numeric(38,18)'],
    ['order_reservations','reserved_amount','numeric(38,18)'],
    ['order_reservations','released_amount','numeric(38,18)'],
    ['order_reservations','consumed_amount','numeric(38,18)'],
    ['conditional_orders','amount','numeric(34,18)'],
    ['conditional_orders','trigger_price','numeric(34,18)'],
    ['conditional_orders','limit_price','numeric(34,18)'],
    ['conditional_orders','executed_price','numeric(34,18)'],
    ['wallets','balance_usdt','numeric(24,8)'],
    ['transactions','amount','numeric(24,8)']
  ]) {
    assert.ok(rollout.includes("('" + table + "','" + column + "','" + type + "')"),
      'missing postflight check for ' + table + '.' + column);
  }
});

test('Limit worker preserves concurrency and account safeguards', () => {
  assert.match(worker, /pg_try_advisory_xact_lock\(739201126\)/);
  assert.match(worker, /FOR UPDATE SKIP LOCKED/);
  assert.match(worker, /FOR UPDATE/);
  assert.match(worker, /p\.is_active IS TRUE/);
  assert.match(worker, /v_order\.amount \* 0\.25/);
  assert.match(worker, /v_order\.filled_amount IS NULL/);
  assert.match(worker, /v_order\.filled_amount > v_order\.amount/);
  assert.match(worker, /round\(v_order\.amount \* 0\.25, 18\)/);
  assert.match(worker, /LEAST\(v_remaining, 0\.000000000000000001::numeric\)/);
  assert.match(worker, /round\(v_qty \* v_market_price, 8\)/);
  assert.match(worker, /round\(v_fee_rate \* v_gross, 8\)|round\(v_gross \* v_fee_rate, 8\)/);
  assert.match(worker, /v_gross <= 0/);
  assert.match(worker, /round\(\(v_remaining - v_qty\) \* v_market_price, 8\) <= 0/);
  assert.match(worker, /round\(v_new_remaining \* v_order\.price, 8\)[\s\S]*0\.0000001::numeric/);
});

test('entrypoint candidates enforce exact scale and quote-ledger rounding', () => {
  for (const name of ['execute_demo_trade', 'place_limit_order', 'place_stop_limit_order', 'place_conditional_exit_order']) {
    assert.match(entrypoints, new RegExp('CREATE OR REPLACE FUNCTION public\\.' + name));
  }
  assert.match(entrypoints, /pg_catalog\.scale\(p_amount\) > 18/);
  assert.match(entrypoints, /pg_catalog\.scale\(p_limit_price\) > 18/);
  assert.match(entrypoints, /pg_catalog\.scale\(p_stop_price\) > 18/);
  assert.match(entrypoints, /pg_catalog\.scale\(p_trigger_price\) > 18/);
  assert.match(entrypoints, /pg_catalog\.scale\(v_price\) > 18/);
  assert.match(entrypoints, /v_price >= 10000000000000000::numeric/);
  assert.match(entrypoints, /round\(p_amount \* p_limit_price, 8\)[\s\S]*0\.0000001::numeric/);
  assert.match(entrypoints, /Trade notional rounds to zero USDT/);
  assert.match(entrypoints, /round\(p_amount \* p_limit_price, 8\) <= 0/);
  assert.match(entrypoints, /Limit order notional rounds to zero USDT/);
  assert.match(entrypoints, /Stop-Limit order notional rounds to zero USDT/);
  assert.match(entrypoints, /Conditional exit notional rounds to zero USDT/);
  assert.match(entrypoints, /Sell order settlement exceeds numeric\\(24,8\\) USDT capacity/);
  assert.match(entrypoints, /Stop-Limit sell settlement exceeds numeric\\(24,8\\) USDT capacity/);
  assert.match(entrypoints, /Conditional exit settlement exceeds numeric\\(24,8\\) USDT capacity/);
  assert.match(rollout, /Sell order settlement exceeds numeric\\(24,8\\) USDT capacity/);
  assert.match(rollout, /Stop-Limit sell settlement exceeds numeric\\(24,8\\) USDT capacity/);
  assert.match(rollout, /Conditional exit settlement exceeds numeric\\(24,8\\) USDT capacity/);
});

test('schema candidate widens base precision but retains 8-place quote ledgers', () => {
  assert.match(widening, /orders[\s\S]*numeric\(34,18\)/);
  assert.match(widening, /trades[\s\S]*numeric\(34,18\)/);
  assert.match(widening, /asset_balances[\s\S]*numeric\(38,18\)/);
  assert.match(widening, /order_reservations[\s\S]*numeric\(38,18\)/);
  assert.match(widening, /conditional_orders[\s\S]*numeric\(34,18\)/);
  assert.doesNotMatch(widening, /ALTER TABLE public\.wallets/);
  assert.doesNotMatch(widening, /ALTER TABLE public\.transactions/);
  assert.match(widening, /SET LOCAL lock_timeout/);
  assert.match(widening, /DO \$preflight\$/);
  assert.match(widening, /LOCK TABLE public\.orders[\s\S]*DO \$preflight\$/);
});
