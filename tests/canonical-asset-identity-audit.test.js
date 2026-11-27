'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const sql = fs.readFileSync('supabase/audit/canonical_asset_identity_schema_fingerprint.sql', 'utf8');

function stripCommentsAndStringLiterals(source) {
  return source
    .replace(/--[^\\n]*/g, '')
    .replace(/\\/\\*[\\s\\S]*?\\*\\//g, '')
    .replace(/'(?:''|[^'])*'/g, "''");
}

test('canonical asset identity fingerprint is a single read-only catalog query', () => {
  const executable = stripCommentsAndStringLiterals(sql);
  assert.match(executable, /^\\s*WITH\\b/i);
  assert.match(executable, /\\bSELECT\\b/i);
  assert.doesNotMatch(
    executable,
    /\\b(?:INSERT|UPDATE|DELETE|MERGE|CREATE|ALTER|DROP|TRUNCATE|GRANT|REVOKE|CALL|DO|COPY)\\b/i
  );
  assert.doesNotMatch(
    executable,
    /\\b(?:FROM|JOIN)\\s+public\\.(?:crypto_assets|admin_market_listings|exchange_asset_observations|demo_trading_pairs|market_prices|orders|trades|conditional_orders|order_reservations|asset_balances|wallets|transactions)\\b/i
  );
  assert.equal((executable.match(/;/g) || []).length, 1);
});

test('canonical fingerprint covers catalog and every financial identity table', () => {
  for (const table of [
    'crypto_assets','admin_market_listings','exchange_asset_observations',
    'demo_trading_pairs','market_prices','orders','trades','conditional_orders',
    'order_reservations','asset_balances','wallets','transactions'
  ]) {
    assert.ok(sql.includes("'" + table + "'"), 'missing table: ' + table);
  }
});

test('canonical fingerprint captures all identity writers and trading call-chain functions', () => {
  for (const fn of [
    'refresh_crypto_assets','refresh_market_prices','admin_enable_market_pair',
    'auto_list_verified_exchange_asset','execute_demo_trade','place_limit_order',
    'process_limit_orders','place_conditional_exit_order','cancel_conditional_exit_order',
    'process_conditional_orders','place_stop_limit_order','cancel_stop_limit_order',
    'process_stop_limit_orders','deactivate_my_account'
  ]) {
    assert.ok(sql.includes("'" + fn + "'"), 'missing function: ' + fn);
  }
});

test('canonical fingerprint captures indexes, constraints, RLS, ACLs, triggers and cron', () => {
  for (const token of [
    'pg_get_constraintdef','pg_get_functiondef','pg_get_triggerdef','pg_indexes',
    'pg_policies','information_schema.role_table_grants','has_function_privilege',
    'cron.job','relrowsecurity','relforcerowsecurity'
  ]) {
    assert.ok(sql.includes(token), 'missing schema contract: ' + token);
  }
});
