'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const sql = fs.readFileSync('supabase/audit/stop_limit_schema_fingerprint.sql', 'utf8');

function stripCommentsAndStringLiterals(source) {
  return source
    .replace(/--[^\n]*/g, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/'(?:''|[^'])*'/g, "''");
}

test('Stop-Limit production fingerprint is a single read-only catalog query', () => {
  const executable = stripCommentsAndStringLiterals(sql);
  assert.match(executable, /^\s*WITH\b/i);
  assert.match(executable, /\bSELECT\b/i);
  assert.doesNotMatch(
    executable,
    /\b(?:INSERT|UPDATE|DELETE|MERGE|CREATE|ALTER|DROP|TRUNCATE|GRANT|REVOKE|CALL|DO|COPY)\b/i
  );
  assert.doesNotMatch(
    executable,
    /\b(?:FROM|JOIN)\s+public\.(?:orders|conditional_orders|order_reservations|trades|asset_balances|wallets|market_prices)\b/i
  );
  assert.equal((executable.match(/;/g) || []).length, 1);
});

test('Stop-Limit fingerprint covers the complete financial object boundary', () => {
  for (const table of [
    'orders',
    'conditional_orders',
    'order_reservations',
    'trades',
    'asset_balances',
    'wallets',
    'market_prices'
  ]) {
    assert.ok(sql.includes("'" + table + "'"), 'missing table: ' + table);
  }

  for (const fn of [
    'place_stop_limit_order',
    'cancel_stop_limit_order',
    'process_stop_limit_orders',
    'place_limit_order',
    'cancel_limit_order',
    'process_limit_orders',
    'place_conditional_exit_order',
    'cancel_conditional_exit_order',
    'process_conditional_orders'
  ]) {
    assert.ok(sql.includes("'" + fn + "'"), 'missing function: ' + fn);
  }
});

test('Stop-Limit fingerprint captures constraints, ACL, RLS, triggers and worker schedule', () => {
  for (const token of [
    'pg_get_constraintdef',
    'pg_get_functiondef',
    'pg_get_triggerdef',
    'pg_indexes',
    'pg_policies',
    'information_schema.role_table_grants',
    'has_function_privilege',
    'cron.job',
    'relrowsecurity',
    'relforcerowsecurity'
  ]) {
    assert.ok(sql.includes(token), 'missing schema contract: ' + token);
  }
});
