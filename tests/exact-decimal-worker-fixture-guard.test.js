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
