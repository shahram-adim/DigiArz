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
- `public.claim_admin_asset_refresh(text,uuid)` has no caller found in the active browser entrypoint, reviewed Edge Functions, database function bodies, Cron jobs, or application triggers. This remains unexplained, not proven unused outside the inspected sources.

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

### E. Unresolved refresh-claim function

Before deciding the fate of `public.claim_admin_asset_refresh(text,uuid)`:
- search all active repository code, deployment configuration that is accessible without revealing secrets, function logs/metadata where authorized, and known external/manual worker documentation;
- determine whether rate limiting is intended to be enforced by this RPC;
- if an Edge Function currently bypasses this RPC and performs direct table operations, record the design gap and propose a separately reviewed correction;
- do not revoke or grant this function based only on absence of a repository callsite.

## 5. Existing test-contract discrepancy — must be resolved before enabling CI

The current `tests/default-function-acl-hardening.sql` asserts that the `postgres` public-schema default continues to grant EXECUTE to `service_role`.

The current review draft `2026-11-25_proposed_restrict_default_public_function_exec.sql` instead proposes revoking default EXECUTE from `service_role` as well, because no service-role RPC caller was found in the reviewed Edge Functions and Cron runs as `postgres`.

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

Recommended next review unit: prepare a separate, non-executable exact-signature ACL matrix (current Production state versus proposed target state), with each function's owner, SECURITY DEFINER flag, search_path, current effective API roles, observed caller, and proposed required roles. Mark `claim_admin_asset_refresh(text,uuid)` as unresolved. Do not generate executable GRANT/REVOKE statements until every row has a verified caller and the owner approves the target policy.

This section is evidence/review documentation only. No SQL test was run, no CI workflow or gate was changed, and no database object or privilege was modified.
