'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const setup = fs.readFileSync(
  path.join(__dirname, '..', 'supabase/tests/exact_decimal_limit_worker_setup.sql'),
  'utf8'
);
const integration = fs.readFileSync(
  path.join(__dirname, '..', 'supabase/tests/exact_decimal_limit_worker_integration.sql'),
  'utf8'
);
const raceSetup = fs.readFileSync(
  path.join(__dirname, '..', 'supabase/tests/exact_decimal_cancel_race_setup.sql'),
  'utf8'
);

test('exact-decimal Limit worker fixture mirrors Production active-account trigger semantics', () => {
  assert.ok(setup.includes('CREATE FUNCTION private.guard_active_account_writes()'));
  assert.ok(setup.includes('SECURITY DEFINER'));
  assert.ok(setup.includes("SET search_path TO ''"));
  assert.ok(setup.includes('FROM public.profiles p'));
  assert.ok(setup.includes('FOR SHARE'));
  assert.ok(setup.includes('COALESCE(v_active, false) IS NOT TRUE'));
  for (const table of ['orders', 'trades', 'transactions']) {
    assert.ok(setup.includes('CREATE TRIGGER guard_active_account_' + table));
    assert.ok(setup.includes('BEFORE INSERT ON public.' + table));
  }
});

test('exact-decimal Limit worker SQL integration proves inactive ledger inserts are rejected', () => {
  assert.ok(integration.includes('90000000-0000-0000-0000-000000000009'));
  assert.ok(integration.includes('inactive-account trigger regression'));
  assert.ok(integration.includes('Account is inactive; reactivate the account before trading'));
  assert.ok(integration.includes('Production active-account trigger accepted an inactive transaction'));
});

test('Limit cancellation race fixture deactivates only after the pending order was created', () => {
  const profileInsert = raceSetup.indexOf('INSERT INTO public.profiles');
  const orderInsert = raceSetup.indexOf('INSERT INTO public.orders');
  const deactivate = raceSetup.indexOf('UPDATE public.profiles');
  assert.ok(profileInsert >= 0 && orderInsert > profileInsert && deactivate > orderInsert);
  assert.ok(raceSetup.includes("('72000000-0000-0000-0000-000000000002',true)"));
  assert.ok(raceSetup.includes("WHERE id='72000000-0000-0000-0000-000000000002'"));
});

test('Limit worker fixture mirrors Production catalog and the coordinated widened numeric contract', () => {
  for (const fragment of [
    'CREATE SCHEMA auth;',
    'CREATE TABLE auth.users',
    'REFERENCES auth.users(id) ON DELETE CASCADE',
    'orders_amount_accounting_chk',
    'orders_filled_amount_range_chk',
    'orders_limit_price_required_chk',
    'orders_limit_active_created_at_idx',
    'order_reservations_order_user_fk',
    'order_reservations_accounting_check',
    'order_reservations_user_status_idx',
    'asset_balances_user_asset_unique',
    'wallets_nonnegative_balance',
    'trades_order_id_fk',
    'transactions_amount_nonzero',
    'demo_trading_pairs_unique_base',
    'market_prices_price_check',
    'ENABLE ROW LEVEL SECURITY',
    'CREATE POLICY "View own orders"',
    'CREATE POLICY "Users can view own order reservations"',
    'CREATE POLICY "market_prices_anon_public_read"',
    'numeric(34,18)',
    'numeric(38,18)'
  ]) {
    assert.ok(setup.includes(fragment), 'missing Production catalog fixture element: ' + fragment);
  }
  for (const table of ['orders', 'trades', 'transactions']) {
    assert.ok(setup.includes('CREATE TRIGGER guard_active_account_' + table));
  }
});

test('catalog-parity integration seeds referenced auth users and the real market-pair key shape', () => {
  assert.ok(integration.includes('INSERT INTO auth.users'));
  assert.ok(integration.includes('base_coingecko_id'));
  assert.ok(integration.includes('(symbol, price, source, updated_at)'));
});

test('candidate Limit worker owner, security mode, search_path, and EXECUTE ACL are asserted in PostgreSQL integration', () => {
  assert.ok(integration.includes('REVOKE ALL ON FUNCTION public.process_limit_orders() FROM PUBLIC'));
  assert.ok(integration.includes('REVOKE EXECUTE ON FUNCTION public.process_limit_orders() FROM anon, authenticated'));
  assert.ok(integration.includes('GRANT EXECUTE ON FUNCTION public.process_limit_orders() TO service_role'));
  assert.ok(integration.includes('pg_get_userbyid(p.proowner)'));
  assert.ok(integration.includes('has_function_privilege'));
});
