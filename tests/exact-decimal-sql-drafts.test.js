'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const read = (name) => fs.readFileSync(name, 'utf8');
const worker = read('supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql');
const entrypoints = read('supabase/drafts/2026-11-15_exact_decimal_entrypoint_candidates.sql');
const widening = read('supabase/drafts/2026-11-15_exact_decimal_type_widening.sql');

test('candidate SQL remains explicitly draft-only and outside migrations', () => {
  for (const sql of [worker, entrypoints, widening]) {
    assert.match(sql, /DRAFT ONLY — DO NOT APPLY TO PRODUCTION/);
  }
  assert.ok(fs.existsSync('supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql'));
  assert.ok(!fs.existsSync('supabase/migrations/20261115_exact_decimal_process_limit_orders.sql'));
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
  assert.match(worker, /round\(v_new_remaining \* v_order\.price \* \(1 \+ v_fee_rate\), 8\)/);
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
  assert.match(entrypoints, /round\(p_amount \* p_limit_price \* \(1 \+ v_fee_rate\), 8\)/);
  assert.match(entrypoints, /Trade notional rounds to zero USDT/);
  assert.match(entrypoints, /round\(p_amount \* p_limit_price, 8\) <= 0/);
  assert.match(entrypoints, /Limit order notional rounds to zero USDT/);
  assert.match(entrypoints, /Stop-Limit order notional rounds to zero USDT/);
  assert.match(entrypoints, /Conditional exit notional rounds to zero USDT/);
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
});
