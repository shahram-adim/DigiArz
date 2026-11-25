'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const manifest = JSON.parse(fs.readFileSync('supabase/audit/production_security_definer_manifest_2026-11-25.json', 'utf8'));
const inventory = JSON.parse(fs.readFileSync('supabase/audit/production_rpc_relation_rls_inventory_2026-11-25.json', 'utf8'));
const review = JSON.parse(fs.readFileSync('supabase/audit/production_anon_access_review_2026-11-25.json', 'utf8'));
const dependencies = JSON.parse(fs.readFileSync('supabase/audit/production_rpc_relation_dependencies_2026-11-25.json', 'utf8'));
const migrationReconciliation = JSON.parse(fs.readFileSync('supabase/audit/production_migration_source_reconciliation_2026-11-25.json', 'utf8'));
const migrationRecoveryMap = JSON.parse(fs.readFileSync('supabase/audit/production_missing_migration_recovery_map_2026-11-25.json', 'utf8'));
const migrationAuthoritySearch = JSON.parse(fs.readFileSync('supabase/audit/production_migration_authority_search_2026-11-25.json', 'utf8'));

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
    assert.equal(fn.public_access_intent.confirmed_by_migrations, true);
    assert.ok(fn.public_access_intent.migrations.length > 0);
  }
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

test('Production RPC body relation scan resolves to live schema metadata', () => {
  assert.equal(dependencies.scan.functions_scanned, 46);
  assert.equal(dependencies.scan.unique_schema_qualified_relation_candidates, 27);
  assert.equal(dependencies.scan.resolved_relations, 27);
  assert.deepEqual(dependencies.scan.unresolved_candidates, []);
  assert.equal(dependencies.scan.columns_captured, 175);
  const functions = new Set(manifest.functions.map(fn => fn.schema_name + '.' + fn.function_name));
  const relations = new Set();
  for (const relation of dependencies.relations) {
    const key = relation.schema + '.' + relation.relation;
    assert.equal(relations.has(key), false, 'duplicate relation: ' + key);
    relations.add(key);
    assert.ok(['public', 'private', 'auth'].includes(relation.schema));
    assert.ok(Array.isArray(relation.columns) && relation.columns.length > 0, 'missing columns: ' + key);
    assert.ok(Array.isArray(relation.referenced_by) && relation.referenced_by.length > 0, 'missing function references: ' + key);
    assert.equal(typeof relation.rls_enabled, 'boolean');
    for (const caller of relation.referenced_by) {
      assert.ok(functions.has(caller), 'unknown function reference: ' + caller);
    }
  }
});

test('Production migration ledger reconciliation distinguishes missing sources from timestamp drift', () => {
  assert.deepEqual(migrationReconciliation.counts, {
    production_ledger: 55,
    local_sql_files: 40,
    matched_by_normalized_name: 38,
    missing_source_files: 17,
    matched_timestamp_mismatches: 20,
    exact_timestamp_matches: 18,
    local_files_without_ledger_name: 2
  });
  assert.equal(migrationReconciliation.missing_sources.length, 17);
  assert.equal(migrationReconciliation.matched.length, 38);
  assert.equal(migrationReconciliation.matched.filter(x => x.timestamp_match).length, 18);
  assert.equal(migrationReconciliation.matched.filter(x => !x.timestamp_match).length, 20);
  assert.equal(migrationReconciliation.local_files_without_ledger_name.length, 2);
  assert.equal(migrationReconciliation.safety.includes('Do not run db push'), true);
});

test('Missing Production migration sources have explicit evidence maps and remain non-executable', () => {
  const mapped = migrationRecoveryMap.groups.flatMap(group => group.migrations);
  assert.equal(mapped.length, 17);
  assert.equal(new Set(mapped).size, 17);
  assert.equal(migrationRecoveryMap.groups.length, 4);
  assert.ok(migrationRecoveryMap.global_gaps.some(x => x.includes('must not be synthesized')));
  assert.ok(migrationRecoveryMap.global_gaps.some(x => x.includes('No Production migration')));
  for (const group of migrationRecoveryMap.groups) {
    assert.ok(group.area.length > 0);
    assert.ok(group.evidence_files.length > 0);
    assert.ok(group.gaps.length > 0);
  }
});

test('Migration source recovery report records bounded search evidence and limitations', () => {
  assert.equal(migrationAuthoritySearch.migration_reconciliation_document.then_missing_sources, 14);
  assert.equal(migrationAuthoritySearch.migration_reconciliation_document.current_missing_sources, 17);
  assert.equal(migrationAuthoritySearch.migration_reconciliation_document.later_additions.length, 3);
  assert.equal(migrationAuthoritySearch.git_history.returned_commits, 44);
  assert.equal(migrationAuthoritySearch.pull_request_search.inspected_pr_count, 28);
  assert.equal(migrationAuthoritySearch.branch_search.unique_topic_branches_examined, 20);
  assert.equal(migrationAuthoritySearch.actions_artifacts.runs_checked.length, 2);
  assert.ok(migrationAuthoritySearch.actions_artifacts.runs_checked.every(x => x.artifact_count === 0));
  assert.ok(migrationAuthoritySearch.next_authoritative_sources_to_check.length >= 3);
  assert.ok(migrationAuthoritySearch.safety.includes('No source was reconstructed or applied'));
});


test('All 17 missing migrations have review-only dossiers and executable replay stays blocked', () => {
  const dossierPath = 'supabase/audit/production_missing_migration_dossiers_2026-11-25.md';
  assert.equal(fs.existsSync(dossierPath), true);
  const dossier = fs.readFileSync(dossierPath, 'utf8');
  const ids = [...dossier.matchAll(/^#### (\d{14}) — /gm)].map(match => match[1]);
  assert.equal(ids.length, 17);
  assert.equal(new Set(ids).size, 17);
  assert.match(dossier, /وضعیت: فقط مستندات بازبینی؛ غیرقابل اجرا/);
  assert.match(dossier, /تعداد SQL اصلی بازیابی‌شده در این گام: صفر/);
  assert.match(dossier, /تعداد SQL اجرایی ساخته‌شده: صفر/);
  assert.match(dossier, /هر پرونده فقط وقتی می‌تواند از «مفقود» به «بازیابی‌شده» تغییر کند/);
  assert.match(dossier, /هیچ Migration یا SQL بازسازی‌شده اجرا نشود/);
  assert.match(dossier, /هیچ scheduleی از روی حدس تغییر یا بازگردانی نشود/);
});


test('missing-migration dossiers cross-reference only captured live fingerprints and object bindings', () => {
  const dossier = fs.readFileSync('supabase/audit/production_missing_migration_dossiers_2026-11-25.md', 'utf8');
  assert.match(dossier, /تطبیق اشیای زنده و fingerprintها/);
  assert.match(dossier, /ارتباط مشاهده‌شده در وضعیت فعلی/);
  assert.match(dossier, /اثبات نمی‌کند کدام Migration تاریخی/);
  assert.match(dossier, /no direct live attribution/);
  assert.match(dossier, /command text\/fingerprint در این crosswalk موجود نیست/);
  const fingerprints = [...dossier.matchAll(/MD5 `[a-f0-9]{32}`/g)];
  assert.equal(fingerprints.length, 12);
  assert.match(dossier, /20261113153808/);
  assert.match(dossier, /20261115105956/);
  assert.match(dossier, /20261116201639/);
  assert.match(dossier, /20261121050216/);
  assert.match(dossier, /هیچ grant\/revoke، policy، function، trigger، cron، queue/);
});


test('migration dossier includes all captured cron command and trigger fingerprints', () => {
  const dossier = fs.readFileSync('supabase/audit/production_missing_migration_dossiers_2026-11-25.md', 'utf8');
  const cronFingerprints = [...dossier.matchAll(/\| \d+ \| `digiarz-[^`]+` \| `[^`]+` \| true \| \d+ \| `[a-f0-9]{32}` \|/g)];
  assert.equal(cronFingerprints.length, 4);
  const triggerFingerprints = [...dossier.matchAll(/\| `(?:trg_auto_list_verified_exchange_asset|admin_market_listing_unique_ticker|guard_active_account_orders|guard_active_account_trades|guard_active_account_transactions|on_auth_user_created)` \| `[^`]+` \| `[^`]+` \| `[a-f0-9]{32}` \|/g)];
  assert.equal(triggerFingerprints.length, 6);
  const invokedRoutineRows = [...dossier.matchAll(/\\| \\d+ \\| `(?:public|private)\\.[^`]+\\(\\)` \\| `[a-f0-9]{32}` \| `[a-f0-9]{32}` \|/g)];
  assert.equal(invokedRoutineRows.length, 4);
  assert.ok(dossier.includes('public.recover_stale_crypto_assets_sync()'));
  assert.ok(dossier.includes('public.request_iran_exchange_asset_sync()'));
  assert.ok(dossier.includes('public.process_iran_exchange_asset_sync()'));
  assert.ok(dossier.includes('private.auto_activate_verified_exchange_pairs()'));
  for (const trigger of ['trg_auto_list_verified_exchange_asset', 'admin_market_listing_unique_ticker', 'guard_active_account_orders', 'guard_active_account_trades', 'guard_active_account_transactions', 'on_auth_user_created']) {
    assert.ok(dossier.includes(trigger));
  }
  assert.match(dossier, /هیچ jobی متوقف، کند، زمان‌بندی مجدد یا اجرا نشد/);
});


test('live cron-invoked routine fingerprints match the captured Production manifest', () => {
  const dossier = fs.readFileSync('supabase/audit/production_missing_migration_dossiers_2026-11-25.md', 'utf8');
  for (const fingerprint of [
    '9ab6efcdb72cce454244f81aecc1da86',
    '22e4150dd0ae30a2e3abf81887c52897',
    '889c3728e54154a799e55ed8b9bc2edb',
    'fd177baeee1a5bdd927458413f69bfb6'
  ]) {
    assert.ok(dossier.includes(fingerprint));
  }
  assert.match(dossier, /تطبیق fingerprint فعلی Production با manifest برای این چهار routine برابر است \(۴\/۴\)/);
});
