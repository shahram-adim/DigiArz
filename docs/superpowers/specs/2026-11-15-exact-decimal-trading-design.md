# DigiArz Exact Decimal Trading — Design

**Status:** Proposed design; implementation not yet approved.
**Date:** 2026-11-15
**Repository:** `shahram-adim/DigiArz`

## Intent

Make demo trading preserve tiny asset quantities and micro-prices end-to-end. Market prices already support 18 decimal places, but order/trade/balance storage and parts of the browser UI still lose precision. The goal is consistent, auditable arithmetic across Market, Limit, Stop-Limit, and conditional exits while keeping quote-currency settlement aligned with the existing 8-decimal USDT ledger.

## Goals

- Preserve base-asset quantities and execution/limit/trigger prices at up to 18 fractional digits.
- Keep submitted decimal values exact from browser input through RPC validation; do not convert authoritative values to JavaScript binary floating point.
- Preserve `filled_amount + remaining_amount = amount` exactly at the stored scale through repeated partial fills and final residual fills.
- Quantize USDT gross, fee, net, wallet deltas, transaction amounts, and reservation consumption consistently to 8 decimal places using one documented rounding policy.
- Apply the same precision and validation rules to Market, Limit, Stop-Limit parent/child orders, and conditional exits.
- Retain current authentication, account-state checks, reservation rules, RLS, locking order, and atomic transaction behavior.

## Non-goals and anti-goals

- No real-money deposits, withdrawals, or exchange execution.
- No new active trading pairs; current 12 enabled pairs remain unchanged.
- No Production test trades or changes to user orders, balances, reservations, or transactions.
- No weakening/removal of accounting constraints or security checks.
- No unrelated UI redesign or broad refactor.

## Current findings

- `market_prices.price` is already `numeric(38,18)`.
- `orders.amount/price`, `trades.amount/price`, and `asset_balances.balance` are currently 8-decimal numeric columns.
- `process_limit_orders()` fills up to 25% of original amount per cycle. For an 8-decimal amount, an exact quarter-fill can have more than 8 decimal places; order accounting may retain it while trade and balance columns round it.
- Limit quote settlement is not explicitly quantized once before updating wallet, transaction, and reservation ledger.
- Browser `formatNum` converts values using `Number`; trade estimate/quick amount paths also use binary floating-point. These paths need a focused audit and exact-decimal replacement for order-critical values.
- Existing database inventory found no indexes or foreign keys directly dependent on the numeric columns being widened. Accounting constraints must be preserved. Production DDL may still require strong locks and storage work.

## Approaches considered

1. **Coordinated 18-decimal asset/price precision (recommended).** Widen the relevant numeric columns and update browser parsing/formatting and all trading RPCs together. Keep USDT settlement at 8 decimals with a single explicit quantization point. This supports micro-assets and avoids partial-fill dust.
2. **Enforce 8 decimals everywhere.** Reject higher precision and quantize every fill to 8 decimals. This is simpler but can strand tiny residuals or make very small asset orders unusable; it does not meet the micro-asset goal.

**Selected direction:** Approach 1, as the recommended direction accepted by the user when they said to continue after it was proposed.

## Proposed architecture

### Browser
- Add a small decimal-string utility for validation, comparison, scaling, multiplication/division where required, and formatting. Prefer integer `BigInt` coefficient/scale arithmetic; no dependency installation unless existing project constraints require it.
- Preserve input strings for amount, limit price, stop price, and conditional exit values. Validate decimal syntax, allowed sign, integer digit count, and at most 18 fractional digits before RPC calls.
- Send decimal strings to Supabase RPC parameters (PostgreSQL `numeric` accepts decimal text).
- Use exact-decimal operations for order amount/price and order-critical estimates. Non-authoritative market analytics may continue using Number where appropriate and clearly separate from settlement.
- Update order book, open-order, history, and dashboard formatters so precision is not silently truncated.

### PostgreSQL
- Proposed and now pinned target typmods, subject to isolated migration rehearsal: `orders.amount/price/filled_amount/remaining_amount numeric(34,18)`; `trades.amount/price numeric(34,18)`; `asset_balances.balance numeric(38,18)`; `order_reservations.reserved_amount/released_amount/consumed_amount numeric(38,18)`; `conditional_orders.amount/trigger_price/limit_price/executed_price numeric(34,18)`. Keep `market_prices.price numeric(38,18)`, and keep `wallets.balance_usdt` plus `transactions.amount numeric(24,8)`.
- The 16-integer-digit cap for order amounts/prices matches the existing exact browser parser (`maxIntegerDigits: 16`); order amount remains additionally capped at 1,000,000 by the RPCs. The 20-integer-digit asset/reservation types provide headroom for balances and reservation accounting, while actual USDT settlement remains constrained by the 16-integer-digit wallet/transaction ledger.
- Read-only Production snapshot: maximum observed `market_prices.price` was 65,419; financial/order/conditional/reservation tables had no rows after the user's authorized test-data cleanup, so no historical values need widening. This does not replace the required migration lock/rewrite rehearsal.
- Add server-side validation for supported scale/range at every public trading RPC boundary.
- Keep quote-currency wallet and transaction columns at 8 decimals for this phase.
- In each execution function, quantize quote gross/fee/net once to 8 decimals, then reuse the exact same quantized values for wallet, transaction, reservation consumption, and remaining-reserve calculations.
- Keep partial-fill quantity arithmetic at 18 decimals. On the final fill, consume the exact remaining quantity rather than independently rounding another 25% chunk.
- Preserve atomicity, ownership checks, account status, freshness checks, row/advisory locks, reservation reconciliation, and grants.


### Partial-fill quantization policy (pinned for implementation)

- The stored and executed base-asset quantity scale is 18 fractional digits. The minimum accepted positive amount is therefore one quantum: `0.000000000000000001`.
- For each non-final Limit fill, compute the nominal quarter-fill and quantize it explicitly: `v_chunk := round(v_order.amount * 0.25, 18)`; then `v_qty := LEAST(v_remaining, v_chunk)`.
- If that rounded chunk is zero for a valid positive remaining quantity, use exactly one minimum quantum: `v_qty := LEAST(v_remaining, 0.000000000000000001)`. This prevents a valid smallest-quantity order from becoming permanently unfillable. It is the sole exception to the 25%-per-cycle target and can occur only where a quarter is below half of one 18-place quantum.
- When the order is final (the chosen quantity equals the remaining quantity), consume the exact remaining quantity, never a separately recomputed or rounded fraction.
- Because quarter-fill rounding can leave a one-quantum residual after four slices, allow a fifth and final cycle for that exact residual; never force the four rounded slices to absorb it.
- Validate that every submitted amount is at least one quantum and has no more than 18 fractional digits before it is stored. Reject values that would round to zero; do not silently round user input.
- Apply the exact same `v_qty` to trade amount, asset-balance delta, order filled/remaining values, and base-asset reservation consumption.
- This policy is deterministic for positive numeric values because PostgreSQL `round(numeric, 18)` rounds half away from zero. It must be covered by isolated PostgreSQL tests before any worker replacement or release.

### Migration and release
- Prepare a reversible, transaction-aware migration only after dependency inventory and isolated rehearsal.
- Assess table sizes, lock duration, rewrite/reindex behavior, backup/restore and rollback cost before any Production DDL.
- Deploy UI and database changes in a compatibility-safe order so old clients cannot submit unsupported precision during rollout.
- Production rollout requires explicit separate authorization after isolated tests pass.

## Validation requirements

- Unit tests for decimal parser/formatter and arithmetic: zero, leading/trailing zeros, 18 fractional digits, max integer range, malformed strings, negative values, and rounding boundaries.
- RPC tests: over-scale and over-range rejection, auth/active-account checks, enabled-pair checks, stale-price rejection, and grant boundaries.
- Isolated engine tests: repeated 25% partial fills, final residual fill, micro-price execution, buy/sell fees, reservation consumption/release, cancellation, Stop-Limit trigger-to-child handoff, and concurrent processing/cancellation.
- Assert after every fill: order amount equals filled plus remaining; trade quantity equals balance delta; quote wallet delta equals transaction amount; reservation consumed/released never exceeds reserved amount; no negative balances.
- Android browser tests for decimal keyboard/input behavior and exact RPC payload strings.

## Constraints and implementation calls

- No new Supabase project/environment and no paid infrastructure.
- No Production transaction fixtures.
- Existing 12 enabled pairs stay unchanged.
- Implementation must first add tests and demonstrate failure, then implement in small reviewed commits.
- Any critical security, money-accounting, or data-integrity issue discovered blocks rollout.
- Target numeric typmods, rounding mode, and any maximum integer digits must be pinned in the implementation plan after checking existing production values and all callers; do not guess them in a migration.

## Open implementation decisions

- Confirm a single quote rounding policy (recommended PostgreSQL `round(value, 8)`, with test cases at half-way boundaries).
- Confirm exact target numeric precision/integer-digit caps after a read-only scan of maximum existing values and all RPC/UI callers.
- Confirm whether any non-UI integrations call the trading RPCs and need a compatibility window.
