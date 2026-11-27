# Dynamic trading-function rewrite review — 2026-11-25

## Status and scope

Review-only static analysis of the three dynamic rewrite blocks in recovered Production migration `20261113153808`, sourced from the byte-verified historical migration body. This document is not executable SQL and does not authorize replay, function replacement, migration push, or Production changes.

Targets:
- `public.execute_demo_trade(text,text,numeric,numeric)`
- `public.place_limit_order(text,text,numeric,numeric)`
- `public.process_limit_orders()`

The migration creates `public.get_demo_trading_fee_rate(text,text)` immediately before these blocks. That helper reads `public.demo_trading_fees`, validates liquidity type, filters enabled quote assets, and raises when no fee configuration exists. It is declared STABLE SECURITY DEFINER with an empty search_path; the migration revokes execution from PUBLIC/anon/authenticated and then grants it to authenticated. The three rewritten functions call it for USDT taker/maker fees.

## Static review of each rewrite

### 1. execute_demo_trade

Historical precondition checked:
- The block requires the substring `v_fee_rate numeric := 0.001;` to occur at least once in the fetched function definition.

Text transformations:
- Replaces every occurrence of that declaration with `v_fee_rate numeric;`.
- Replaces every occurrence of `v_gross := round(p_amount * v_price, 8);` with a fee-helper assignment followed by the original gross calculation.
- Executes the resulting definition.

Findings:
- The guard does not check that either replacement anchor occurs exactly once.
- The gross-calculation anchor is not independently required; if it is absent, the fee variable's initialization can be removed without inserting the replacement assignment.
- No post-transform assertion checks that the expected helper call exists exactly once, that the old literal is absent, or that the resulting definition preserves the original signature, return type, security mode, owner, configuration, and unrelated body text.
- Because `replace` replaces all occurrences, duplicate anchors would all be rewritten.

Potential impact (conditional on the unavailable live before-definition): an uninitialized fee variable can propagate NULL into fee calculations or fail later constraints; repeated anchors can inject repeated helper calls. Exact runtime effect is not established without the pre-migration function definition and schema constraints.

### 2. place_limit_order

Historical precondition checked:
- The block requires `v_required_amount := p_amount * p_limit_price * 1.001;` to occur at least once.

Text transformations:
- Adds `v_fee_rate numeric;` by replacing `v_order_id uuid;`.
- Inserts a maker-fee helper call before `IF v_side = 'buy' THEN`.
- Replaces the hard-coded 1.001 reservation multiplier with `(1 + v_fee_rate)`.
- Replaces the JSON fee literal `'fee_rate', 0.001,` with the variable.

Findings:
- The guard does not validate the declaration anchor, the side-branch anchor, or the JSON fee anchor.
- It does not assert exactly one occurrence for any anchor or validate that every replacement changed the body.
- If the declaration anchor is absent, the inserted assignment may refer to an undeclared variable and fail function compilation.
- If the side-branch anchor is absent while the reservation expression is replaced, `v_fee_rate` may remain NULL; if the reservation anchor is absent, the hard-coded reserve calculation can remain while metadata reports a dynamic fee.
- No post-transform check proves that reservation arithmetic and persisted order metadata use the same rate.

Potential impact: failed function replacement, incorrect/NULL reservation calculation, or mismatch between reserved funds and recorded fee metadata. These are static conditional risks, not claims that Production currently exhibits them.

### 3. process_limit_orders

Historical precondition checked:
- The block requires `v_fee := v_gross * 0.001;` to occur at least once.

Text transformations:
- Adds `v_fee_rate numeric;` by replacing `v_fee numeric;`.
- Inserts a maker-fee helper call before the fee calculation.
- Replaces the remaining-reservation multiplier `v_new_remaining * v_order.price * 1.001;`.
- Replaces JSON fee metadata literal `'fee_rate', 0.001`.

Findings:
- The guard checks only the fee-calculation anchor; declaration, remaining-reservation, and JSON anchors are unchecked.
- No exact occurrence counts or post-transform assertions exist.
- If the declaration anchor is absent, the generated body can fail compilation.
- If the remaining-reservation anchor is absent, fills may use the configured maker rate while the remaining reservation continues using the historical hard-coded 0.1% multiplier.
- If the JSON anchor is absent, stored metadata can disagree with the actual fee rate.
- The block does not independently assert that the helper call is placed inside the intended per-order execution scope or that it is evaluated consistently for each fill.

Potential impact: mismatch among charged fee, remaining reserved amount, and recorded fee metadata; exact effect requires the historical live function definition and schema constraints.

## Cross-function dependency and safety observations

- The helper's fee rows are seeded for USDT and IRR. These three call sites explicitly request USDT rates; this is consistent with the literal fee helper arguments in the recovered source, but does not prove all supported quote-asset paths are handled.
- The source comments state market orders use taker fees and limit-order placement/fills use maker fees. The code's intended distinction is explicit; runtime parity remains unproven until exact before/after definitions are available.
- All three blocks use `pg_get_functiondef(...::regprocedure)` and dynamic `EXECUTE`. They operate on the existing overload resolved by the exact regprocedure signature, not on an independently versioned function source file.
- A successful migration run alone would not prove semantic correctness: PostgreSQL can accept a transformed function whose text compiles but whose omitted replacement leaves inconsistent fee/reservation behavior.
- Function owner, SECURITY DEFINER/INVOKER mode, volatility, parallel-safety, SET clauses, ACLs, dependencies, triggers/callers, and full pre-migration definitions are not embedded in these DO blocks. They must be compared against the read-only Production catalog snapshot before any isolated rehearsal.

## Required evidence before any fixture rehearsal

1. Obtain exact pre-migration `pg_get_functiondef` snapshots for all three signatures from the historical Production state, with owner, language, volatility, SECURITY mode, SET/search_path, ACLs and identity arguments.
2. Count every old anchor in each original definition and require exactly one occurrence; explicitly reject zero or multiple matches.
3. Produce deterministic transformed text without executing it; record before/after SHA-256, byte length, and a unified diff.
4. Assert every intended old anchor is absent and every intended new fragment occurs exactly once, in the expected block/scope.
5. Parse/compile transformed definitions in a disposable PostgreSQL 17 container with synthetic fee rows and synthetic wallet/order fixtures only.
6. Test market taker fee, limit maker reservation, partial fills, multiple fills, residual reservation recalculation, cancellation/release, insufficient available balance, disabled/missing fee rows, and fee metadata consistency.
7. Compare resulting function metadata, dependencies, triggers/callers and ACLs with the captured historical catalog. Keep order-engine Cron jobs untouched; do not invoke Production workers or change schedules.
8. Roll back synthetic DML and destroy the ephemeral database after assertions.

## Decision

**BLOCKED — no replay or function rewrite approved.**

The recovered source is byte-authentic historical SQL, but the three blocks lack complete replacement-anchor validation and post-transform semantic assertions. Exact Production before-definitions and a source-faithful disposable PG17 test are still required. No SQL was executed by this review; no Production object, financial row, ACL, RLS policy, Cron job, queue, deployment, or paid resource was changed.
