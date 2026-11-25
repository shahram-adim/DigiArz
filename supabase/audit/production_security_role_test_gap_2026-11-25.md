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
