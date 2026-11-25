# Production security role-test gap — 2026-11-25

## Scope and branch separation

- PR #63 is the Production security audit branch based on `main`; it remains an open Draft and unmerged.
- PR #62 is a separate open Draft on `feature/persian-asset-name-candidates-2026`, based on `redesign/ui-clean-rebuild-2026` (PR #61 candidate), not on `main`.
- Evidence from PR #62 is recorded here as cross-branch evidence only. It has not been merged, cherry-picked, or applied to PR #63 or Production.
- No Merge, `db push`, Production SQL, grant/revoke, policy, function, view, data, Cron, queue, Edge Function, deployment, wallet, order, or financial-row mutation is authorized by this note.

## Evidence checked on 2026-11-25

### PR #63 audit branch

- The earlier workflow run on head `c21ac67990ee8ad468b4260ad7b3b160d6b22c90` was successful: run `45643794201` (#2023).
- It executed `node --test tests/*.test.js`: 88 passed, 0 failed, 0 skipped.
- That suite contains static assertions for the 46-function SECURITY DEFINER manifest, the two-function anon allowlist, admin guard text, RLS/grant snapshots, security-invoker view metadata, 27 relation references, and the original migration-source reconciliation.
- The docs-only follow-up commit `ac5036591502701aa682a8e6786b9386a97c82fc` also completed its workflow successfully (run `45659490513`). Its PostgreSQL 17 arithmetic, schema-widening, trading-lifecycle and two-session race checks passed. This run did not contain a dedicated security role matrix.

### PR #62 source-recovery evidence

- PR #62 contains 17 separate files under `supabase/drafts/recovered_*.sql`; all 17 paths were fetched and their contents were confirmed present.
- Its recovery report states that the files were reproduced from the Production `supabase_migrations.schema_migrations.statements` column on 2026-11-25.
- This provenance was independently re-verified with SELECT-only queries against the ACTIVE_HEALTHY Production project (PostgreSQL 17.11). The catalog shows `statements` is `text[]`; for each of the 17 versions, the query compared `md5(array_to_string(statements, E'\\n'))` with `md5(recovered_file_body)`, after removing only the nine-line review/provenance header. **All 17 of 17 matched exactly**, with identical byte lengths and identical MD5 values. Each ledger row contained one statement element.
- This establishes byte-exact recovery of the recorded historical SQL text. It does not establish that replaying any statement is safe or appropriate.
- The recovered versions are review-only drafts, not canonical files in `supabase/migrations/`. Their presence does not authorize replay or deployment.
- The 17 recovered migration versions are:
  - `20261113153808`, `20261113154323`, `20261113154736`, `20261113154750`, `20261113154844`, `20261113154926`;
  - `20261115101709`, `20261115102729`, `20261115102927`, `20261115103227`, `20261115103507`, `20261115105721`, `20261115105956`;
  - `20261116201639`;
  - `20261121045434`, `20261121045531`, `20261121050216`.
- The old reconciliation finding should now be read precisely: 17 canonical migration source paths were missing from the repository migration directory; source text has since been recovered into review-only draft files on PR #62. Canonical-path reconciliation, dependency/order review, and isolated replay validation remain incomplete.
- The 20 timestamp/content mismatches in the broader local-vs-Production migration reconciliation remain a separate issue; recovery of these 17 sources does not resolve them automatically.

### PR #62 PostgreSQL 17 security smoke run

- PR #62 head at the time of inspection: `66dad350ad3f02a7c3c885c4bd2e45e9f1f0e53b`.
- Workflow run `45617838082` completed successfully. The `postgres17-rpc-smoke` job passed all 27 steps; the unit/type-check job passed; the remote-database `rpc-security-integration` job was skipped as configured.
- The ephemeral PostgreSQL server was PostgreSQL 17. The workflow used a job-local `postgres:17` service and synthetic roles/identities, not the Production URL, Supabase credentials, or user data.
- The smoke fixture checked the exact 46 SECURITY DEFINER signatures and current API-role EXECUTE booleans, constrained search_path, absence of direct PUBLIC EXECUTE, and schema-USAGE contract.
- The workflow step loads 34 inert metadata stubs plus 12 real/source-backed bodies, then replaces the exchange-discovery stub with its applied migration body. The final fixture therefore has 33 inert stubs and 13 real/source-backed bodies. The inert stubs are metadata-only and must never be counted as tested Production implementations.
- Runtime checks passed for selected paths:
  - `anon`, ordinary `authenticated`, and one designated synthetic super-admin against the read-only admin sync report function (including function-body denials/allowance);
  - `service_role` on the synthetic admin asset-refresh claim path and its cooldown/error cases;
  - public market-listing reads under anon/authenticated/service_role;
  - selected admin-search, admin add/enable listing, exchange-discovery, trigger, fee-rate, and owner-scoped reservation paths.
- These are real PostgreSQL 17 fixture executions, but they are a **targeted smoke harness**, not a full Supabase or Production-parity test.

## Remaining security coverage gaps

1. **Function-body parity:** 33 of the 46 exact SECURITY DEFINER signatures remain inert metadata stubs in the PostgreSQL 17 fixture. Their Production bodies and dependencies have not been executed there.
2. **RLS parity:** the fixture does not reproduce every Production relation, policy, grant, owner, default ACL, Auth trigger, or extension. In particular, a complete two-user isolation matrix for wallets, balances, orders, trades, reservations, conditional orders, transactions, and coin reviews remains outstanding.
3. **Role matrix completeness:** runtime role tests cover selected functions only. They do not prove the positive/negative caller matrix for every signature or every worker RPC.
4. **Auth fidelity:** the fixture's `auth.uid()` shim reads a transaction-local synthetic subject. It is not Supabase JWT verification and does not test the real Auth platform.
5. **Service-role policy:** the conflict between the current/default ACL test and the proposed default-function EXECUTE hardening remains unresolved. Current-state ACL observations must not be mistaken for an approved target policy.
6. **Remote test gate:** the workflow's remote `rpc-security-integration` job remains skipped. Do not enable it until its destination, parity, secrets, and owner approval are explicitly verified.

## Migration replay hazards

Static source review of the recovered bodies identified several distinct classes of side effects. These are reasons to preserve the SQL as historical evidence, not reasons to execute it again:

- **Privilege/data seed:** `20261113154323` inserts or updates the `private.admin_users` super-admin row under a profile-count condition. Replaying it could reassign privileged access; never replay this identity/role assignment.
- **Wallet/fee seed and function replacement:** `20261113153808` inserts profile/wallet defaults and fee rows, creates review/report tables and policies, and dynamically replaces trading function definitions. Replaying it could touch account defaults or alter financial execution logic.
- **Wallet-management function definitions:** `20261113154736`, `20261113154844`, and `20261113154926` install or revise functions that, when invoked, can update wallet balances, insert transaction/audit rows, and change admin privilege checks. The function bodies must be reviewed independently; do not invoke them as part of source recovery.
- **External API and Cron setup:** `20261115102729` and `20261115103507` define request workers that call `net.http_get`, write request/observation rows, and create Cron schedules. Replaying them could enqueue real external requests and create duplicate/changed jobs.
- **Curated-market backfill and trigger:** `20261115103227` inserts rows into `admin_market_listings`, drops/recreates an observation trigger, and runs a backfill. It can change the visible curated market catalogue.
- **Demo-pair seed and Cron:** `20261116201639` inserts demo trading pairs and creates a Cron job.
- **Dynamic worker rewrites:** `20261121045434` dynamically replaces several live market-price, FX, crypto-asset, Iranian-exchange, and Bit24 function definitions. Its embedded request cleanup/back-pressure logic requires dependency-aware isolated validation.
- **Queue/response snapshots:** `20261121045531` creates persistent copies of `net.http_request_queue` and `net._http_response`; it is not a harmless schema-only migration and may duplicate transient operational payloads.
- **Cron schedule mutation:** `20261121050216` calls `cron.alter_job` for jobs 14 and 16. Do not execute it or alter any Production Cron schedule.
- The remaining recovered files also contain function/trigger, schema, RLS, and ACL definitions; they must be checked in historical order and against the current live catalog before any isolated rehearsal.

No recovered migration may be blindly replayed as a batch. Do not restore, replay, drain, delete, throttle, or reschedule any Production queue or worker. In particular, no order-engine Cron job may be paused, slowed, or rescheduled.

## Required next steps

1. Reconcile each of the 17 recovered draft files against its exact Production ledger version and retain per-file provenance/checksums; preserve the original historical text.
2. Reconcile the 20 timestamp/content mismatches without rewriting history or inferring migration provenance from current object state.
3. Build a disposable PostgreSQL 17 schema-replay harness from reviewed authoritative sources. Exclude Production data, secrets, live queue contents, and Cron side effects; fail closed if the target is not the disposable CI database.
4. Expand source-backed runtime coverage function-by-function, removing a stub only when the exact body and required dependencies are available.
5. Add two-synthetic-user RLS isolation tests and explicit role-positive/negative tests for the still-uncovered relations and RPCs.
6. Keep the remote-database job disabled and all proposed ACL hardening separate until the test destination, parity, and target policy have been approved.

## Current safety state

- PR #63 remains open, Draft, and unmerged.
- PR #62 remains a separate open Draft; its recovered SQL and PG17 harness have not been integrated into PR #63 or `main`.
- The PostgreSQL 17 smoke run used only an ephemeral CI container; the remote-database job was skipped.
- No Production migration, SQL, grant, revoke, RLS policy, function, view, data, Cron schedule, queue, Edge Function, deployment, or financial row was changed.
- No cost-creating project or database branch was created.


## Follow-up verification — dependency map and timestamp mismatches (2026-11-25)

A source-level dependency/order map for all 17 recovered historical migrations was added at [`production_migration_dependency_order_map_2026-11-25.md`](production_migration_dependency_order_map_2026-11-25.md). It records prerequisite objects, downstream consumers, data/HTTP/Cron/privilege side effects, and the minimum dependency edges. It is a review artifact only, not a replay manifest.

### Direct byte comparison of all 20 timestamp-mismatched local files

The 20 local SQL files mapped by normalized migration name were compared against their corresponding Production ledger `statements` bodies using byte lengths, MD5 values, and targeted line-level inspection of the non-exact cases:

- **16 of 20** are byte-for-byte identical to the Production ledger despite a different filename timestamp.
- **3 of 20** differ only by a single leading or trailing newline:
  - `20261113162154` ↔ `20261113162202_record_conditional_reservation_consumption.sql`;
  - `20261113162233` ↔ `20261113162244_index_conditional_execution_order_reference.sql`;
  - `20261113173506` ↔ `20261113190000_admin_on_demand_crypto_asset_refresh.sql`.
- **1 of 20** has a substantive SQL-body divergence:
  - Production ledger version `20261115134357` vs local `20261115134500_add_kifpool_to_scheduled_exchange_asset_sync.sql`.
  - The local file is 230 bytes longer and includes additional change-detection predicates that avoid updating unchanged observation match/status rows. The Production ledger body does not include those predicates. This is a behavioral divergence, not a filename-only mismatch. Keep both source versions distinct; do not rename the local file as if it were the historical Production body.

This narrows the timestamp mismatch problem substantially, but it does not authorize bulk renaming. The two local-only KuCoin/Gate.io refresh migrations remain unrecorded in the ledger and retain the previously identified risk of replacing the current 515-ID-capped market-price function with older definitions.

### Current live project and CI snapshot

- Production project remains `ACTIVE_HEALTHY`, PostgreSQL 17.11; its migration ledger currently contains 55 applied rows through `20261121050216`. All database inspection for this follow-up was SELECT-only.
- PR #61 head `3474f628eb5b7e7515fe9c559908235f09fa9a05`: UI visual review, exact-decimal tests, and isolated Android APK workflow runs completed successfully.
- PR #62 head `66dad350ad3f02a7c3c885c4bd2e45e9f1f0e53b`: unit/type-check and PostgreSQL 17 targeted RPC smoke passed; the remote database integration job was skipped.
- PR #63 head before this documentation follow-up `907bf1d5b7a0689dccb5db98c55c040bbe7787b0`: the observed run `45661119749` passed the exact-decimal job (including isolated PostgreSQL arithmetic/schema and trading lifecycle/race checks). It did not run the full security audit role matrix. CI for the new documentation commit must be checked separately before reporting its status.

### Safety and next step

No Migration was renamed, copied into `supabase/migrations/`, replayed, pushed, or applied. No migration ledger row, function, grant, RLS policy, queue, Cron schedule, Edge Function, deployment, wallet, order, trade, reservation, or financial record was changed. No merge or cost-creating resource was made.

Next: turn the dependency map into a disposable PostgreSQL 17 replay plan with external HTTP, queue snapshot, privileged identity seed, Cron scheduling/alteration, and all live data/financial writes explicitly excluded or replaced by synthetic assertions. Keep all Production operations gated by explicit owner approval.


## Disposable PostgreSQL 17 migration-replay plan — 2026-11-25

A review-only replay-validation plan has been added in PR #62:
https://github.com/shahram-adim/DigiArz/blob/feature/persian-asset-name-candidates-2026/supabase/drafts/2026-11-25_postgres17-migration-replay-validation-plan.md

The plan classifies all 17 byte-exact recovered historical SQL bodies by their schema/function/data/privilege/HTTP/Cron/queue effects and lays out a dependency-ordered, ephemeral PostgreSQL 17 validation approach. It explicitly excludes the privileged identity seed, real wallet/data writes, HTTP request execution, pg_net queue snapshots, pg_cron schedule creation/alteration, and both local-only KuCoin/Gate.io migrations. It also requires synthetic two-user RLS isolation tests and separates ACL denial from function-body authorization.

### Existing harness boundary confirmed

The current PR #62 workflow uses a postgres:17 service container and no Production database URL or secrets. Its latest verified run 45617838082 passed:
- unit tests and isolated Edge Function type-check;
- the targeted PostgreSQL 17 RPC smoke suite, including all 46 exact SECURITY DEFINER signatures and current API-role ACL metadata;
- 13 source-backed/reviewed function bodies plus 33 inert metadata-only stubs in the shared 46-signature fixture;
- targeted role, worker-claim, listing, exchange-discovery, admin search/add/enable, trigger, fee-rate and owner-scoped reservation tests.

The remote rpc-security-integration job was skipped as configured. The harness remains a targeted smoke suite, not full Supabase parity or a migration replay.

The new replay plan is documentation only. No workflow or test code was changed, no CI gate was enabled, no SQL was executed, and no Production/Recovery-Test object, privilege, data, queue, Cron schedule, or financial record was changed. The plan's next bounded unit is a static statement-classification manifest; execution remains blocked until the acceptance gates are reviewed.
