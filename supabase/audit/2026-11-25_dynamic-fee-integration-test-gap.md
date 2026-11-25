# Dynamic trading-fee integration test gap — 2026-11-25

## Scope and safety

This is a review-only finding for PR #62. It does not change a database, migration, function, ACL, policy, cron job, order, reservation, wallet, or balance. No Production RPC was invoked. No migration was replayed. The only PostgreSQL tests referenced below are disposable CI fixtures.

## Evidence rechecked

- PR #62 head before this note: `658a058345dffc96f970ff61cfc1ca09f286e475`; PR remains open and Draft.
- Latest PR #62 CI run: [45667158663](https://github.com/shahram-adim/DigiArz/actions/runs/45667158663). The PostgreSQL 17 smoke job and unit/type-check job passed; remote integration remained intentionally skipped.
- The smoke job's fee-related step is named **“Test source-backed demo fee-rate RPC with synthetic fee rows”**. It validates the fee-rate helper with synthetic rows, not the complete Market/Limit accounting path.
- Existing repository integration fixtures on `main` include:
  - `supabase/tests/exact_decimal_market_limit_entrypoints.sql` (blob `3d324573b8304cf1820a5be4bc958a50130b1551`)
  - `supabase/tests/exact_decimal_limit_rounding_buffer.sql` (blob `3914fdf3ad1d159ff9e7142ba38e1d18ce42836a`)
- Both fixtures contain fixed 0.1% fee expectations (for example, the Market wallet expectation and Limit reserve arithmetic). They therefore do not independently prove that the current dynamic fee helper's returned rate is propagated consistently through all three current financial entrypoints.
- The live Production catalog comparison recorded the current function fingerprints and confirmed one helper call in each of `execute_demo_trade`, `place_limit_order`, and `process_limit_orders`. This is structural evidence only; it is not an execution test.
- Supabase development-branch listing returned no branches. This does not establish whether provider-managed backups exist; no restore, backup creation, or paid action was attempted.

## Finding

**The helper-level fee test is not equivalent to end-to-end dynamic-fee accounting coverage.** The existing fixed-rate fixtures are useful historical regression tests, but their hard-coded 0.001 expectations must not be treated as proof of the current dynamic-fee behavior.

No production defect is inferred from this coverage gap.

## Required isolated test matrix

Before considering the dynamic-fee path adequately tested, add source-faithful PostgreSQL 17 tests in a disposable database for:

1. Market buy and sell: assert the selected taker rate is reflected identically in fee amount, wallet settlement, transaction ledger, and returned fee metadata.
2. Limit buy and sell placement: assert maker-rate calculation, quote/base reservation, insufficient-balance rejection, and no partial writes on rejection.
3. Limit worker: test repeated partial fills, per-fill fee calculation, residual reservation recalculation, final release, and reconciliation of consumed + released against reserved amount.
4. Cancellation: verify only the remaining valid reservation is released and the accounting rows reconcile.
5. Fee configuration boundaries: missing, disabled, duplicate/ambiguous, and changed fee rows. Expected fallback/fail-closed behavior must be derived from the actual helper source and explicitly asserted; do not invent policy.
6. Fee-rate timing: document and test whether an order's maker rate is fixed at placement or re-read at fill time. This is an unresolved product/accounting semantic, not an assumption.
7. Two-user isolation: ensure no user can observe or mutate another user's wallet, asset balance, order, trade, reservation, or transaction in the isolated role/RLS matrix.

Use non-default synthetic rates (not only 0.001) so the tests can detect accidental hard-coding. Keep the existing concurrency locks and worker schedule untouched.

## Release gate

- Do not run these fixtures against Production.
- Do not apply the recovered dynamic-rewrite DO blocks or replay historical migrations.
- Keep PR #62 Draft until source-faithful end-to-end tests and the missing RLS cases are complete.
- Any Production migration, function change, ACL change, cron change, or release remains subject to explicit owner approval.
