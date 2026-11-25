# Production security role-test gap — 2026-11-25

## Evidence checked

- PR #63 remains an open Draft; this note is review-only and does not request merge.
- Reviewed the workflow run associated with the current audit branch HEAD `c21ac67990ee8ad468b4260ad7b3b160d6b22c90`: run `45643794201` (#2023), conclusion `success`.
- The workflow executed `node --test tests/*.test.js`: 88 tests passed, 0 failed, 0 skipped.
- The 88 Node tests include static assertions for the 46-function SECURITY DEFINER manifest, the two-function anon allowlist, admin guard text, RLS/grant snapshots, view security-invoker metadata, 27 relation references, and the 17 missing-migration evidence dossiers.
- The same workflow ran PostgreSQL 17 disposable-database arithmetic, schema-widening, trading lifecycle, and two-session race checks.
- In the inspected run/job step summaries and log output, no dedicated runtime role-matrix test was found that executes the audited Production RPCs and table/view operations under `anon`, ordinary `authenticated`, super-admin `authenticated`, and `service_role` identities. This is a coverage gap in the evidence reviewed, not proof that an access-control vulnerability exists.

## Required next test layer

Add a separate, explicitly isolated PostgreSQL 17/Supabase-compatible role harness. It must never connect to the Production project.

1. **ACL / EXECUTE matrix**
   - Verify `anon` can execute only the two intentionally public market-metadata SECURITY DEFINER RPCs.
   - Verify ordinary `authenticated` cannot execute admin-only RPCs or worker-only RPCs.
   - Verify a normal authenticated user cannot pass super-admin checks by changing client-supplied metadata.
   - Verify service-role-only worker RPCs reject anon and ordinary authenticated callers.
   - Verify the expected service-role worker calls remain permitted in the disposable fixture.

2. **RLS isolation**
   - Seed two synthetic users and synthetic rows only.
   - Under ordinary authenticated user A, verify own-row visibility and denied reads/writes against user B's wallet, balances, orders, trades, reservations, conditional orders, and transactions.
   - Verify anon sees only explicitly public market metadata; no private account or financial rows.
   - Verify user-owned review/report policies enforce ownership and active-account requirements where applicable.

3. **SECURITY DEFINER execution**
   - Invoke representative guarded admin RPCs with no JWT subject, ordinary user A, and the designated synthetic super-admin.
   - Assert fail-closed behavior for the first two and the intended permission boundary for the synthetic super-admin.
   - Check fixed function owner, `search_path`, ACL, and function identity in the test database against the captured manifest.
   - Test the two public market RPCs for output-column allowlisting; assert no user identity, wallet, balance, order, trade, reservation, or transaction fields are returned.

4. **Least-privilege hardening candidates**
   - Confirm effective denial for anon writes to `coin_reviews` despite excess table grants.
   - Confirm anon cannot read `conditional_orders` under the captured policies.
   - Confirm the two `security_invoker` views cannot bypass underlying table grants.
   - Keep any proposed GRANT/REVOKE change separate from the test harness and require owner approval before any Production change.

## Harness acceptance gates

- Bootstrap from reviewed, authoritative SQL sources; do not infer or synthesize missing historical migrations.
- Record every fixture-only stub and prove it cannot weaken the permission boundary being tested.
- Assert the database target is disposable before executing any setup or cleanup.
- Use synthetic identities and rows only; no Production credentials, user records, wallet rows, or financial rows.
- Fail closed if the database URL points to the known Production project/ref or if environment identity cannot be established.
- Preserve all existing order-engine cron jobs; do not pause, throttle, reschedule, or replay queues.
- CI must show the role matrix test names and explicit pass/fail counts, separate from the existing arithmetic/lifecycle/race suite.

## Current safety state

- This note is documentation only.
- No Production SQL, migration, grant, policy, function, view, data, cron, queue, Edge Function, deployment, or financial row was changed.
- No migration source was reconstructed; the 17 missing canonical SQL sources remain unrecovered.
- PR #63 remains Draft and unmerged. No `db push` or Merge is authorized by this work.
