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
- [x] Specify and unit-test the initial USDT futures cross-risk aggregation helper (ledger-derived account cash + all cross positions + liabilities + close-fee reserve + stale-price fail-closed).\n- [ ] Specify cross risk for Margin Spot with supported collateral assets and conservative haircuts.
- [ ] Specify and test margin borrow/repay, accrued interest, short sale proceeds and debt closeout.
- [ ] Specify funding-rate calculation, settlement interval, caps and idempotency.
- [ ] Add disposable PostgreSQL fixtures for exact arithmetic, rounding, negative balances, stale prices and liquidation boundaries, including the ledger-derived futures cash projection and account-level cross-risk SQL projection.\n- [ ] Add exact-decimal Available Margin tests for open/partially-filled limit orders and reduce-only quantity reservations.
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
Phase 0 product/design baseline is recorded. No runtime code, Supabase schema, migrations, cron, functions, balances, orders or Production data have been changed. Next task is the authoritative read-only schema/function/grant/RLS/cron reconciliation, then formula and disposable-fixture tests.
