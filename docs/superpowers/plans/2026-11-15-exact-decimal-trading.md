# DigiArz Exact Decimal Trading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve base-asset amounts and execution prices at up to 18 fractional digits across Market, Limit, Stop-Limit, and conditional exits while keeping USDT ledger settlement exact at 8 fractional digits.

**Architecture:** Implement a browser-side decimal-string utility and a coordinated PostgreSQL precision/accounting update. Keep order-critical values as decimal strings in the UI and PostgreSQL numeric values in RPCs; quantize quote-currency values once using PostgreSQL `round(value, 8)` and reuse those values throughout each atomic ledger update. Release only after isolated tests and compatibility checks; production rollout requires separate explicit authorization.

**Tech Stack:** Existing vanilla JavaScript in `index.html`; PostgreSQL/Supabase SQL migrations; existing GitHub Actions and repository test conventions (inspect before adding tooling). No new runtime dependency unless an existing constraint makes it unavoidable.

**Spec:** `docs/superpowers/specs/2026-11-15-exact-decimal-trading-design.md`

## Global Constraints

- Base-asset quantities and execution/limit/trigger prices support at most 18 fractional digits.
- USDT wallet and transaction settlement remains at 8 fractional digits in this phase.
- Use exact decimal strings and integer-coefficient/scale arithmetic (BigInt) for browser order-critical calculations; do not route authoritative values through JavaScript `Number`.
- Preserve authentication, active-account checks, enabled-pair checks, RLS, ownership, freshness checks, lock ordering, reservations, grants, and atomic transactions.
- Keep the current 12 enabled trading pairs unchanged.
- No Production test trades; do not insert/update/delete Production orders, trades, wallets, asset balances, reservations, or transactions for testing.
- Do not create a new Supabase project, paid infrastructure, or external service.
- Do not run Production DDL until separate explicit rollout authorization is given after isolated tests and lock/rollback assessment.
- Add tests first, demonstrate failure, implement in small commits, and read back every committed change.

## Review Focus

- Values with 18 fractional digits and leading/trailing zeros must round-trip without loss; test parser, formatter, RPC payload, and display.
- Partial fills must preserve `amount = filled_amount + remaining_amount` exactly through repeated 25% cycles and final residual; test the 25% residual and final-fill path.
- Quote rounding half-way boundaries must use PostgreSQL `round(value, 8)` consistently; test just-below, exact-half, and just-above cases.
- Invalid precision, excessive integer range, zero, negative, exponent notation, whitespace, and malformed decimal strings must be rejected consistently at browser and RPC boundaries.
- Buy/sell fee, reserve, release, cancellation, Stop-Limit parent/child handoff, and concurrent worker/cancel paths must never double-consume or strand a valid reservation; exercise only in an isolated disposable database.

---

### Task 1: Read-only numeric range and caller inventory

**Files:**
- Read: `docs/superpowers/specs/2026-11-15-exact-decimal-trading-design.md`
- Read: `index.html`
- Read: relevant SQL migrations under `supabase/migrations/`
- Create: `docs/superpowers/reports/2026-11-15-exact-decimal-preflight.md`

**Interfaces:**
- Produces the approved numeric typmods, maximum integer digits, RPC caller inventory, and list of functions/columns to change. No DDL or data writes.

- [ ] **Step 1: Scan existing stored values read-only** for maximum integer digits, fractional scale, nulls, and out-of-range values in `orders.amount/price/filled_amount/remaining_amount`, `trades.amount/price`, `asset_balances.balance`, reservation fields, and conditional-order trigger/limit/amount fields.
- [ ] **Step 2: Inventory all trading RPC definitions and callers** for Market, Limit, Stop-Limit, conditional exits, cancellation, and worker processing; record every function signature, grant, and browser call site.
- [ ] **Step 3: Confirm typmods and integer caps** from the scan; choose the smallest safe precision that supports 18 fractional digits and the existing documented amount bounds. Do not guess or silently truncate.
- [ ] **Step 4: Record compatibility callers** beyond the browser, if any, and define whether decimal-string arguments are already accepted by each RPC.
- [ ] **Step 5: Write and review the preflight report**; confirm no index, constraint, generated column, or function dependency is missed.

### Task 2: Browser exact-decimal utility

**Files:**
- Create: `src/decimal.js` (or the repository's established equivalent after checking its current structure)
- Modify: `index.html`
- Test: `tests/decimal.test.js` (or existing test convention)

**Interfaces:**
- Produces pure functions: `parseDecimal(text, { maxFractionDigits, maxIntegerDigits, allowNegative })`, `compareDecimal(a, b)`, `addDecimal(a, b, scale)`, `subtractDecimal(a, b, scale)`, `multiplyDecimal(a, b, scale, rounding)`, `divideDecimal(a, b, scale, rounding)`, and `formatDecimal(value, options)`. Return canonical decimal strings; reject invalid input rather than coercing it.

- [ ] **Step 1: Add failing unit tests** for zero, signs, leading/trailing zeros, 18 fractional digits, max integer digits, malformed strings, exponent notation, whitespace policy, and half-way rounding.
- [ ] **Step 2: Run the focused test suite** and verify the new tests fail for the intended missing functions/behaviors.
- [ ] **Step 3: Implement the utility** using BigInt coefficient/scale arithmetic only; do not use `Number`, `parseFloat`, or `toFixed` for order-critical values.
- [ ] **Step 4: Add property-style invariants** for compare symmetry, add/subtract reversibility at a common scale, and canonical parse/format round trips.
- [ ] **Step 5: Run tests and commit** the utility independently.

### Task 3: Browser trading-flow integration

**Files:**
- Modify: `index.html`
- Test: browser/unit tests covering order forms, estimate paths, order book, open orders, history, and dashboard asset values.

**Interfaces:**
- Consumes Task 2 decimal-string API.
- Produces exact string RPC arguments for Market, Limit, Stop-Limit, and conditional exits; displays stored 18-digit amounts/prices without silent truncation.

- [ ] **Step 1: Add failing tests** proving 18-digit amounts/prices survive input, validation, estimate, and RPC argument construction for buy and sell.
- [ ] **Step 2: Audit all order-critical `Number`/`parseFloat`/`toFixed` call sites** and classify non-authoritative chart/analytics conversions separately.
- [ ] **Step 3: Replace order-critical parsing, arithmetic, and formatting** with Task 2 functions while preserving the existing Persian/mobile input UX.
- [ ] **Step 4: Update order book, open-order, trade history, reservation display, and dashboard asset formatters** to show supported precision without changing server values.
- [ ] **Step 5: Verify generated RPC payloads are decimal strings** and that invalid scale/range is rejected before network calls.
- [ ] **Step 6: Run static script parsing, unique-ID checks, focused tests, and Android viewport/input checks; commit the browser integration.**

### Task 4: PostgreSQL schema precision migration

**Files:**
- Create: `supabase/migrations/<timestamp>_widen_trading_asset_precision.sql`
- Test: isolated database migration tests

**Interfaces:**
- Consumes Task 1's confirmed typmods and dependency inventory.
- Produces 18-scale numeric storage for base amounts and prices in orders/trades/asset balances and relevant conditional/reservation quantity fields, while leaving USDT wallet/transaction settlement columns at scale 8.

- [ ] **Step 1: Add migration assertions/tests** for target column types, preserved constraints, and pre/post data equivalence.
- [ ] **Step 2: Run migration tests against an isolated disposable PostgreSQL/Supabase-compatible database**; Production is not a test environment.
- [ ] **Step 3: Implement explicit `ALTER COLUMN TYPE numeric(p,18)` statements** only for columns approved by Task 1; preserve all existing constraints, defaults, indexes, grants, and policies.
- [ ] **Step 4: Verify existing values are unchanged numerically** and all constraints remain present after migration.
- [ ] **Step 5: Record table size, lock/rewrite behavior, expected duration, backup/restore plan, and rollback procedure; commit the migration without applying it to Production.**

### Task 5: PostgreSQL RPC precision and accounting update

**Files:**
- Create: `supabase/migrations/<timestamp>_exact_decimal_trading_rpc_accounting.sql`
- Test: isolated SQL/pgTAP or equivalent RPC integration tests

**Interfaces:**
- Consumes Task 1's caller inventory and Task 4's schema target.
- Updates `execute_demo_trade`, `place_limit_order`, `process_limit_orders`, `place_stop_limit_order`, `process_stop_limit_orders`, and applicable conditional-exit RPCs without changing their public security boundaries.

- [ ] **Step 1: Add failing SQL tests** for 18-digit acceptance, 19-digit rejection, integer-range rejection, authentication, inactive account, disabled pair, and stale price.
- [ ] **Step 2: Add failing accounting tests** for `round(value, 8)` half-way boundaries and identical quantized quote values across wallet, transaction, reservation consumption, and remaining reserve.
- [ ] **Step 3: Update every RPC boundary** to validate non-null positive values, 18 fractional digits, and the Task 1 integer cap before writes.
- [ ] **Step 4: Quantize USDT gross/fee/net once per execution** with `round(value, 8)`; reuse those exact variables for every related ledger write and reserve calculation.
- [ ] **Step 5: Keep partial-fill quantities at 18 digits** and make the final fill consume the exact remaining amount; preserve the 25%-per-cycle cap for non-final fills.
- [ ] **Step 6: Preserve security and concurrency behavior**: `auth.uid()`, active-account checks, enabled-pair checks, freshness checks, SECURITY DEFINER/search_path settings, grants, row locks, advisory locks, SKIP LOCKED, ownership checks, and atomic cancellation/reservation logic.
- [ ] **Step 7: Run isolated SQL/RPC tests** including Market buy/sell, repeated Limit partial fills, final residual fill, Stop-Limit trigger-to-child handoff, conditional exits, cancellation, concurrent worker/cancel, and no-negative-balance/reservation invariants.
- [ ] **Step 8: Commit the SQL migration only after all isolated tests pass; do not apply it to Production.**

### Task 6: Compatibility, release verification, and handoff

**Files:**
- Modify: `index.html` only if compatibility findings require it
- Create: `docs/superpowers/reports/2026-11-15-exact-decimal-release-checklist.md`

**Interfaces:**
- Consumes Tasks 1–5.
- Produces a release checklist and explicit go/no-go recommendation; no Production rollout without a separate authorization.

- [ ] **Step 1: Verify old-client compatibility** and define a safe deployment order so older clients cannot submit values that the database rejects or misinterprets.
- [ ] **Step 2: Run all unit, browser, static, migration, RPC, and concurrency tests** in isolated environments.
- [ ] **Step 3: Verify current 12 enabled pairs remain unchanged** and no Production financial rows were used as test fixtures.
- [ ] **Step 4: Review migration locks, table rewrite, backup/restore, rollback, and deployment sequencing.**
- [ ] **Step 5: Publish the release checklist with every unresolved blocker clearly marked.**
- [ ] **Step 6: Stop before Production DDL/deployment and request separate explicit authorization from the owner.**

## Execution blockers and gates

- The connected Supabase account currently exposes only the Production DigiArz project. Full database lifecycle tests cannot be run there. Do not create another Supabase project or use Production rows as fixtures; use an approved isolated test environment if one becomes available, otherwise keep database integration and release blocked.
- The plan does not authorize any Production migration, deployment, order placement, balance mutation, or pair activation.
- If preflight finds values that do not fit the proposed numeric typmods, stop and revise the target types before writing the migration.
