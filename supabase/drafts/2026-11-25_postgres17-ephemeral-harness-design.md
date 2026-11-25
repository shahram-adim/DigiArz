# DigiArz — Disposable PostgreSQL 17 RPC security harness

**Date:** 2026-11-25  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Purpose:** isolated CI smoke test without a new Supabase project or database branch.

## What this harness does

The existing GitHub Actions workflow starts a disposable `postgres:17` service container inside the job. It creates synthetic API roles and one synthetic super-admin identity, installs a test-only `auth.uid()` shim, seeds the current-state ACL metadata for all 46 exact SECURITY DEFINER signatures (43 inert stubs plus three reviewed real bodies), and exercises the current Production body of the read-only `public.admin_exchange_asset_sync_report()` function against empty synthetic reporting tables.

The test checks two separate security layers:

1. **Catalog/ACL contract:** the exact zero-argument function is SECURITY DEFINER, has an empty search_path, denies direct EXECUTE to `anon`, and allows the currently observed EXECUTE grants for `authenticated` and `service_role`.
2. **Function-body authorization:** the existing transaction-scoped test temporarily grants EXECUTE to `anon` and `authenticated` so it can reach the function body. It verifies that anonymous and ordinary authenticated identities receive SQLSTATE `42501`, while the designated synthetic super-admin receives a JSON report.

This separation matters: an ACL denial and a function-body authorization denial are different controls and must not be reported as the same test.

## Isolation and cost boundary

- No Supabase project or branch is created.
- No Production database URL, Supabase key, JWT secret, Auth token, or user data is used.
- No GitHub Actions secret or variable is read or changed.
- No external API, payment, email, SMS, market worker, Cron, or trading engine is invoked.
- The only inserted identity is the fixed synthetic super-admin UUID in the ephemeral container.
- The database container is scoped to one CI job and is discarded when the job ends.
- The workflow does not use the existing `DIGIARZ_TEST_DB_URL` secret and does not enable the existing `rpc-security-integration` job.

## Explicit scope limitation — not Production parity

This is a **PostgreSQL 17 ACL/function-behavior smoke harness**, not a complete Supabase or Production-parity clone. It reproduces the 46-signature current-state ACL metadata contract, but it does not reproduce:

- the remaining 43 SECURITY DEFINER function bodies and their dependencies;
- every Production table, RLS policy, schema privilege, owner, or default ACL;
- Supabase-managed roles and platform schemas beyond the minimal test shims;
- the real Supabase Auth implementation or `auth.users` trigger;
- `pg_cron` jobs, execution identities, or scheduled worker side effects;
- the full extension inventory and platform configuration;
- the remaining 45 function bodies and their dependency graphs.

The `auth.uid()` function in the fixture is a minimal test shim reading a transaction-local synthetic subject. It is not a JWT verifier and must never be reused by application code or deployed to Supabase.

## Why full parity remains blocked

The repository's migration reconciliation records 17 applied Production migrations without authoritative local SQL sources, and the migration set contains timestamp/content mismatches. A blind replay of the local migration directory is unsafe. The existing Recovery-Test project is known to have different function ACLs, default ACLs, Cron relation, and Auth-trigger wiring; it is not used by this workflow.

Before calling any future run a full ACL parity pass, a separately reviewed manifest must cover exact signature, owner, security mode, search_path, effective API-role ACL, schema USAGE, global and schema-specific default ACL per grantor, extension/version, Auth trigger, and inert Cron identity. Missing evidence is a blocker, not a value to approximate.

## Next phases

1. Run this isolated PostgreSQL 17 smoke workflow and inspect all logs.
2. Extend the disposable fixture only with additional exact Production function bodies and their minimal synthetic dependencies, one reviewed unit at a time.
3. Recover missing migration sources from authoritative artifacts and build a complete schema-only replay set without real user or financial data.
4. Generate a full parity manifest from read-only Production catalog snapshots and compare it to the disposable database.
5. Resolve the owner decision about the future `service_role` function EXECUTE default. The current contract test and proposed hardening SQL still express different target policies; this harness deliberately does not test or change either default.
6. Only after parity and policy review, prepare the exact-signature positive/negative matrix for `anon`, ordinary `authenticated`, synthetic super-admin, and documented service-role callers.
7. Keep the existing remote-database integration gate disabled until the owner separately approves its destination, parity, and activation.

## Current state

These files are reviewable test code only. They do not modify Production or any Supabase project. The existing Recovery-Test project is untouched. No migration, DDL, GRANT/REVOKE, default ACL, Auth trigger, Cron job, Edge Function, wallet, order, or financial row in any persistent database is changed.

## First CI execution result — 2026-11-25

The first PostgreSQL 17 smoke execution completed successfully on the initial harness. A second expanded run then passed the 46-signature ACL metadata contract as well:

- PostgreSQL server: **17.12**.
- Fixture bootstrap: success.
- Exact-signature / SECURITY DEFINER / empty-search_path / ACL contract: success.
- All **46 exact SECURITY DEFINER signatures** and their current anon/authenticated/service_role EXECUTE booleans, constrained search_path, no direct PUBLIC EXECUTE, and schema-USAGE contract: success. The 43 placeholder bodies are inert metadata-only stubs and were never invoked.
- Anonymous caller: rejected by the function-body guard with SQLSTATE `42501`.
- Ordinary authenticated caller: rejected by the function-body guard with SQLSTATE `42501`.
- Synthetic super-admin caller: accepted and returned the JSON report.
- Transaction rollback: completed.
- Post-check: exactly one synthetic super-admin row remained in the disposable database.
- Initial GitHub Actions run IDs: `45597893116` and `45597904032`; both `postgres17-rpc-smoke` jobs and both `unit-tests` jobs passed.
- Expanded 46-signature ACL run: `45598493186`; `postgres17-rpc-smoke` and `unit-tests` passed, and the existing remote-database integration job remained skipped.

This confirms the fixture and the single-RPC behavior test execute on PostgreSQL 17. It does not upgrade the result to full Production parity; all limitations in the scope section above remain in force.


## Source-faithful body expansion — 2026-11-25

The fixture now includes a fourth real Production function body: `public.claim_admin_asset_refresh(text, uuid)`, recovered from authoritative historical source `20261113190000_admin_on_demand_crypto_asset_refresh.sql`.

- The fixture creates only the synthetic `private.admin_asset_refresh_limits` table with RLS enabled.
- The exact return type (`boolean`), SECURITY DEFINER flag, empty search_path, and function-specific service_role-only API ACL are asserted.
- A dedicated transaction-scoped test exercises a successful synthetic super-admin claim, a non-admin denial (`42501`), invalid input (`22023`), and the 30-second duplicate-claim cooldown (`55000`).
- The function is no longer replaced by an inert stub. The fixture now has four real function bodies and 42 inert metadata-only stubs.
- CI run `45600501368` passed all PostgreSQL 17 smoke steps and unit/type-check steps. The remote RPC integration job remained skipped.
- The test transaction rolls back; a post-check confirms the synthetic claim table is empty.

This remains a narrow source-faithful function test, not a full Production-parity Supabase clone. The deployed Edge Function itself is not invoked, and the other 42 stub bodies remain untested.


## Superseding fixture coverage checkpoint — 2026-11-25

The read-only `public.get_admin_market_listings()` body from `20261113181000_show_live_prices_for_curated_assets.sql` is now installed in the disposable PostgreSQL 17 fixture as the fifth real function body. The fixture therefore contains 5 source-backed/reviewed bodies and 41 metadata-only stubs across the 46-signature contract. CI run #313 (run ID `45603853118`) passed: unit/type checks and every PostgreSQL 17 step, including the new role/price-freshness test and post-rollback empty-table checks. The remote `rpc-security-integration` job remained skipped. No Production/Recovery-Test operation, ACL/default ACL change, migration, deploy or merge occurred.


## Superseding fixture coverage checkpoint — exchange discovery RPC — 2026-11-25

The source-backed read-only body `public.get_exchange_discovered_market_assets()` from migration `20261116200009_auto_list_unmatched_iran_exchange_assets.sql` (blob `901f6e3004a1fd51995ea159d840ce5b5b39dbeb`) is now installed in the disposable PostgreSQL 17 fixture. The fixture now contains **6 real bodies + 40 metadata-only stubs** across the exact 46-signature contract.

- The function is SQL, STABLE, SECURITY DEFINER, with an empty search_path and an eight-column TABLE result.
- Its dependencies are synthetic `exchange_asset_observations`, `admin_market_listings`, `crypto_assets`, `demo_trading_pairs`, and `market_prices` tables; RLS is enabled and direct anon table SELECT is absent.
- Role tests cover anon, authenticated and service_role; aggregation across exchanges; ambiguous status; 48-hour, active/status, tokenized-stock, curated-listing and enabled-pair filters; fresh versus stale price behavior; and rollback.
- The source migration explicitly grants anon/authenticated but not service_role, while the reviewed current-state catalog contract records service_role EXECUTE=true. The reason for that effective privilege is unresolved. The disposable fixture reproduces the observed bit with a function-specific test-only grant; no Production ACL/default privilege is changed.
- No financial table or row is involved, and no order/trade/reservation/wallet/balance mutation or external HTTP occurs in this function.
- CI evidence is pending for the code/test commits. The remote RPC integration job remains separate and is not represented by the local PostgreSQL 17 harness.
