# DigiArz Demo Derivatives — Implementation Plan

Date: 2026-11-18
Branch: `feat/demo-derivatives-trading`
Spec: `docs/superpowers/specs/2026-11-18-demo-derivatives-trading-design.md`

## Phase 0 — Baseline and protection
- [x] Re-read the current `main` app entrypoint and navigation implementation.
- [x] Confirm existing Spot RPC and tables; preserve the existing spot path.
- [x] Confirm Supabase project health, PostgreSQL version, exposed public tables and migration history.
- [x] Create a dedicated feature branch from the current main commit.
- [x] Record the derivatives product and safety design.
- [ ] Reconcile every Production migration and existing trading function, grants, RLS and cron definitions with repository history. The current production migration history is not yet fully reconciled.
- [ ] Confirm no hidden/legacy derivatives tables or functions exist before creating any new object.

## Phase 1 — Domain model and formula tests
- [ ] Specify and independently test futures notional, initial margin, maintenance margin, unrealized/realized PnL, fee reserve and liquidation price.
- [x] Specify and unit-test the initial USDT futures cross-risk aggregation helper (ledger-derived account cash + all cross positions + liabilities + close-fee reserve + stale-price fail-closed).
- [ ] Specify cross risk for Margin Spot with supported collateral assets and conservative haircuts.
- [ ] Specify and test margin borrow/repay, accrued interest, short sale proceeds and debt closeout.
- [ ] Specify funding-rate calculation, settlement interval, caps and idempotency.
- [x] Add disposable PostgreSQL fixture coverage for ledger-derived Futures cash (positive transfer, zero-balance account, absence of mutable cash columns, and RLS on the projection view); execution on latest HEAD remains pending.
- [ ] Add disposable PostgreSQL fixtures for exact arithmetic, rounding, negative balances, stale prices and liquidation boundaries, including the account-level cross-risk SQL projection.
- [x] Add pure exact-decimal Available Margin unit tests for open/partially-filled limit orders and reduce-only quantity reservations (PostgreSQL reservation/race tests remain pending).
- [ ] Add concurrent-session fixtures for order duplication, account locking, partial close and liquidation races.

## Phase 2 — Backend implementation (feature branch only)
- [ ] Add separate derivative accounts, orders, positions, fills, loans, funding, risk events and immutable ledger schema.
- [ ] Add RLS policies and least-privilege grants.
- [ ] Add fixed-search_path SECURITY DEFINER RPCs for all writes.
- [ ] Add idempotency and row-version checks.
- [ ] Add a deterministic settlement/maintenance worker design with bounded batches, retries and stale-price safeguards.
- [ ] Test migrations against a disposable PostgreSQL 17 database before any deployment discussion.

## Phase 3 — User interface
- [ ] Add a Derivatives area without changing existing Spot controls or RPC behavior.
- [ ] Build Futures terminal: pair, side, order type, leverage, margin mode, preview and position management.
- [ ] Build Margin terminal: borrow/repay, long/short, collateral, debt and interest.
- [ ] Build open positions, open derivative orders, fills, funding/interest and ledger history.
- [ ] Add clear warnings, risk meters, liquidation estimates and stale-price states.
- [ ] Verify Persian RTL, 360px Android layout, dark/light theme and keyboard/accessibility behavior.

## Phase 4 — End-to-end and Android validation
- [ ] Run all existing repository tests unchanged.
- [ ] Run new unit, SQL integration, concurrency, RLS and retry/recovery suites.
- [ ] Run app syntax and browser-level smoke tests.
- [ ] Confirm web build and Android APK CI artifacts.
- [ ] Test installation and real-device flows when the user can install the new build.

## Phase 5 — Review and controlled release
- [ ] Review security, accounting, performance and migration drift.
- [ ] Prepare a production deployment plan with exact migration versions and rollback/forward-fix strategy.
- [ ] Present the completed feature branch and test evidence for user review.
- [ ] Deploy only after explicit approval; no automatic Production migration or PR merge.

## Current checkpoint
Phase 0 product/design baseline is recorded. The Futures ledger accounting contract is specified in `docs/superpowers/specs/2026-11-18-futures-ledger-accounting.md`; the draft schema now derives Futures cash from an immutable ledger view. A pure exact-decimal `futuresAvailableMarginSnapshot()` helper and nine Node unit tests now cover cross Futures equity, position/order initial margin, open and partially filled Limit reservations, Reduce-only quantity allocation, stale marks, and conservative rounding. These tests have not yet been executed on CI or PostgreSQL. No runtime RPC, Supabase Production schema, migration, cron, function, balance, order or Production data has been changed. Next task is to obtain a real test run, add disposable PostgreSQL reservation/cancellation/partial-fill fixtures, and only then design account-locked idempotent RPCs.


## Checkpoint — cross-only order validation
- [x] Tightened `futuresAvailableMarginSnapshot()`: active orders must be Futures and `marginMode='cross'`; isolated and Margin Spot orders are rejected rather than mixed into the Cross Futures account snapshot.
- [x] Updated all Available Margin order fixtures with explicit cross margin mode and added a negative test for isolated and Margin Spot orders.
- [ ] Node and PostgreSQL 17 tests remain unexecuted/unverified for this checkpoint. The current execution container has Node 22.16.0 but no repository checkout and no `psql` binary; GitHub Actions run visibility remains incomplete.
- [ ] Before relying on order previews, review the short-limit reservation price policy and enforce fill-time margin checks in the eventual account-locked RPC.
- Pre-documentation GitHub comparison for commit `0f4183e39a1f8da8b47c77ba08dff500e538d7db`: 59 ahead / 1 behind `main` (`diverged`); PR #12 remains Draft. No merge/rebase; Actions run/status unverified.
- No Supabase Production schema, migration, RPC, cron, balances, orders or data were changed.


## Checkpoint: syntax failure discovered and corrected (2026-11-18)
- GitHub Actions run `44258864323` for the preceding HEAD failed in the Node test step because a literal stray `\\n` token appeared at line 123 of `src/derivatives-math.js`.
- The token was removed in commit `4020813ede6a3fbcaff1db43e92e979ae694c664`.
- The failing run discovered 37 tests; 35 passed and two derivative test files failed to load due to the same syntax error. PostgreSQL steps were skipped after the Node step failed.
- The correction is not yet validated. Inspect the new Actions run and its logs before proceeding to PostgreSQL reservation lifecycle fixtures or RPC implementation.


## CI validation checkpoint (2026-11-18)
- Fixed stray literal escape token in `src/derivatives-math.js` in commit `4020813ede6a3fbcaff1db43e92e979ae694c664`.
- GitHub Actions completed successfully for code commit `4020813...` (run `44259730430`), status-doc commit `4e48a2d...` (run `44259762686`), and plan-doc commit `e95c055...` (run `44259768302`).
- Verified Node TAP output: 58 tests, 58 passed, 0 failed. Disposable PostgreSQL 17 job also completed successfully, including derivative schema integration and arithmetic/regression scripts.
- Expected ERROR lines in negative SQL tests were asserted and did not fail the workflow.
- Remaining gap: SQL tests for Available Margin order reserve/release, cancel, partial fills, reduce-only allocation and concurrent account locking are not yet authored/verified. Do not activate derivatives UI or production RPCs.


## Checkpoint — explicit order direction and reduce-only contract
- [x] Added an explicit `side` field (`buy`/`sell`) to derivative orders, separate from `position_side` (`long`/`short`).
- [x] Added a database CHECK invariant: Long opens/increases only with Buy non-reduce; Long reduces only with Sell reduce-only; Short opens/increases only with Sell non-reduce; Short reduces only with Buy reduce-only.
- [x] Added `side` to fill records and extended the composite FK so a fill's execution direction must match its source order.
- [x] Added PostgreSQL integration assertions rejecting ambiguous Sell-Long and Buy-Short non-reduce orders.
- [ ] Run disposable PostgreSQL 17 integration tests on this checkpoint; schema/test changes are not validated until CI completes.
- [ ] Next: design deterministic reduce-only allocation across multiple orders for the same account/symbol/position side, then test cancel release, partial fill and concurrent placement under account-first lock.
- No RPC or UI order path is activated; no Supabase Production changes.


## Checkpoint — Reduce-only reservation allocation design
- [x] Defined one open position per account/product/symbol/position side as the allocation target; a partial unique index is required before order RPCs.
- [x] Defined placement validation using position quantity minus the sum of active Reduce-only remaining quantities, all under the account-first `FOR UPDATE` lock.
- [x] Defined Market Reduce-only as immediate fill-or-reject against unreserved quantity; no resting Market order.
- [x] Defined cancel/expire/reject as reservation release without a ledger cash movement.
- [x] Defined partial fills to reduce order remaining quantity and position quantity by the same exact amount in one transaction.
- [x] Defined deterministic reconciliation for external position reductions: cancel newest active Reduce-only orders first until reservations fit the remaining position.
- [ ] Implement the partial unique index and SQL fixtures for duplicate open positions, reserve, cancel, partial fill, market reduce-only, over-allocation and two-session races.
- [ ] Implement account-locked idempotent RPCs only after those SQL tests pass.
- No UI activation or Production database changes.


## Checkpoint — unique open position and atomic Market invariant
- [x] Added a partial unique index allowing at most one open position per account/product/symbol/position side (Long and Short remain independent).
- [x] Tightened Market order CHECK constraint: either fully filled in the same transaction or rejected with zero fill; no resting/partial Market order.
- [x] Updated the schema fixture to model a fully filled Market order.
- [x] Added PostgreSQL negative tests for duplicate open positions and pending Market orders.
- [ ] Await GitHub Actions on the resulting HEAD and inspect all PostgreSQL logs before marking tests passed.
- [ ] Next: add lifecycle functions/tests for Limit reserve, cancel release, partial fill, reduce-only allocation and two-session account-lock races. No RPC/UI activation or Production deployment.

- [x] Added a partial index over active Reduce-only orders keyed by account/product/symbol/position side and newest-first ordering; schema integration now asserts both the position uniqueness and Reduce-only indexes exist.
