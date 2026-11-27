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

test('exact-decimal Limit worker fixture mirrors Production active-account trigger semantics', () => {
  assert.match(setup, /CREATE FUNCTION private\\.guard_active_account_writes\\(\\)[\\s\\S]*?SECURITY DEFINER[\\s\\S]*?SET search_path TO ''/i);
  assert.match(setup, /FROM public\\.profiles p[\\s\\S]*?FOR SHARE/i);
  assert.match(setup, /COALESCE\\(v_active, false\\) IS NOT TRUE/i);
  for (const table of ['orders', 'trades', 'transactions']) {
    assert.match(
      setup,
      new RegExp('CREATE TRIGGER guard_active_account_' + table + '[\\\\s\\\\S]*?BEFORE INSERT ON public\\\\.' + table, 'i')
    );
  }
});

test('exact-decimal Limit worker SQL integration proves inactive ledger inserts are rejected', () => {
  assert.match(integration, /90000000-0000-0000-0000-000000000009/);
  assert.match(integration, /inactive-account trigger regression/);
  assert.match(integration, /Account is inactive; reactivate the account before trading/);
  assert.match(integration, /Production active-account trigger accepted an inactive transaction/);
});
