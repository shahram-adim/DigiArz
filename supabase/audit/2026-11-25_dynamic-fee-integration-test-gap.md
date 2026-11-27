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

## Confirmed NULL-liquidity validation defect — 2026-11-25

A fresh SELECT-only read of the live Production catalog retrieved the exact current definition of `public.get_demo_trading_fee_rate(text,text)`:

- Definition MD5: `546d80d7105228ed97da26c5ed0c7b7f`; length: 772 bytes.
- Owner: `postgres`; `SECURITY DEFINER`; `STABLE`; empty `search_path`.
- The current guard is `IF p_liquidity_type NOT IN ('maker', 'taker') THEN` and does not explicitly test `p_liquidity_type IS NULL`.
- In PostgreSQL, `NULL NOT IN ('maker','taker')` evaluates to NULL, not TRUE. A PL/pgSQL IF does not enter its branch for NULL. The following CASE chooses the ELSE expression for a NULL comparison, so with a configured enabled fee row the helper returns the taker rate instead of raising `Invalid liquidity type`.

This is a confirmed input-validation defect in the helper. It is **not evidence that the three current trade entrypoints are mispricing normal orders**: the inspected live callers pass explicit non-NULL `'taker'` for market execution and `'maker'` for limit placement/processing. No Production function was invoked to establish this finding; it follows from the SELECT-retrieved function body and PostgreSQL NULL semantics.

### Existing regression assets and CI omission

- The repository already contains `tests/demo-trading-fee-rate-validation.sql`, which explicitly expects NULL to raise `Invalid liquidity type`.
- The current PostgreSQL 17 workflow does **not** execute that file. It executes `tests/rpc-security-demo-fee-rate.integration.sql`, which tests an unsupported non-NULL liquidity string but does not test NULL.
- The source-backed CI fixture therefore does not currently catch this defect.
- A review-only correction already exists at `supabase/drafts/2026-11-25_fix_demo_trading_fee_rate_null_validation.sql`; it adds `p_liquidity_type IS NULL OR` while preserving the signature, return type, volatility, security mode and empty search_path. It is not a migration and has not been applied.

### Disposition

1. Keep the proposed correction as a draft until a PostgreSQL 17 isolated test demonstrates NULL rejection and maker/taker behavior remains unchanged.
2. Add the NULL case to the ephemeral CI path (or execute the existing validation script there) only after ensuring its fixture contains the exact reviewed helper body and synthetic enabled fee row.
3. Do not invoke the helper or any trading function in Production as a test. Do not apply the draft SQL, alter ACLs, or change any order/worker/Cron behavior without explicit owner approval.
4. Record the defect as limited to NULL liquidity-type validation; do not claim a live trading-fee accounting defect without further evidence.

No Production mutation, function invocation, migration, ACL change, CI workflow change, merge, deployment, Cron change, or cost was incurred by this inspection.

## PostgreSQL 17 regression result — 2026-11-25

The isolated regression was added as `tests/demo-trading-fee-rate-null-regression.pg17.sql` and wired into `.github/workflows/persian-asset-name-tests.yml`.

- Test commit: `a1a65229c2b1b6d69a0e0755f7477a193bdf73a1`.
- Workflow commit: `3078043b24b4788fe21ce7afee6b79a8bca81c12`.
- GitHub Actions run: `45669028813` — completed successfully.
- `postgres17-rpc-smoke`: success; the new step “Reproduce and verify NULL liquidity-type fee-rate fix in disposable PostgreSQL 17” passed.
- `unit-tests`: success.
- `rpc-security-integration`: skipped by its existing opt-in guard; no remote test project was contacted.

The regression demonstrates the NULL fall-through in a synthetic transaction, applies the proposed explicit NULL guard in that same disposable transaction, verifies Maker/Taker rates remain distinct, verifies invalid liquidity values and disabled fee rows are rejected, and rolls back all changes.

**Scope limitation:** the test reconstructs the reviewed helper definition in the isolated PostgreSQL fixture; it is not a live Production invocation and does not validate the three full trading entrypoints, partial fills, reservation recalculation, cancellation, or two-user RLS. The 46-signature fixture remains 12 source-backed/reviewed function bodies plus 34 inert metadata stubs. The fix remains unapplied to Production and is not a migration.
