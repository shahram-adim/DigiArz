'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const manifest = JSON.parse(fs.readFileSync('supabase/audit/production_security_definer_manifest_2026-11-25.json', 'utf8'));
const inventory = JSON.parse(fs.readFileSync('supabase/audit/production_rpc_relation_rls_inventory_2026-11-25.json', 'utf8'));
const review = JSON.parse(fs.readFileSync('supabase/audit/production_anon_access_review_2026-11-25.json', 'utf8'));

test('Production SECURITY DEFINER snapshot is complete and internally consistent', () => {
  assert.equal(manifest.source.project_ref, 'gfoaubfilhttnwjykaox');
  assert.equal(manifest.functions.length, 46);
  const identities = new Set();
  for (const fn of manifest.functions) {
    const identity = fn.schema_name + '.' + fn.function_name + '(' + fn.identity_arguments + ')';
    assert.equal(identities.has(identity), false, 'duplicate function: ' + identity);
    identities.add(identity);
    assert.ok(['public', 'private'].includes(fn.schema_name), 'unexpected schema: ' + identity);
    assert.equal(fn.security_definer, true, 'not SECURITY DEFINER: ' + identity);
    assert.equal(fn.owner, 'postgres', 'unexpected owner: ' + identity);
    assert.ok(fn.result_type, 'missing result type: ' + identity);
    assert.match(fn.definition, /^CREATE OR REPLACE FUNCTION /i, 'missing live definition: ' + identity);
    assert.match(fn.definition_md5, /^[a-f0-9]{32}$/i, 'missing definition fingerprint: ' + identity);
    assert.ok(Array.isArray(fn.function_config) && fn.function_config.some(x => /^search_path=/.test(x)), 'missing function search_path: ' + identity);
    assert.ok(typeof fn.raw_acl === 'string' && fn.raw_acl.length > 0, 'missing ACL: ' + identity);
  }
});

test('Production snapshot has an explicit allowlist for anonymous SECURITY DEFINER execution', () => {
  const actual = manifest.functions
    .filter(fn => /(?:^|,)anon=X\//.test(fn.raw_acl))
    .map(fn => fn.schema_name + '.' + fn.function_name)
    .sort();
  assert.deepEqual(actual, [
    'public.get_admin_market_listings',
    'public.get_exchange_discovered_market_assets'
  ]);
  assert.deepEqual(review.anon_executable_security_definer_functions.map(fn => fn.name).sort(), actual);
  for (const fn of review.anon_executable_security_definer_functions) {
    assert.doesNotMatch(fn.returns.join(' ').toLowerCase(), /user_id|email|wallet|balance|order|trade|transaction|reservation/);
    assert.doesNotMatch(fn.tables_read.join(' ').toLowerCase(), /profiles|wallets|asset_balances|orders|trades|transactions|order_reservations/);
  }
});

test('Production SECURITY DEFINER trigger bindings point to captured functions', () => {
  assert.equal(inventory.trigger_bindings.length, 6);
  const names = new Set(manifest.functions.map(fn => fn.schema_name + '.' + fn.function_name));
  for (const trigger of inventory.trigger_bindings) {
    assert.ok(names.has(trigger.function_schema + '.' + trigger.function_name),
      'trigger function missing from manifest: ' + trigger.function_schema + '.' + trigger.function_name);
    assert.match(trigger.trigger_definition, /^CREATE TRIGGER /i);
  }
});

test('anonymous excess grants remain documented as constrained by RLS or security-invoker bases', () => {
  const coinReviews = review.anon_base_table_grants.find(x => x.table === 'public.coin_reviews');
  assert.ok(coinReviews);
  assert.equal(coinReviews.rls_enabled, true);
  assert.deepEqual(coinReviews.anon_policies, ['SELECT']);
  assert.ok(coinReviews.privileges.includes('INSERT'));
  assert.ok(coinReviews.privileges.includes('UPDATE'));
  assert.ok(coinReviews.privileges.includes('DELETE'));

  const conditionalOrders = review.anon_base_table_grants.find(x => x.table === 'public.conditional_orders');
  assert.ok(conditionalOrders);
  assert.equal(conditionalOrders.rls_enabled, true);
  assert.deepEqual(conditionalOrders.anon_policies, []);

  assert.equal(review.anon_view_grants.length, 2);
  for (const view of review.anon_view_grants) {
    assert.equal(view.security_invoker, true);
    assert.ok(view.privileges.includes('SELECT'));
    assert.ok(view.privileges.includes('INSERT'));
    assert.ok(view.privileges.includes('UPDATE'));
    assert.ok(view.privileges.includes('DELETE'));
  }
  assert.equal(review.safety.production_mutations, 'none');
  assert.equal(review.safety.grants_changed, false);
  assert.equal(review.safety.policies_changed, false);
});

test('Production admin RPC definitions contain an explicit super-administrator guard', () => {
  const adminFunctions = manifest.functions.filter(fn => fn.function_name.startsWith('admin_'));
  assert.equal(adminFunctions.length, 10);
  for (const fn of adminFunctions) {
    assert.match(
      fn.definition,
      /private\.is_(?:current_user_)?super_admin\s*\(/i,
      'missing explicit super-admin guard: ' + fn.schema_name + '.' + fn.function_name
    );
    assert.doesNotMatch(fn.raw_acl, /(?:^|,)anon=X\//, 'admin RPC is executable by anon: ' + fn.function_name);
  }
});
