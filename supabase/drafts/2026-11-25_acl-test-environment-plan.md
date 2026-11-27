# DigiArz — Production-Parity ACL Test Environment Plan

**Status:** REVIEW DRAFT ONLY — NOT AN EXECUTION RUNBOOK  
**Date:** 2026-11-25  
**Related PR:** #62 — `feature/persian-asset-name-candidates-2026`  
**Production project:** `gfoaubfilhttnwjykaox` (read-only evidence only)  
**Current recovery test project:** `zrriqwyolcjhbappocuw` (not a valid ACL/cron/Auth parity clone)

## 1. Purpose and hard safety boundary

Prepare a reproducible, disposable environment in which the proposed PostgreSQL function EXECUTE-default changes and exact-signature RPC grants can be tested before anyone considers a production change.

This document does not authorize:
- creating or upgrading a Supabase project/branch or enabling an extension;
- restoring, cloning, or copying Production data;
- running migrations, DDL, GRANT, REVOKE, ALTER DEFAULT PRIVILEGES, db push, or SQL that changes state;
- changing Auth users/triggers, Cron jobs, Edge Function deployments, secrets, variables, or CI secrets/gates;
- changing any Production object or data;
- merging PR #62 or incurring infrastructure cost.

Production remains SELECT/catalog-only. Never pause, throttle, reschedule, or invoke the live trading/order or market-sync workers as part of this work.

## 2. Evidence baseline and why the current Recovery-Test project is unsuitable

The 2026-11-25 read-only catalog comparison found:
- all 13 Production service_role-only candidate functions exist in Recovery-Test, but their `proacl` is NULL and effective EXECUTE is available to `anon`, `authenticated`, and `service_role`;
- Recovery-Test has no matching `pg_default_acl` rows for public/global function defaults;
- Recovery-Test has no `cron.job` relation in its current state;
- no `auth.users.on_auth_user_created -> public.new_user_setup()` trigger was found.

Therefore Recovery-Test cannot reproduce Production's explicit function ACLs, future-function defaults, Cron execution identity, or Auth-trigger path. It must not be used to claim a Production-parity test passed.

Production evidence already recorded in `2026-11-25_rpc-caller-inventory.md`:
- 36 SECURITY DEFINER functions have effective service_role EXECUTE; all are postgres-owned and have explicit safe search_path settings.
- 13 functions are service_role-only among API roles; 23 also allow authenticated.
- 14 relevant Cron jobs are active and owned/run as `postgres`.
- `auth.users.on_auth_user_created` invokes `public.new_user_setup()`.
- reviewed Edge Functions use service key for direct PostgREST table operations, not the 13 service_role-only RPCs.
- Historical snapshot only: at the time of this initial catalog review, no caller was found. This conclusion is superseded by section 11, which confirms the active `admin-refresh-crypto-asset` Edge Function v2 calls `public.claim_admin_asset_refresh(text,uuid)` using service_role.

## 3. Preconditions for a disposable parity environment

Do not create or prepare the environment until the owner separately approves the target, method, and any cost. Preferred source is a schema/catalog-only snapshot or a supported Supabase branch/clone process that excludes real personal, wallet, order, trading, and financial data. Use synthetic identities and synthetic fixtures only.

Before testing, record and compare the following to the 2026-11-25 Production catalog snapshot:

1. **Platform/Postgres:** compatible Postgres major/minor family and Supabase-managed schema baseline; record extension names/versions and relevant settings. Do not assume extensions can be installed without platform support.
2. **Roles:** required Supabase roles exist with matching role attributes needed for authorization tests. Never copy Production credentials, passwords, JWT secrets, service keys, or user tokens.
3. **Function inventory:** exact schema, function name, identity arguments/signature, owner, `prosecdef`, `proconfig`/search_path, volatility, language, and effective ACL for every relevant function. Include overloads separately.
4. **Default ACLs:** inspect both global (`defaclnamespace=0`) and public-schema defaults for each relevant grantor, especially `postgres`; document Supabase-managed `supabase_admin` defaults as platform-owned and do not attempt to alter them.
5. **Cron:** confirm `pg_cron` availability, exact job names/schedules/commands, and `username='postgres'` for the 14 jobs under review. Use inert/synthetic test commands or a separately designed isolated schedule; never import live schedules that can call real external services or mutate real data.
6. **Auth trigger:** confirm `auth.users.on_auth_user_created` wiring and function owner/security mode. Use synthetic Auth identities only; verify the trigger path without production users or external email/SMS delivery.
7. **Schema and policies:** capture relevant schema USAGE, table privileges, RLS enablement/policies, private-schema access, and SECURITY DEFINER ownership. Keep table-level tests distinct from RPC EXECUTE tests.
8. **Edge Function behavior:** represent the service-key direct table access separately from RPC. No real secrets or deployed functions need to be copied; use local mocks or isolated test credentials.
9. **Baseline artifacts:** preserve read-only catalog snapshots and checksums so the pre-test and post-test states can be compared.

A missing item is a **test-environment blocker**, not a reason to approximate silently.

## 4. Test matrix to implement only after parity is approved

### A. Catalog and default-ACL contract

- Verify global `postgres` function defaults do not confer EXECUTE to PUBLIC if and only if the reviewed hardening proposal is approved.
- Verify public-schema defaults do not add EXECUTE to PUBLIC, `anon`, `authenticated`, or `service_role` if and only if that exact policy is approved.
- Verify a newly created harmless test function owned by `postgres` receives only the expected defaults; create it only inside the disposable test environment and remove it within the same isolated test lifecycle.
- Test an object created by a different grantor separately; do not assume `postgres` defaults govern it.
- Confirm the documented `supabase_admin` exception; do not attempt to modify platform-managed defaults.

### B. Exact-signature RPC authorization

For every exact function signature in the reviewed inventory, test effective privileges and invocation separately:
- `anon`: denied unless an explicit public anonymous endpoint is intentionally approved;
- ordinary `authenticated`: denied unless the function is intentionally user-facing and its body enforces user/ownership authorization;
- designated synthetic super-admin: allowed only for approved admin RPCs and only after server-side authorization checks;
- `service_role`: allowed only for exact RPCs with a documented service-role caller; direct table access is not evidence that RPC EXECUTE is required;
- `postgres`: verify the actual owner/Cron/trigger execution path without changing Production schedules.

Do not infer a function's authorization from its name. Include positive and negative tests for every overload. Inspect SECURITY DEFINER bodies and confirm safe search_path and explicit authorization.

### C. Cron and Auth-trigger execution

- Prove that representative worker functions execute under the configured `postgres` Cron identity in the isolated environment, without relying on service_role EXECUTE.
- Verify the Auth-created-user trigger invokes `new_user_setup()` in the expected owner/security context with a synthetic user.
- Assert that order-processing and exchange-sync test fixtures remain isolated and that no external API, payment, notification, or live market side effect is possible.
- No live Production Cron job is to be invoked, disabled, slowed, or rescheduled.

### D. Edge Function / service key separation

- Test the Edge Function's session validation with a synthetic user JWT.
- Test direct PostgREST table operations with the isolated service key and only the required table privileges.
- Separately test that the service key cannot invoke an RPC unless that exact RPC grant is intentionally part of the approved contract.
- Confirm that a service key's RLS bypass does not get conflated with function EXECUTE privileges or table grants.

### E. Confirmed refresh-claim function caller

The previous unresolved-caller wording is superseded by the live trace in `2026-11-25_refresh-claim-live-caller-trace.md`:
- Production Edge Function `admin-refresh-crypto-asset` v2 is ACTIVE with `verify_jwt=true`;
- it validates the Bearer token through `auth.getUser(token)`, verifies super-admin access through the user-scoped RPC, derives the UUID from the verified Auth response, and calls `public.claim_admin_asset_refresh(text,uuid)` through a server-side service-role client;
- the exact explicit `service_role EXECUTE` grant is required by this deployed caller and must be preserved unless the caller is intentionally redesigned and separately reviewed;
- the available 24-hour log window showed no invocation, which does not negate the deployed source/caller path.

The disposable PostgreSQL 17 harness now tests the real Migration body, boolean return type, super-admin lookup, invalid-input rejection, and 30-second cooldown using synthetic rows only. This per-function grant is separate from the still-undecided default-function EXECUTE policy.

## 5. Existing test-contract discrepancy — must be resolved before enabling CI

The current `tests/default-function-acl-hardening.sql` asserts that the `postgres` public-schema default continues to grant EXECUTE to `service_role`.

The current review draft `2026-11-25_proposed_restrict_default_public_function_exec.sql` proposes revoking default EXECUTE from `service_role` as well. Its original caller rationale was corrected in section 11 after a live Edge Function caller was confirmed. The future-default policy remains a separate owner decision; preserve the explicit grant for `claim_admin_asset_refresh(text,uuid)`.

These two artifacts express different target policies. Do not run or enable the integration gate until the owner/reviewer chooses one policy and the SQL contract test is updated to match it. Preserve the current CI skip; do not change repository secrets, variables, or the gate as part of this plan.

The current `tests/rpc-security.integration.sql` is a transaction-scoped test of one read-only admin RPC with temporary grants and rollback. It is not a complete exact-signature test suite and does not establish Production parity.

## 6. Pass/fail gates

**PASS only if all are true:**
- the disposable environment's required catalog, roles, defaults, functions, trigger, extensions, and isolated Cron model match the approved parity manifest;
- every exact signature has a documented caller and expected role matrix;
- all negative and positive authorization tests pass;
- no unapproved API role can invoke privileged SECURITY DEFINER functions;
- Cron and Auth-trigger tests succeed under the observed execution identities;
- Edge Function table access and RPC EXECUTE are tested independently;
- no external or Production side effects occur;
- pre/post snapshots show no unexpected changes;
- the default-ACL SQL test and the written proposal describe the same policy;
- CI integration gate is enabled only by a separate explicit approval after review.

**FAIL / BLOCK** if any role, owner, ACL, trigger, schedule, extension, or signature is missing or differs; if a function's caller remains unexplained; if a test needs real user data or production secrets; if any test can reach a live worker/external side effect; or if the test contract and proposal disagree.

## 7. Proposed sequence — no execution authorized

1. Review this plan and settle the service_role default-policy discrepancy.
2. Obtain explicit approval for a no-real-data disposable environment and confirm whether it can be created at zero cost. If cost is uncertain or any paid feature is required, stop and ask.
3. Prepare a parity manifest from read-only catalog evidence; independently review it.
4. Only after separate approval, provision/prepare the isolated environment using an approved method and synthetic fixtures.
5. Implement the exact-signature positive/negative tests and inert Cron/Auth-trigger tests.
6. Run tests and capture logs/catalog snapshots; review all failures.
7. Produce a separate proposed Production migration only after the isolated tests pass and the owner explicitly authorizes preparation of that migration. Execution remains a separate approval.
8. Keep PR #62 Draft and unmerged until all gates and the broader PR review are complete.

## 8. Current execution status

- This file is a planning document only.
- No Supabase project/branch/clone was created or modified.
- No extension, role, function, trigger, Cron job, Auth user, fixture, ACL, or table was changed.
- No SQL migration or DDL was executed.
- No Production query beyond the already documented read-only catalog audits was run for this plan.
- No CI gate, secret, variable, or deployment was changed.
- No PR merge or infrastructure spend occurred.


## 9. Follow-up review of current CI artifacts (2026-11-25)

The latest Push and Pull Request runs on the plan commit `ec10ff0cc556701bdb0d0baa8e0d20e9d9d40a52` both completed:
- `unit-tests`: success (candidate extraction tests and isolated Edge Function type-check).
- `rpc-security-integration`: skipped in both runs, as intended by the current opt-in gate.
- These results do not validate database ACL behavior or Production parity.

Additional static review findings:

1. `tests/default-function-acl-hardening.sql` currently encodes the policy that `service_role` keeps public-schema default EXECUTE. The proposal file encodes the opposite policy. This is a genuine contract mismatch. Neither artifact should be changed until the owner/reviewer explicitly selects the intended default policy.
2. `tests/rpc-security-catalog.sql` compares most role allowlists by schema + function name, not by exact identity-argument signature. It separately fails if any SECURITY DEFINER function name has multiple overloads, which reduces ambiguity but does not fully assert the exact argument signature. A future reviewed revision should use explicit (schema, name, identity_arguments) tuples and compare those against catalog results.
3. The catalog test's service_role allowlist reflects the current Production baseline (including the 13 service_role-only candidates and the 23 functions also executable by authenticated). It is not a proposed post-hardening ACL state and must not be reused as a post-change expected matrix without an explicit decision.
4. `tests/rpc-security.integration.sql` temporarily grants public-schema USAGE and EXECUTE to anon/authenticated inside a transaction, then tests the function body's super-admin guard and rolls back. It is useful as a function-body authorization test, but it does not prove the real catalog ACL contract; temporary grants deliberately bypass that part of the test. Its fixture also requires exactly one synthetic super-admin row.
5. Both current workflow runs confirm the integration job remains skipped; do not enable it until a disposable parity environment and the policy contract are approved.

Recommended next review unit: prepare a separate, non-executable exact-signature ACL matrix (current Production state versus proposed target state), with each function's owner, SECURITY DEFINER flag, search_path, current effective API roles, observed caller, and proposed required roles. The earlier unresolved classification for `claim_admin_asset_refresh(text,uuid)` is superseded by section 11. Do not generate executable GRANT/REVOKE statements until every row has a verified caller and the owner approves the target policy.

This section is evidence/review documentation only. No SQL test was run, no CI workflow or gate was changed, and no database object or privilege was modified.


## 10. Follow-up: exact-signature contract and parity preflight (2026-11-25)

### Repository state revalidated
- PR #62 remains open, Draft, unmerged; latest head at the start of this review was `40cb62b7c74861441862bb42bd5a45ca683a2bb7`.
- The workflow on that head completed successfully for `unit-tests`; `rpc-security-integration` remains intentionally skipped.
- The updated `tests/rpc-security-catalog.sql` now compares exact tuples of schema, function name, identity arguments, and effective EXECUTE booleans for anon/authenticated/service_role. Its inventory contains 46 reviewed SECURITY DEFINER signatures.
- The SQL test also asserts the observed schema USAGE matrix and constrained search_path / no direct PUBLIC EXECUTE conditions.
- The schema USAGE matrix was independently re-read from Production: public USAGE is true for anon/authenticated/service_role; private USAGE is false for anon/service_role and true for authenticated. These six values match the test contract.
- This contract is a current-state regression snapshot only. It is not the proposed post-hardening target.

### Test environment decision
- Existing `DigiArz-Recovery-Test` is currently `ACTIVE_HEALTHY` on PostgreSQL 17.11, but remains non-parity: it lacks matching Production explicit function ACLs, relevant default ACL rows, `cron.job`, and the Auth user-creation trigger.
- Its healthy status does not make it safe or valid for this test. Do not run the exact Production snapshot test there and do not claim a pass/fail based on its known structural mismatch.
- No new Supabase project or branch was created. No branch provisioning was attempted because it can incur compute/usage charges and requires explicit cost approval.
- No production or test database DDL, grants, revokes, function invocation, fixture insertion, trigger change, or Cron action was performed.

### Remaining parity blockers
1. The owner/reviewer must choose between the two conflicting service_role future-function default policies encoded in `tests/default-function-acl-hardening.sql` and `supabase/drafts/2026-11-25_proposed_restrict_default_public_function_exec.sql`. Do not silently align either artifact.
2. Decide and approve the isolated environment provisioning method and any cost. Preferred route is a zero-real-data disposable database with synthetic Auth identities, no copied secrets, and inert Cron fixtures. If the supported route costs money or requires a paid tier, stop.
3. Build a parity manifest and compare exact signatures, owners, security modes, search_path, effective API-role ACLs, default ACLs per grantor, schema USAGE, extensions, Auth trigger, and Cron identities before running any test.
4. Preserve all production schedules as evidence only. Never import live worker commands or invoke real exchange, price, order, notification, or payment side effects in the disposable environment.
5. Preserve the confirmed service_role caller grant for `claim_admin_asset_refresh(text,uuid)`; investigate any additional external/manual callers and the intended rate-limit design before proposing a runtime redesign.
6. Only after the policy conflict and parity preconditions are resolved, prepare positive/negative per-signature authorization tests and inert Auth/Cron tests. Enable the CI integration job only after a separate explicit approval.

At the time this section was written, no test environment had been provisioned. Section 11 records the subsequent disposable PostgreSQL 17 smoke harness and its passing first run. Full Production parity remains NOT ready.

## 11. Disposable PostgreSQL 17 smoke harness — first execution result (2026-11-25)

The plan above remains the authority for full Production-parity testing. The following limited smoke phase is now implemented and has passed:

- A per-job `postgres:17` service container runs in GitHub Actions; observed server version was PostgreSQL **17.12**.
- Synthetic `anon`, `authenticated`, and `service_role` roles were created. One fixed synthetic super-admin identity was inserted into the ephemeral container only.
- The test-only `auth.uid()` shim reads the transaction-local synthetic subject; it is not a JWT verifier and is not production code.
- The exact read-only Production body of `public.admin_exchange_asset_sync_report()` was exercised against empty synthetic reporting tables.
- The separate fixture contract passed: exact zero-argument signature, SECURITY DEFINER, empty search_path, anon EXECUTE denied, authenticated/service_role EXECUTE present, and no direct PUBLIC EXECUTE.
- The complete current-state catalog contract also passed for all **46 exact SECURITY DEFINER signatures**, including effective EXECUTE booleans for anon/authenticated/service_role, constrained search_path, no direct PUBLIC EXECUTE, and the six schema-USAGE expectations. The 43 non-exercised function bodies are inert metadata-only stubs; only the three reviewed helper/report bodies are installed, and only the read-only report RPC is invoked.
- Function-body tests passed: anon and ordinary authenticated both received SQLSTATE `42501`; the synthetic super-admin received the expected JSON report. The transaction rolled back and the post-check confirmed exactly one synthetic admin fixture.
- Both GitHub Actions runs associated with head `2ccd668038adddf7cdee0944f02089dacad34f5d` completed the `postgres17-rpc-smoke` and `unit-tests` jobs successfully. The pre-existing remote `rpc-security-integration` job remained skipped.

### What this result does not prove

This is a PostgreSQL 17 smoke test that validates the 46-signature current-state ACL metadata contract and exercises one read-only admin RPC body, **not** a Production-parity pass. It does not validate the future-function default ACL contract, all RLS/table grants, the real Supabase Auth trigger, `pg_cron`, or the 43 stubbed function bodies and their dependency graphs. It does not resolve the owner decision about the future `service_role` EXECUTE defaults.

The Recovery-Test project remains unsuitable and untouched. The missing-migration/source reconciliation remains a blocker to full schema replay. No persistent Supabase database, GitHub secret, CI variable, Production object, ACL, trigger, Cron job, or financial record was changed.

### Corrected refresh-claim caller evidence

The earlier statements in this plan that described `claim_admin_asset_refresh(text,uuid)` as having no known Edge Function caller are superseded by the live runtime trace recorded in `2026-11-25_refresh-claim-live-caller-trace.md`: the active Production `admin-refresh-crypto-asset` Edge Function (version 2) calls this exact RPC using its server-side service-role client after validating the user JWT and super-admin status. Preserve its exact service_role EXECUTE grant unless the caller is intentionally redesigned and reviewed. This does not justify blanket service_role EXECUTE defaults for unrelated functions. The available 24-hour log window did not show a request to that Edge Function, so source-level caller existence is confirmed but a request during that window is not.

### Next action

Extend the ephemeral fixture one reviewed exact-signature function at a time, then produce a complete Production-vs-fixture parity manifest. Keep default ACL policy unresolved and the remote-database integration gate disabled until full parity and separate owner approval.
