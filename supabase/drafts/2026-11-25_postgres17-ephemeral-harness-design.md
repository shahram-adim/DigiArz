# DigiArz — Disposable PostgreSQL 17 RPC security harness

**Date:** 2026-11-25  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Purpose:** isolated CI smoke test without a new Supabase project or database branch.

## What this harness does

The workflow `.github/workflows/rpc-security-postgres17-smoke.yml` starts a disposable `postgres:17` service container inside the GitHub Actions job. It creates synthetic API roles and one synthetic super-admin identity, installs a test-only `auth.uid()` shim, and exercises the current Production body of the read-only `public.admin_exchange_asset_sync_report()` function against empty synthetic reporting tables.

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

This is a **PostgreSQL 17 behavior smoke harness**, not a complete Supabase or Production-parity clone. It does not reproduce:

- the full 46-signature SECURITY DEFINER catalog;
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

The first PostgreSQL 17 smoke execution completed successfully on the harness code commit:

- PostgreSQL server: **17.12**.
- Fixture bootstrap: success.
- Exact-signature / SECURITY DEFINER / empty-search_path / ACL contract: success.
- Anonymous caller: rejected by the function-body guard with SQLSTATE `42501`.
- Ordinary authenticated caller: rejected by the function-body guard with SQLSTATE `42501`.
- Synthetic super-admin caller: accepted and returned the JSON report.
- Transaction rollback: completed.
- Post-check: exactly one synthetic super-admin row remained in the disposable database.
- GitHub Actions run IDs: `45597893116` and `45597904032`; both `postgres17-rpc-smoke` jobs and both `unit-tests` jobs passed. The existing remote-database integration job remained skipped.

This confirms the fixture and the single-RPC behavior test execute on PostgreSQL 17. It does not upgrade the result to full Production parity; all limitations in the scope section above remain in force.
