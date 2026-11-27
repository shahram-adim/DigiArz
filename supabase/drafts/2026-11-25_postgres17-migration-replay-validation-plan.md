# DigiArz — PostgreSQL 17 disposable migration-replay validation plan

**Status:** REVIEW PLAN ONLY — NOT AN EXECUTION RUNBOOK  
**Date:** 2026-11-25  
**Related branch / PR:** feature/persian-asset-name-candidates-2026 / PR #62  
**Evidence branch / PR:** audit/production-rpc-manifest-2026-11-25 / PR #63  
**Production project:** gfoaubfilhttnwjykaox — read-only evidence only

## 1. Goal and boundary

Validate whether the 17 byte-exact recovered historical SQL bodies can be represented in a clean, disposable PostgreSQL 17 fixture in a safe, deterministic order, and whether their resulting catalog metadata matches the reviewed Production snapshot.

This plan does NOT authorize:
- running the 17 SQL files as a batch or replaying them into Production, Recovery-Test, or any persistent Supabase project;
- supabase db push, migration ledger edits, canonical migration renames, DDL, GRANT/REVOKE, RLS/policy changes, function deployment, or schema changes outside a one-job ephemeral CI container;
- external HTTP calls, payments, notifications, pg_net queue writes/snapshots, live data ingestion, or any worker invocation against an external endpoint;
- creating/upgrading a Supabase project/branch, paid runner, extension, or other cost-bearing resource;
- invoking, stopping, slowing, rescheduling, or altering any Cron job, especially order-processing jobs;
- using real Auth users, JWTs, API keys, service-role secrets, wallet balances, orders, trades, reservations, or financial data.

The only acceptable future execution target is a PostgreSQL 17 service container created and destroyed inside a single GitHub Actions job, with synthetic roles, synthetic UUIDs and synthetic rows. It must not accept a configurable remote database URL.

## 2. Current verified baseline

- Production ledger: 55 rows through 20261121050216.
- Local SQL files: 40; normalized-name matches: 38; timestamp drift: 20; exact timestamp matches: 18; missing canonical source files: 17; local-only files: 2.
- Seventeen recovered SQL bodies in PR #62 have already been independently verified byte-for-byte against their matching Production ledger text[] bodies after removing only the nine-line provenance header.
- Among 20 timestamp-mismatched local files: 16 are byte-exact; 3 differ only by a single leading/trailing newline; one is a substantive Kifpool processor divergence. That divergent local file must not be treated as the Production historical body.
- Two local-only KuCoin/Gate.io refresh migrations are not in the Production ledger and remain excluded; their older function definitions may supersede the current 515-ID cap.
- Latest verified PR #62 workflow run 45665750807 passed the unit/type-check job and PostgreSQL 17 RPC smoke job; the remote database integration job was intentionally skipped.
- The current harness is not full parity: after installing the exchange-discovery body it contains 12 source-backed/reviewed function bodies and 34 inert metadata stubs for the 46-signature inventory, as reported by the latest CI step. The synthetic auth.uid() shim is not Supabase Auth/JWT verification.
- The latest verified workflow uses an ephemeral postgres:17 service container, no Production URL/secrets, and keeps rpc-security-integration skipped. The job validates the 46-signature ACL fixture and targeted source-backed behavior; it is not yet a full migration replay harness or complete two-user RLS matrix.

## 3. Classification of recovered SQL bodies

Do not execute any recovered file unmodified as a single batch. Each file must first be split into reviewed units and assigned one or more categories below. The classification is about test treatment, not authorization to run.

| Historical version | Main test unit | Required treatment in an ephemeral harness |
|---|---|---|
| 20261113153808 | Wallet defaults, fees, review/report tables and function replacements | Build only synthetic schema prerequisites; exclude user onboarding, wallet/default inserts and any financial-row effects from replay. Test function definitions and table/policy metadata separately. |
| 20261113154323 | Confirmed super-admin assignment | NEVER replay the identity seed. Use a fixed synthetic UUID in the fixture and assert the guard logic only. |
| 20261113154736 | Admin wallet management functions and audit table | Install exact function bodies only after synthetic private/admin and wallet schema exists. Test only synthetic rows in rollback-scoped transactions; no real balance or transaction data. |
| 20261113154750 | Admin role probe | Install exact function body after synthetic private role helpers exist; test anon, ordinary user and synthetic admin. |
| 20261113154844 | Toman admin-credit UI/function changes | Verify function signature/definition and unit conversion against synthetic values. No wallet update is permitted outside a rollback transaction. |
| 20261113154926 | Move admin privilege logic to private schema | Verify exact schema placement, wrappers, owners, search_path and ACL metadata. No grant change against any persistent database. |
| 20261115101709 | Exchange observation table, FK, indexes, RLS | Safe candidate for schema-only fixture replay after a synthetic crypto_assets prerequisite; use empty fixture tables. |
| 20261115102729 | Iranian exchange request/process functions and Cron | Do not execute the request function or Cron DDL. Install only reviewed function definitions against local no-op net stubs, or test a source-transformed pure processor unit. Assert expected schedule metadata as data, never create a job. |
| 20261115102927 | JSON response cast fix | Test exact processor definition against synthetic response fixtures; no real net response rows or network activity. |
| 20261115103227 | Auto-list verified observations and trigger | Install trigger/function definitions only against synthetic observation/asset/listing tables. Test synthetic inserts inside a transaction and roll back. |
| 20261115103507 | Bit24 request/process functions and Cron | Same HTTP/Cron prohibition as 15102729; test only a pure parser/processor against synthetic payloads. |
| 20261115105721 | Admin exchange-sync monitoring and manual request RPCs | Install read-only reporting body with synthetic data; do not call manual request RPC if it can enqueue HTTP. Test its authorization branch using a stubbed no-op worker only. |
| 20261115105956 | Restrict worker EXECUTE | Treat grants/revokes as catalog assertions, not as live ACL changes. In a fresh ephemeral database only, compare expected effective privileges after an explicitly reviewed test-only setup. |
| 20261116201639 | Auto-activate verified demo pairs and schedule | Test activation eligibility against synthetic market/asset rows in rollback transactions. Replace Cron creation with an inert schedule-manifest assertion. |
| 20261121045434 | Dynamic function-body replacements and backpressure guards | Do not run dynamic pg_get_functiondef/string-replacement code until each exact source/target fingerprint is pinned. Test the resulting function definitions as exact reviewed bodies. No queue cleanup or worker execution. |
| 20261121045531 | Snapshot pg_net queue/response tables | Exclude from replay entirely. Do not read, copy, fabricate or persist operational queue payloads. Assert only that the migration is classified as non-replayable. |
| 20261121050216 | cron.alter_job for jobs 14 and 16 | Exclude execution entirely. No job creation/alteration in any shared database. Validate the reviewed job ID/target metadata as a static assertion only. |

Any additional statement discovered in a file must be classified before the test harness can consume it. Unknown statements fail closed.

## 4. Dependency-ordered test phases

### Phase A — immutable source inventory
1. Fetch the 17 exact recovered files from the reviewed PR #62 commit and the corresponding Production ledger hashes already recorded in the evidence package.
2. Verify source provenance header boundaries, version, normalized name, byte count and hash. The expected SQL body must match the Production ledger text exactly.
3. Reject any file whose source ref changes, whose body hash is not the reviewed value, or whose timestamp/name mapping is ambiguous.
4. Preserve the Kifpool substantive divergence as a separate source artifact. Do not silently choose one body.
5. Keep the 17 missing-source canonical paths and the two local-only refresh files out of any push/replay list.

### Phase B — clean disposable bootstrap
1. Start only postgres:17 as a GitHub Actions service container with a fixed local-only database name.
2. Assert server_version_num begins with 17, current database equals the exact fixture database name, and server address is local to the job container.
3. The workflow must not define or read SUPABASE_DB_URL, DATABASE_URL, DIGIARZ_TEST_DB_URL, Production project refs, service keys, or JWT secrets.
4. Create only synthetic roles/schemas and minimal prerequisite tables. Use deterministic UUIDs reserved for tests.
5. Do not install Supabase extensions or emulate Supabase-managed roles unless a specific test requires a documented minimal shim. Label every shim as non-platform behavior.
6. Fail if any connection string or environment variable could route SQL to a remote host. No fallback database target is allowed.

### Phase C — schema and function units
1. Apply only the reviewed schema-only subset of 20261115101709 and required synthetic prerequisite objects, in a fresh disposable database.
2. Verify relation columns, primary/foreign keys, indexes, RLS enabled/forced flags, policies and grants against the expected test fixture contract.
3. Install exact function bodies only after their prerequisite tables/helpers are present.
4. For functions that call net.http_get, net.http_post, or inspect net._http_response, use an explicit local no-op stub or synthetic response table. Assert that no socket/network extension is present and that no HTTP call is attempted.
5. For dynamic function rewrites, compare exact input fingerprint before transformation and exact expected output fingerprint afterward. If either differs, stop; never perform fuzzy replacement.
6. Do not run the privileged identity-seed migration. The only administrator is the fixed synthetic identity created by the bootstrap fixture.

### Phase D — worker, trigger and admin behavior
- Exercise pure response parsing using synthetic JSON payloads for each exchange.
- Test request/response association with synthetic request IDs; no real pg_net queue or external response payloads.
- Test observation upsert, matching status and auto-list trigger with synthetic assets only.
- Test admin report, manual-request authorization, role probe, wallet adjustment and pair activation using anon, ordinary authenticated UUID, and one synthetic super-admin UUID.
- For financial functions, assert expected arithmetic in a transaction and issue ROLLBACK; additionally assert that synthetic balance/audit rows return to their pre-test state.
- Add two-synthetic-user isolation tests for wallets, balances, orders, trades, reservations, conditional orders, transactions and reviews. Each user must be unable to read or mutate the other's rows. Include anon-denial tests.
- Keep tests of function EXECUTE grants separate from function-body authorization tests; a catalog denial must not be described as proof that the body guard works.

### Phase E — cron, queue and external-effect exclusion
- Never create or alter cron.job entries.
- Never invoke request workers that can call HTTP. Do not load pg_net as an extension.
- Never snapshot, restore, replay or persist pg_net request/response queues.
- Represent the expected cron jobs and cadence only as static expected metadata in a test file. The test may verify that source references match the reviewed job IDs and routine names; it must not issue cron SQL.
- Explicitly fail the workflow if pg_cron, pg_net, a network client, a Production secret, or a remote DB URL is available to the test process.
- Do not import, call or modify order-engine Cron jobs.

### Phase F — catalog parity assertions and teardown

Compare only the objects deliberately installed in the disposable fixture:
- exact function identity arguments, result types, owners, SECURITY DEFINER flags, volatility and search_path;
- exact effective API-role EXECUTE matrix and schema USAGE where modeled;
- relation definitions, constraints, indexes, RLS flags and policy predicates;
- trigger function bindings and enabled state;
- expected but deliberately uncreated Cron/HTTP/queue side effects as explicit exclusions.

At job end:
- assert only synthetic IDs and rows exist;
- assert all financial fixture tables are empty after rollback;
- assert no request/response queue table was created;
- assert no Cron table/job was created or altered;
- destroy the service container automatically with the job.

A pass means only that the tested subset behaves as expected on the disposable PostgreSQL 17 fixture. It does not prove full Supabase parity or authorize Production replay.

## 5. Required CI guardrails before implementing this plan

A future workflow change must be separately reviewed and should include:
- a new job name that clearly says ephemeral-migration-replay;
- services.postgres.image: postgres:17, fixed local database and fixed local credentials only;
- no GitHub secrets, no repository variables that enable remote integration, and no configurable remote DB URL;
- a static denylist for network, pg_net, pg_cron, queue snapshot, cron.schedule, cron.alter_job, and privileged identity seed statements;
- a SQL statement classifier with allowlist by exact file hash and exact statement digest; unknown statement = hard failure;
- explicit database/host assertion before every psql invocation;
- one migration unit per isolated transaction/database; no blind glob over supabase/migrations or supabase/drafts;
- captured logs and catalog snapshots with synthetic values only;
- a final zero-side-effect assertion.

Do not edit or enable the existing rpc-security-integration job. It targets the Recovery-Test project, which is known not to be a Production-parity clone, and remains intentionally skipped.

## 6. Acceptance gates

The replay validation plan is not ready to execute until all are true:

1. Every statement in all 17 SQL bodies has a reviewed category and an exact expected file hash.
2. The 16 byte-exact timestamp-drift cases and 3 whitespace-only cases are kept distinct from the substantive Kifpool divergence.
3. The two local-only KuCoin/Gate.io files are excluded.
4. Schema prerequisites and dependency order are explicit for every function/table/trigger tested.
5. External HTTP, Cron, queue snapshot, privileged identity seed, and financial writes are impossible by construction, not merely expected not to occur.
6. Two-user RLS isolation and exact function ACL tests are implemented on synthetic data.
7. The disposable workflow cannot read secrets or reach a remote DB.
8. A reviewer has inspected the complete SQL statement classifier and test logs.
9. The run succeeds on PostgreSQL 17 and all containers are destroyed.

Until all gates pass, report the replay as NOT RUN / BLOCKED, not passed.

## 7. Work performed for this plan

- Reviewed the existing PostgreSQL 17 workflow and its service-container boundary.
- Confirmed the current successful PR #62 run 45617838082 ran unit/type checks and the disposable PostgreSQL 17 RPC smoke suite; remote rpc-security-integration was skipped.
- Inspected the existing bootstrap, 46-signature fixture and PostgreSQL 17 contract tests to distinguish the current RPC smoke harness from a migration replay harness.
- This document is planning/review evidence only. No workflow, SQL test, migration file, database, secret, variable, role, function, grant, RLS policy, trigger, Cron job, Edge Function, deployment, or financial record was changed or executed.
- No merge, Production mutation, Recovery-Test mutation, project/branch provisioning, or cost-bearing resource was created.

## 8. Next bounded implementation unit

After review, implement only a static statement-classification manifest for the 17 exact source bodies. The manifest should list statement ordinal, statement digest, object targets, classification, dependencies, and whether the statement is excluded from replay. It must not contain runnable SQL copies and must not invoke a database. Only after that manifest passes review should a disposable replay test be considered.


## 9. Static statement-classification manifest — first pass completed (2026-11-25)

A non-executable JSON manifest is now stored at:
supabase/drafts/2026-11-25_recovered-migration-statement-classification.json

- All 17 recovered source bodies were re-fetched from the reviewed PR #62 branch.
- The lexical splitter produced 136 statement units while respecting SQL single/double quotes, line/block comments and PostgreSQL dollar-quoted bodies.
- Each file has a source blob SHA, exact body SHA-256 and UTF-8 byte length. Each statement has an ordinal, SHA-256 digest, classification, best-effort target and short preview. No runnable SQL body is copied into the manifest.
- The SHA-256 implementation was checked against the standard "abc" and empty-string test vectors.
- Classification is fail-closed: unknown statements block replay. The first pass was refined to zero unclassified-unknown statements.
- Three dynamic pg_get_functiondef/replace/EXECUTE blocks in 20261113153808 remain explicit manual-review blockers because they rewrite execute_demo_trade, place_limit_order and process_limit_orders.
- Eight BEGIN/COMMIT transaction-wrapper statements are marked for removal/re-authoring at the fixture layer, not standalone replay.
- Cron, external HTTP/pg_net queue, privileged identity seed, financial DML, generic synthetic DML, ACL assertion-only, and schema/function candidate units have separate classifications.

This is a static inventory only. It does not prove every unit is safe to execute, and the best-effort target extraction is not a dependency proof. The 3 dynamic trading-function rewrites are still blocked; Cron/HTTP/queue/identity/financial effects remain excluded or synthetic-only. No SQL statement was executed, no database was changed, and no workflow was modified.

Next bounded step: independently review every statement classification and target against its full SQL body, especially all 136 statement ordinals and any dynamic SQL. Then add explicit object dependency edges and only afterwards design the isolated test-unit list. Replay remains NOT RUN / BLOCKED.


### Target-locator refinement

The statement manifest was refined after reviewing the unresolved target previews:
- 136/136 statement units now have a best-effort object target locator.
- 0 target locators remain unresolved.
- 0 statements remain in the unclassified-unknown category.
- The three dynamic trading-function rewrites remain manual-review blockers, despite their exact function targets now being identified.

Target locators are navigation aids only. They do not prove dependency order, ownership, exact runtime effect, or replay safety. The complete SQL body still requires reviewer inspection before any test-unit selection.
