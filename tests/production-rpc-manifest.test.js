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


test('group four cron attribution supersedes the earlier map omission without claiming migration provenance', () => {
  const dossier = fs.readFileSync('supabase/audit/production_missing_migration_dossiers_2026-11-25.md', 'utf8');
  assert.match(dossier, /job 11 تابع `public\.recover_stale_crypto_assets_sync\(\)` را فراخوانی می‌کند/);
  assert.match(dossier, /این انتساب، اجرای فعلی job را ثابت می‌کند نه اینکه کدام Migration آن را ایجاد\/تغییر داده باشد/);
});


test('anonymous base-table access is limited to intended public market metadata reads', () => {
  const byTable = new Map(review.anon_base_table_grants.map(item => [item.table, item]));
  const expectedPublicMetadata = [
    'public.crypto_assets',
    'public.demo_trading_pairs',
    'public.market_fx_rates',
    'public.market_prices'
  ];
  for (const table of expectedPublicMetadata) {
    const entry = byTable.get(table);
    assert.ok(entry, 'missing public market metadata grant: ' + table);
    assert.deepEqual(entry.privileges, ['SELECT'], 'unexpected anon privilege: ' + table);
    assert.deepEqual(entry.anon_policies, ['SELECT'], 'unexpected anon policy: ' + table);
  }

  for (const table of ['public.market_toman_prices', 'public.market_toman_price_history']) {
    const entry = byTable.get(table);
    assert.ok(entry, 'missing Toman table access snapshot: ' + table);
    assert.deepEqual(entry.privileges, [], 'unexpected anon base-table grant: ' + table);
    assert.deepEqual(entry.anon_policies, [], 'unexpected anon row policy: ' + table);
  }

  assert.deepEqual(
    [...byTable.keys()].sort(),
    [
      'public.coin_reviews',
      'public.conditional_orders',
      'public.crypto_assets',
      'public.demo_trading_pairs',
      'public.market_fx_rates',
      'public.market_prices',
      'public.market_toman_price_history',
      'public.market_toman_prices'
    ]
  );
});

test('security-invoker market views cannot exceed captured underlying anon base-table access', () => {
  const views = new Map(review.anon_view_grants.map(item => [item.view, item]));
  const marketView = views.get('public.market_prices_with_toman');
  assert.ok(marketView);
  assert.equal(marketView.security_invoker, true);
  assert.deepEqual(marketView.underlying_anon_privileges, {
    'public.market_prices': ['SELECT'],
    'public.market_fx_rates': ['SELECT']
  });

  const tomanView = views.get('public.market_toman_performance');
  assert.ok(tomanView);
  assert.equal(tomanView.security_invoker, true);
  assert.deepEqual(tomanView.underlying_anon_privileges, {
    'public.market_toman_prices': [],
    'public.market_toman_price_history': []
  });

  assert.deepEqual([...views.keys()].sort(), [
    'public.market_prices_with_toman',
    'public.market_toman_performance'
  ]);
});


test('Production RPC role ACL matrix covers all 46 signatures and preserves the captured role expectations', () => {
  const matrix = JSON.parse(fs.readFileSync('supabase/audit/production_rpc_role_matrix_2026-11-25.json', 'utf8'));
  assert.equal(matrix.function_count, 46);
  assert.equal(matrix.functions.length, 46);
  assert.deepEqual(matrix.roles, ['anon', 'authenticated', 'service_role', 'postgres']);
  const identities = new Set(matrix.functions.map(fn => fn.identity));
  assert.equal(identities.size, 46, 'role matrix must contain every function identity exactly once');
  for (const fn of matrix.functions) {
    assert.equal(fn.owner, 'postgres', fn.identity);
    assert.match(fn.definition_md5, /^[a-f0-9]{32}$/i, fn.identity);
    assert.equal(fn.expected_execute.postgres, true, fn.identity);
    const entries = fn.acl_snapshot.replace(/^\\{|\\}$/g, '').split(',').filter(Boolean);
    const acl = Object.fromEntries(entries.map(entry => {
      const index = entry.indexOf('=');
      const grantee = entry.slice(0, index) || 'PUBLIC';
      const privileges = entry.slice(index + 1).split('/')[0];
      return [grantee, privileges.includes('X')];
    }));
    for (const role of ['anon', 'authenticated', 'service_role']) {
      assert.equal(fn.expected_execute[role], !!acl[role], fn.identity + ' ' + role + ' ACL mismatch');
    }
    assert.equal(fn.public_execute, !!acl.PUBLIC, fn.identity + ' PUBLIC ACL mismatch');
  }
  assert.deepEqual(
    matrix.functions.filter(fn => fn.expected_execute.anon).map(fn => fn.identity).sort(),
    ['public.get_admin_market_listings()', 'public.get_exchange_discovered_market_assets()']
  );
  assert.ok(matrix.limitations.some(x => /does not execute functions/.test(x)));
});


test('Production role matrix exactly reconciles every captured function ACL and definition fingerprint', () => {
  const matrix = JSON.parse(fs.readFileSync('supabase/audit/production_rpc_role_matrix_2026-11-25.json', 'utf8'));
  const liveManifest = JSON.parse(fs.readFileSync('supabase/audit/production_security_definer_manifest_2026-11-25.json', 'utf8'));
  assert.equal(matrix.function_count, 46);
  assert.equal(liveManifest.functions.length, 46);

  const parseAcl = raw => {
    assert.ok(raw.startsWith('{') && raw.endsWith('}'), 'malformed ACL array: ' + raw);
    const entries = raw.slice(1, -1).split(',').filter(Boolean);
    const privileges = new Map();
    for (const entry of entries) {
      const separator = entry.indexOf('=');
      assert.notEqual(separator, -1, 'malformed ACL entry: ' + entry);
      const grantee = entry.slice(0, separator) || 'PUBLIC';
      const privilegeText = entry.slice(separator + 1).split('/')[0];
      privileges.set(grantee, privilegeText.includes('X'));
    }
    return privileges;
  };

  const byIdentity = new Map(liveManifest.functions.map(fn => [
    fn.schema_name + '.' + fn.function_name + '(' + fn.identity_arguments + ')', fn
  ]));
  assert.equal(byIdentity.size, 46, 'manifest identities must be unique');

  for (const row of matrix.functions) {
    const source = byIdentity.get(row.identity);
    assert.ok(source, 'role matrix identity missing from Production manifest: ' + row.identity);
    assert.equal(row.owner, source.owner, row.identity + ' owner drift');
    assert.equal(row.acl_snapshot, source.raw_acl, row.identity + ' raw ACL drift');
    assert.equal(row.definition_md5, source.definition_md5, row.identity + ' definition fingerprint drift');

    const acl = parseAcl(source.raw_acl);
    for (const role of ['anon', 'authenticated', 'service_role']) {
      assert.equal(row.expected_execute[role], acl.get(role) === true, row.identity + ' ' + role + ' direct ACL mismatch');
    }
    assert.equal(row.public_execute, acl.get('PUBLIC') === true, row.identity + ' PUBLIC ACL mismatch');
    assert.equal(row.expected_execute.postgres, true, row.identity + ' postgres owner execution expectation');
  }
});



test('inactive-account guards serialize order, reservation and conditional-order writes', () => {
  const fn = (schema, name) => {
    const found = manifest.functions.find(item => item.schema_name === schema && item.function_name === name);
    assert.ok(found, 'missing captured Production function: ' + schema + '.' + name);
    return found.definition;
  };

  const guard = fn('private', 'guard_active_account_writes');
  assert.match(guard, /from public\.profiles p[\s\S]*where p\.id = new\.user_id[\s\S]*for share;/i);
  assert.match(guard, /coalesce\(v_active, false\) is not true[\s\S]*raise exception/i);

  const guardedInsertTriggers = inventory.trigger_bindings.filter(trigger =>
    trigger.function_schema === 'private' &&
    trigger.function_name === 'guard_active_account_writes' &&
    /^CREATE TRIGGER guard_active_account_/.test(trigger.trigger_definition)
  );
  assert.deepEqual(
    guardedInsertTriggers.map(trigger => trigger.relation_schema + '.' + trigger.relation_name).sort(),
    ['public.orders', 'public.trades', 'public.transactions']
  );
  for (const relation of ['orders', 'trades', 'transactions']) {
    const trigger = guardedInsertTriggers.find(item => item.relation_name === relation);
    assert.match(trigger.trigger_definition, /BEFORE INSERT ON public\./i);
  }

  const placements = [
    ['place_limit_order', 'INSERT INTO public.orders', 'INSERT INTO public.order_reservations'],
    ['place_conditional_exit_order', 'INSERT INTO public.orders', 'INSERT INTO public.order_reservations', 'INSERT INTO public.conditional_orders'],
    ['place_stop_limit_order', 'INSERT INTO public.orders', 'INSERT INTO public.order_reservations', 'INSERT INTO public.conditional_orders']
  ];
  for (const [name, ...writes] of placements) {
    const body = fn('public', name);
    assert.match(body, /current_account_is_active\(\)/i, name + ' must reject inactive accounts before placement');
    let previous = body.indexOf('current_account_is_active()');
    assert.notEqual(previous, -1, name + ' active-account check missing');
    for (const write of writes) {
      const at = body.indexOf(write);
      assert.ok(at > previous, name + ' write order changed: ' + write);
      previous = at;
    }
  }

  for (const [name, downstream] of [
    ['process_conditional_orders', 'execute_demo_trade'],
    ['process_stop_limit_orders', 'place_limit_order']
  ]) {
    const body = fn('public', name);
    assert.match(body, /join public\.profiles p on p\.id=c\.user_id and p\.is_active is true/i, name + ' must filter inactive accounts');
    assert.match(body, /select mp\.price into v_market_price[\s\S]*from public\.market_prices mp[\s\S]*for share;/i,
      name + ' market-price FOR SHARE must not be mistaken for a profile lock');
    assert.match(body, new RegExp('public\\.' + downstream + '\\('), name + ' must call its guarded execution entrypoint');
    const execution = fn('public', downstream);
    assert.match(execution, /current_account_is_active\(\)/i, downstream + ' must recheck account state at execution');
    assert.match(execution, /insert into public\.orders/i, downstream + ' must pass through the guarded order INSERT');
  }

  const limitWorker = fn('public', 'process_limit_orders');
  assert.match(limitWorker, /exists \(select 1 from public\.profiles as p where p\.id = o\.user_id and p\.is_active is true\)/i);
  assert.match(limitWorker, /insert into public\.trades/i, 'Limit worker must pass through the guarded trade INSERT');
  assert.ok(guardedInsertTriggers.some(trigger => trigger.relation_name === 'trades'));

  const deactivate = fn('public', 'deactivate_my_account');
  const deactivateAt = deactivate.indexOf('SET is_active=false');
  assert.notEqual(deactivateAt, -1);
  for (const write of ['UPDATE public.order_reservations', 'UPDATE public.conditional_orders']) {
    assert.ok(deactivate.indexOf(write) > deactivateAt, 'deactivation must mark profile inactive before cleanup: ' + write);
  }

  const relation = name => {
    const found = inventory.relations.find(item => item.schema === 'public' && item.name === name);
    assert.ok(found, 'missing Production relation ACL snapshot: ' + name);
    return found;
  };
  for (const name of ['order_reservations', 'conditional_orders']) {
    const acl = relation(name);
    assert.equal(acl.authenticated_insert, false, name + ' must not allow direct authenticated INSERT');
    assert.equal(acl.authenticated_update, false, name + ' must not allow direct authenticated UPDATE');
    assert.equal(acl.authenticated_delete, false, name + ' must not allow direct authenticated DELETE');
  }

  for (const [name, tables] of [
    ['cancel_limit_order', ['order_reservations']],
    ['cancel_conditional_exit_order', ['order_reservations', 'conditional_orders']],
    ['cancel_stop_limit_order', ['order_reservations', 'conditional_orders']]
  ]) {
    const body = fn('public', name);
    for (const table of tables) {
      assert.match(body, new RegExp('UPDATE\\s+public\\.' + table, 'i'), name + ' must retain cleanup path for ' + table);
      assert.doesNotMatch(body, new RegExp('INSERT\\s+INTO\\s+public\\.' + table, 'i'), name + ' must not create new ' + table + ' rows');
    }
  }
});


test('captured Production order workers preserve active-account, row-lock and reservation safeguards', () => {
  const byName = name => manifest.functions.find(fn => fn.schema_name === 'public' && fn.function_name === name);
  const limit = byName('process_limit_orders');
  const conditional = byName('process_conditional_orders');
  const stopLimit = byName('process_stop_limit_orders');

  assert.equal(limit.definition_md5, '00ab429596fb99392666632967cde9c0');
  assert.equal(conditional.definition_md5, '5cfbf0e2e73474ae64e42643b3feb28a');
  assert.equal(stopLimit.definition_md5, '66357ab4a2247019f22a8b6ab6eac6fe');

  assert.match(limit.definition, /EXISTS\s*\(SELECT 1 FROM public\.profiles AS p WHERE p\.id = o\.user_id AND p\.is_active IS TRUE\)/i);
  assert.match(limit.definition, /FROM public\.orders AS o[\s\S]*?FOR UPDATE SKIP LOCKED/i);
  assert.match(limit.definition, /FROM public\.order_reservations AS r[\s\S]*?FOR UPDATE;/i);
  assert.match(limit.definition, /FROM public\.wallets AS w[\s\S]*?FOR UPDATE;/i);
  assert.match(limit.definition, /INSERT INTO public\.trades/i);
  assert.match(limit.definition, /INSERT INTO public\.transactions/i);

  for (const worker of [conditional, stopLimit]) {
    assert.match(worker.definition, /JOIN public\.profiles p ON p\.id=c\.user_id AND p\.is_active IS TRUE/i);
    assert.match(worker.definition, /FOR UPDATE OF c,o SKIP LOCKED/i);
    assert.match(worker.definition, /FROM public\.order_reservations r[\s\S]*?FOR UPDATE;/i);
    assert.match(worker.definition, /EXCEPTION WHEN OTHERS THEN/i);
    assert.match(worker.definition, /SET released_amount=reserved_amount-consumed_amount/i);
  }
});

test('Stop-Limit Production worker lock scope is explicit for child-order concurrency review', () => {
  const worker = manifest.functions.find(fn => fn.schema_name === 'public' && fn.function_name === 'process_stop_limit_orders');
  const definition = worker.definition;
  assert.match(definition, /JOIN public\.orders child ON child\.id=c\.execution_order_id AND child\.user_id=c\.user_id/i);
  assert.match(definition, /FOR UPDATE OF c,parent SKIP LOCKED/i);
  assert.doesNotMatch(definition, /FOR UPDATE OF c,parent,child/i);
  assert.doesNotMatch(definition, /FOR UPDATE OF c,parent,\s*child/i);
  // This assertion records the captured Production lock scope; it does not
  // declare the unlocked child row safe. A two-session worker/deactivation
  // fixture must decide whether expanding the lock set is necessary.
});


test('Stop-Limit worker race fixture embeds the captured Production body and tests next-cycle convergence', () => {
  const worker = manifest.functions.find(fn => fn.schema_name === 'public' && fn.function_name === 'process_stop_limit_orders');
  const fixture = fs.readFileSync('tests/inactive-account-rpc-race.pg17.sql', 'utf8');
  const fixtureStart = fixture.lastIndexOf('CREATE OR REPLACE FUNCTION public.process_stop_limit_orders()');
  assert.notEqual(fixtureStart, -1, 'captured Stop-Limit worker missing from PostgreSQL fixture');
  assert.ok(fixture.slice(fixtureStart).trim().startsWith(worker.definition.trim()),
    'Stop-Limit worker fixture must preserve the exact captured Production definition');

  const race = fs.readFileSync('tests/stop-limit-child-sync-race.pg17.sh', 'utf8');
  assert.match(race, /PGAPPNAME=digiarz_child_fill_hold/);
  assert.match(race, /wait_for_sleep_query digiarz_child_fill_hold/);
  assert.match(race, /public\.process_stop_limit_orders\(\)/);
  assert.match(race, /expected one-cycle parent lag/);
  assert.match(race, /parent did not converge to child filled state/);
  assert.match(race, /conditional did not converge to child filled state/);
});


test('Limit and Stop-Limit worker-to-worker race fixture uses captured Production worker bodies', () => {
  const fixture = fs.readFileSync('tests/inactive-account-rpc-race.pg17.sql', 'utf8');
  for (const name of ['process_limit_orders', 'process_stop_limit_orders']) {
    const worker = manifest.functions.find(fn => fn.schema_name === 'public' && fn.function_name === name);
    const start = fixture.lastIndexOf('CREATE OR REPLACE FUNCTION public.' + name + '()');
    assert.notEqual(start, -1, 'worker missing from disposable fixture: ' + name);
    assert.ok(fixture.slice(start).trim().startsWith(worker.definition.trim()),
      'fixture must use exact captured Production body: ' + name);
  }

  const race = fs.readFileSync('tests/limit-stop-worker-race.pg17.sh', 'utf8');
  assert.match(race, /PGAPPNAME=digiarz_limit_worker/);
  assert.match(race, /wait_for_lock_wait digiarz_limit_worker/);
  assert.match(race, /process_stop_limit_orders\(\)->>'synced'/);
  assert.match(race, /process_limit_orders\(\)/);
  assert.match(race, /one-cycle stale parent snapshot/);
  assert.match(race, /parent quantities did not converge/);
  assert.match(race, /public\.trades/);
  assert.match(race, /public\.transactions/);
});


test('Stop-Limit cancellation serializes with child fills and preserves partial reservation accounting', () => {
  const stopCancel = manifest.functions.find(fn => fn.schema_name === 'public' && fn.function_name === 'cancel_stop_limit_order');
  const limitCancel = manifest.functions.find(fn => fn.schema_name === 'public' && fn.function_name === 'cancel_limit_order');
  const fixture = fs.readFileSync('tests/inactive-account-rpc-race.pg17.sql', 'utf8');
  for (const fn of [stopCancel, limitCancel]) {
    const start = fixture.lastIndexOf('CREATE OR REPLACE FUNCTION public.' + fn.function_name + '(');
    assert.notEqual(start, -1, 'captured cancellation RPC missing: ' + fn.function_name);
    assert.ok(fixture.slice(start).trim().startsWith(fn.definition.trim()),
      'cancellation fixture must use exact captured Production body: ' + fn.function_name);
  }

  assert.match(stopCancel.definition, /FROM public\.conditional_orders[\s\S]*?FOR UPDATE;/i);
  assert.match(stopCancel.definition, /FROM public\.orders[\s\S]*?FOR UPDATE;/i);
  assert.match(stopCancel.definition, /FROM public\.orders[\s\S]*?v_cond\.execution_order_id[\s\S]*?FOR UPDATE;/i);
  assert.match(stopCancel.definition, /public\.cancel_limit_order\(v_child\.id\)/i);

  const race = fs.readFileSync('tests/stop-limit-cancel-limit-race.pg17.sh', 'utf8');
  assert.match(race, /PGAPPNAME=digiarz_limit_worker_cancel_race/);
  assert.match(race, /PGAPPNAME=digiarz_stop_cancel/);
  assert.match(race, /wait_for_lock_wait digiarz_stop_cancel/);
  assert.match(race, /child partial fill accounting was not preserved/);
  assert.match(race, /reservation consumption\/release accounting was not preserved/);
});
