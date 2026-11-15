# DigiArz exact-decimal backend RPC review

Date: 2026-11-15
Repository: `shahram-adim/DigiArz`
Supabase project inspected: `gfoaubfilhttnwjykaox`
Scope: read-only review of live PostgreSQL function definitions and existing design/preflight artifacts. No DDL, DML, test orders, balance changes, or production migration was executed.

## Current state

- Browser exact-decimal utility and 8-fractional-digit compatibility gate remain committed.
- GitHub Actions exact-decimal test workflow passed for the previous implementation commit; that does not exercise PostgreSQL RPCs.
- Production schema has not been widened. `orders.amount/price` and `trades.amount/price` remain 8-scale; `asset_balances.balance` remains 8-scale. USDT wallet and transaction ledger columns remain 8-scale.
- The current Supabase connection exposes Production only. No paid branch or additional project was created. Consequently, database lifecycle testing remains blocked and no Production DDL is authorized.

## Live RPC review observations

### `execute_demo_trade`

- Reads a fresh market price server-side (one-minute freshness) and checks active account and enabled pair.
- Calculates `v_gross := round(p_amount * v_price, 8)` and `v_fee := round(v_gross * v_fee_rate, 8)`.
- This already follows the intended quote-ledger scale for gross and fee, but the RPC has no explicit input-scale/range guard for amount. The widened base amount storage and all related asset-balance writes must be coordinated with that guard.
- Buy/sell base quantity writes currently depend on the 8-scale `asset_balances.balance` column.

### `place_limit_order`

- Validates positive amount/limit price, maximum amount 1,000,000, active account, enabled pair, and available funds.
- Does not explicitly reject more than 18 fractional digits or enforce the selected integer-digit cap.
- Buy reservation requirement is currently calculated as `p_amount * p_limit_price * (1 + fee_rate)` without a single explicit 8-place quantization before persisting it. This must be quantized once to the USDT ledger scale.
- Sell reservation is a base-asset quantity and must retain 18 places after the schema change.

### `process_limit_orders` — critical accounting defect to address before 18-place release

The current live function:
1. Selects a fill quantity as `LEAST(remaining_amount, original_amount * 0.25)`.
2. Calculates gross and fee without explicit 8-place quantization.
3. Uses the unquantized values for wallet deltas, transactions, and reservation consumption.
4. Persists trades and base balances into columns that currently round to 8 places.
5. Recomputes the remaining buy reserve using an unquantized expression.

This can make the order fill quantity, trade quantity, asset balance delta, quote ledger, and reservation arithmetic disagree once precision is widened or even during current partial fills.

Required implementation contract:
- Quantize every persisted base fill quantity to at most 18 fractional digits before any financial write.
- Use that exact same quantity for the trade row, asset balance delta, order filled/remaining updates, and base-asset reservation consumption.
- Ensure a final fill uses the exact remaining quantity, not a newly computed 25% slice.
- Quantize quote gross once: `v_gross := round(v_qty * v_market_price, 8)`.
- Quantize fee from that quantized gross: `v_fee := round(v_gross * v_fee_rate, 8)`.
- For buy: `v_total := v_gross + v_fee`; reuse this exact value for wallet debit, transaction amount, and USDT reservation consumed amount.
- For sell: `v_net := v_gross - v_fee`; reuse this exact value for wallet credit and transaction amount; consume the exact 18-place base quantity from reservation.
- Recompute the remaining buy reserve at quote scale: `round(v_new_remaining * limit_price * (1 + fee_rate), 8)`; do not compare or persist a higher-scale quote expression against the 8-scale ledger.
- Keep `consumed_amount + released_amount <= reserved_amount` invariant and use the existing row/advisory locking and atomic transaction behavior.

Open design detail: a quarter of an 18-scale quantity may itself require 20 fractional digits. The implementation must choose and test an explicit 18-place partial-fill rounding rule, including a minimum-progress case for the smallest supported quantity, so a valid order cannot remain stuck forever with a rounded-to-zero fill. Do not silently cast or rely on column assignment rounding.

### `place_stop_limit_order` and `process_stop_limit_orders`

- Stop-Limit hands the triggered order to `place_limit_order`; therefore, input validation, reservation quantization, and child order precision must be consistent with the Limit engine.
- Parent/child filled and remaining quantities must use the same 18-place values.
- Preserve the current atomic reservation handoff, retry cap, parent-child synchronization, advisory locking, and fail-closed invalid-reservation handling.
- Do not independently round parent or child amounts during synchronization.

### Conditional exits

- `place_conditional_exit_order` reserves base asset quantity and writes the trigger to both the order and conditional-order records. Amount and trigger precision must be validated identically to Market/Limit/Stop-Limit.
- `process_conditional_orders` must apply the same quote gross/fee/net policy as Market execution and use the exact 18-place base quantity for balance and reservation accounting.
- Cancellation must release only the validated unconsumed remainder and remain atomic.

## Schema target remains provisional

Do not create/apply a migration until the numeric integer caps are formally pinned and every live RPC/caller is covered. Existing proposal to preserve current integer capacity is:
- order/trade amount and price: `numeric(34,18)` (16 integer digits)
- asset balances: `numeric(38,18)` (20 integer digits)
- reservation and conditional-order numeric values: `numeric(38,18)`
- USDT wallet and transaction amount: retain `numeric(24,8)`

This is a proposal, not approval. A 1,000,000 maximum amount check does not by itself constrain price integer digits or all aggregate balances; server validation and overflow behavior must be specified.

## Next implementation sequence

1. Add pure regression tests for PostgreSQL-compatible `round(value, 8)`, 18-place fill quantities, exact residual completion, and reservation invariants.
2. Pin the 18-place partial-fill policy and integer caps.
3. Build complete replacement definitions for all affected RPCs from the current live definitions, preserving grants and security attributes.
4. Add an isolated PostgreSQL integration harness that creates disposable schema/users/wallet fixtures and verifies Market, Limit, Stop-Limit, conditional exit, cancellation, partial fills, residual fills, and concurrency.
5. Only after those tests pass, prepare a schema/RPC migration in the repository. Do not apply it to Production without separate explicit authorization.

## Gate

**NO-GO for 18-decimal database or Production trading release.** The current Limit worker has an unquantized multi-ledger accounting path that must be corrected and tested before enabling the new precision. This review made no Production changes.


## Follow-up artifacts — 2026-11-15

- Added `supabase/tests/exact_decimal_arithmetic.sql`, a pure PostgreSQL numeric regression script. It creates no tables and performs no data writes. It checks PostgreSQL 8-place rounding boundaries, 18-place micro-quantity arithmetic, a representative four-cycle partial-fill plus exact residual, quote-ledger arithmetic, reservation conservation, and explicitly exposes the sub-quantum quarter-fill case.
- The SQL script has been committed but has **not** been executed yet: this environment has no local PostgreSQL client/server, and Production is not an acceptable test target. Do not claim this SQL script has passed.
- The new report and SQL test file were read back from GitHub after commit.
- Latest Production migration remains `20261115143827_bound_stop_limit_invalid_reservation_retries`; no exact-decimal migration is applied. Supabase still exposes no development branches.
- The next unresolved design choice is the 18-place partial-fill progress rule for quantities whose 25% slice rounds to zero. This must be decided and tested before replacing the Limit worker.


## Partial-fill policy decision — 2026-11-15

The 18-place partial-fill progress rule is now pinned in the design spec and covered by additional pure-SQL regression assertions:

- Quantize the nominal 25% slice explicitly with PostgreSQL `round(..., 18)`.
- If that slice is zero for a valid positive order, advance by one base-asset quantum (`0.000000000000000001`), bounded by the remaining amount.
- Use the exact remaining amount for the final fill.
- Reject submitted quantities that would be below the supported 18-place quantum; never silently round input.

This is a design/test specification only. The SQL regression file has not been executed in PostgreSQL. The live worker has not been replaced. Production remains unchanged and 18-decimal release remains NO-GO.


## Additional live RPC findings — 2026-11-15

Read-only inspection of the current Production function definitions found:

- `place_limit_order` and `place_stop_limit_order` validate positivity and the existing amount ceiling, but do not reject input with more than 18 fractional digits or enforce an 18-place price scale. Buy-side reserve is currently calculated as an unquantized `amount * limit_price * (1 + fee_rate)`.
- `execute_demo_trade` uses the fresh `market_prices.price` value for execution and ignores the supplied `p_price` argument. Gross and fee are rounded to 8 places; the same calculated total/net is reused for wallet and transaction, but the function currently accepts amounts without an explicit 18-place scale gate.
- `process_stop_limit_orders` hands triggered orders to `place_limit_order`, so its precision and reserve behavior inherit the Limit placement implementation. The parent/child synchronization path also copies child fill and residual values.
- `process_conditional_orders` hands conditional exits to `execute_demo_trade`; its reservation reconciliation and execution therefore inherit the Market engine's amount validation and settlement behavior.
- Existing cancellation functions were inspected; they update order/reservation status but are not the place to introduce numeric scale conversion. Their lock ordering and account checks need to be preserved during the coordinated migration.

The GitHub Actions workflow now provisions an ephemeral PostgreSQL 17 service and runs the pure arithmetic SQL regression file after the Node/browser tests. This service is CI-only; it is not a Supabase branch and does not touch Production. The first run for this workflow revision is still pending/in progress at the time of this report update.

These findings reinforce that the eventual migration must update the complete RPC call chain together: Market execution, Limit placement/worker, Stop-Limit placement/trigger worker, and conditional exit execution. No Production function has been replaced.
