# DigiArz Exact Decimal Trading — Preflight Report

**Date:** 2026-11-15  
**Repository:** `shahram-adim/DigiArz`  
**Branch:** `work/exact-decimal-preflight`  
**Supabase project inspected:** `gfoaubfilhttnwjykaox` (Production; read-only queries only)

## Safety statement

This report was produced using read-only schema inspection, aggregate SELECTs, function-definition reads, and GitHub source inspection. No Production DDL was run. No order, trade, wallet, asset balance, reservation, transaction, market pair, or user record was inserted, updated, or deleted.

## 1. Production snapshot at inspection time

| Table / item | Count |
|---|---:|
| `orders` | 3 |
| `trades` | 3 |
| `wallets` | 1 |
| `asset_balances` | 1 |
| `order_reservations` | 0 |
| `conditional_orders` | 0 |
| Enabled USDT trading pairs | 12 |
| `market_prices` | 686 |

The three existing orders/trades are the only rows available for empirical order/trade range inspection. There are no Production reservation or conditional-order examples, so those paths cannot be empirically validated from live rows.

## 2. Current numeric column types

| Table.column | Current type |
|---|---|
| `market_prices.price` | `numeric(38,18)` |
| `orders.amount` | `numeric(24,8)` |
| `orders.price` | `numeric(24,8)` |
| `orders.filled_amount` | unconstrained `numeric` |
| `orders.remaining_amount` | unconstrained `numeric` |
| `trades.amount` | `numeric(24,8)` |
| `trades.price` | `numeric(24,8)` |
| `asset_balances.balance` | `numeric(28,8)` |
| `order_reservations.reserved_amount` | unconstrained `numeric` |
| `order_reservations.consumed_amount` | unconstrained `numeric` |
| `order_reservations.released_amount` | unconstrained `numeric` |
| `conditional_orders.trigger_price` | unconstrained `numeric` |
| `conditional_orders.limit_price` | unconstrained `numeric` |
| `conditional_orders.amount` | unconstrained `numeric` |
| `conditional_orders.executed_price` | unconstrained `numeric` |
| `wallets.balance_usdt` | `numeric(24,8)` |
| `wallets.balance_irr` | `numeric(24,0)` |
| `transactions.amount` | `numeric(24,8)` |

## 3. Observed stored ranges

The following are aggregate maxima from the live rows at inspection time, not guaranteed future limits:

| Column | Rows | Max absolute value | Integer digits | Fractional digits observed |
|---|---:|---:|---:|---:|
| `orders.amount` | 3 | 0.0026 | 1 | 8 |
| `orders.price` | 3 | 75,810 | 5 | 8 |
| `orders.filled_amount` | 3 | 0.0026 | 1 | 8 |
| `orders.remaining_amount` | 3 | 0 | 1 | 0 |
| `trades.amount` | 3 | 0.0026 | 1 | 8 |
| `trades.price` | 3 | 75,810 | 5 | 8 |
| `asset_balances.balance` | 1 | 0.0026 | 1 | 8 |
| `wallets.balance_usdt` | 1 | 9,802.6974477 | 4 | 8 |
| `transactions.amount` | 3 | 197.2874904 | 3 | 8 |
| `market_prices.price` | 686 | 65,419 | 5 | 18 |

Reservation and conditional-order tables currently contain zero rows. Existing order and trade values fit both the current and proposed wider types without numeric loss.

## 4. Constraints and dependencies

- The order accounting invariant is enforced by `orders_amount_accounting_chk`: `filled_amount + remaining_amount = amount`.
- `orders_filled_amount_range_chk` and `orders_remaining_amount_range_chk` constrain fill and remainder to the order amount.
- Order and trade amount/price positivity constraints must be retained.
- Asset balances have a nonnegative check and a unique user/asset key.
- Reservation accounting checks enforce nonnegative consumed/released values and prevent consumed plus released from exceeding reserved.
- Conditional-order checks enforce positive amount/trigger/execution price and valid Stop-Limit price fields.
- There are no indexes whose indexed key columns are any of the inspected numeric columns. The indexes found on these tables are identity, symbol, or user/asset/order-key indexes.
- Foreign keys connect orders, trades, reservations, and conditional orders by UUID/user identifiers, not by numeric amount/price columns.
- Existing triggers on orders, trades, and transactions call `guard_active_account_writes`; these protections must remain intact.

## 5. Database function/caller inventory

The relevant live public RPCs and helper paths identified include:

- Market: `execute_demo_trade(text,text,numeric,numeric)`
- Limit: `place_limit_order(text,text,numeric,numeric)`, `process_limit_orders()`, `cancel_limit_order(uuid)`
- Stop-Limit: `place_stop_limit_order(text,text,numeric,numeric,numeric)`, `process_stop_limit_orders()`, `cancel_stop_limit_order(uuid)`
- Conditional exits: `place_conditional_exit_order(text,text,numeric,numeric)`, `process_conditional_orders()`, `cancel_conditional_exit_order(uuid)`
- Reservation display: `get_my_order_reservations(uuid[])`
- Account lifecycle: `deactivate_my_account()`
- Administrative wallet path to check for compatibility: `private.admin_adjust_wallet(uuid,text,text,numeric,text)`
- Pair administration: `admin_disable_market_pair(...)`

Internal calls matter: conditional exits call the Market execution function; Stop-Limit processing creates its child through the ordinary Limit placement function. Those internal paths must use the same precision and quantization rules as direct RPC calls.

The inspected trading RPCs are SECURITY DEFINER with an empty search_path. Their existing grants, authentication checks, active-account checks, enabled-pair checks, price freshness, ownership, and worker-only permissions must be preserved.

## 6. Browser findings

The current `index.html` still converts order-critical values to JavaScript Number:

- `formatNum` uses `Number(value)` and `toLocaleString`.
- Quick-trade estimates parse amounts with `Number(...)`.
- Market trade submission converts the amount to Number before RPC.
- Limit submission converts amount and limit price to Number before RPC.
- Conditional-exit submission converts amount and trigger price to Number before RPC.
- Stop-Limit submission converts amount, stop price, and limit price to Number before RPC.
- Reservation arithmetic and some order/conditional displays also use Number subtraction/comparison.
- The relevant UI RPCs are `execute_demo_trade`, `place_limit_order`, `place_conditional_exit_order`, and `place_stop_limit_order`.

Market analytics/chart conversions can remain Number-based where they are non-authoritative, but must not be reused for order validation, settlement estimates, or RPC arguments.

## 7. Recommended target precision

**Recommendation:** use `numeric(38,18)` for all asset-denominated quantities and execution/limit/trigger prices that participate in the order lifecycle:

- `orders.amount`, `orders.price`, `orders.filled_amount`, `orders.remaining_amount`
- `trades.amount`, `trades.price`
- `asset_balances.balance`
- `order_reservations.reserved_amount`, `consumed_amount`, `released_amount`
- `conditional_orders.amount`, `trigger_price`, `limit_price`, `executed_price`

Rationale:
- It matches the already-established `market_prices.price numeric(38,18)` range and avoids inconsistent scale limits across parent/child/order/trade/balance rows.
- It provides 20 integer digits and 18 fractional digits, exceeding the current observed integer ranges and preserving the existing per-order cap of 1,000,000 enforced by the placement RPCs.
- Reservation columns are asset-dependent: sell reservations are base-asset quantities while buy reservations are USDT. Widening the storage type supports the base-asset precision; the buy-side USDT reservation values must still be explicitly quantized to 8 decimals before being written.
- USDT wallet and transaction ledger columns remain `numeric(24,8)`; IRR remains `numeric(24,0)`. Quote gross, fee, net, wallet delta, transaction amount, and USDT reservation consumption must be quantized once using PostgreSQL `round(value,8)` and the same quantized values reused consistently.

This target is a schema recommendation, not an applied migration. It must be tested in an isolated database and reviewed for lock/rewrite/rollback behavior before any Production rollout.

## 8. Remaining pre-implementation checks

- Inspect every relevant RPC definition in full, especially `process_limit_orders()`, `process_conditional_orders()`, and `private.admin_adjust_wallet(...)`, to confirm all quote reservation calculations and helper calls.
- Inspect all browser code paths that display and compare reservation/order quantities; retain Number only for clearly non-authoritative chart/market analytics.
- Confirm the complete set of RPC callers beyond the browser. Numeric RPC arguments accept decimal text from PostgREST, but compatibility callers must be identified.
- Build an isolated test database with disposable users and balances before any transactional lifecycle test. The connected Supabase account currently exposes only Production; no Production test order is permitted.
- Confirm migration lock duration, table rewrite behavior, backup/restore, and rollback before Production DDL.

## Conclusion

The coordinated `numeric(38,18)` approach is technically consistent with the existing market-price column and is safe for the currently observed values. The most important implementation work is not merely widening columns: it is keeping exact decimal strings in the browser, applying uniform validation at every RPC boundary, and reusing one quantized 8-decimal USDT settlement amount throughout the atomic accounting writes.

**No Production changes were made.**


## Additional preflight findings — second pass (2026-11-15)

### Limit partial-fill precision

The live `process_limit_orders()` computes each cycle quantity as:

```sql
v_qty := LEAST(v_remaining, v_order.amount * 0.25);
```

An amount stored at 18 fractional digits can produce a 20-digit intermediate when multiplied by 0.25. This must not be silently rounded by a later `numeric(...,18)` assignment. The implementation must explicitly define and test a fill-quantization rule. Recommended rule: floor each non-final 25%-of-original fill to 18 fractional digits; if the quantized slice is zero, consume the exact remaining dust as the terminal fill. For a normal amount, the final fill must consume the exact remainder so that `filled_amount + remaining_amount = amount` at every step. This rule preserves the existing 25%-per-cycle behavior for ordinary quantities and prevents sub-quantum orders from getting stuck. This is a proposed algorithm to validate in isolated tests, not a Production change.

### Quote reservation and settlement precision

The live Limit placement and worker functions currently calculate buy-side required reserve, gross, fee, net, and remaining reserve without consistently applying an 8-decimal quantization before all writes. The worker writes wallet and transaction columns with 8-decimal scale while reservation fields are unconstrained. Consequently, the same logical USDT amount can be stored at different effective precision across wallet, transaction, and reservation ledger entries.

The implementation must calculate the 8-decimal quote values once, then reuse the same values for:
- buy-side reserve requirement;
- each fill's gross and fee;
- wallet debit/credit;
- transaction amount;
- reservation consumed amount and remaining reserve/release.

Use PostgreSQL `round(value,8)` for the quote policy and include below-half, exact-half, and above-half tests. Do not apply this quote quantization to base-asset quantities or prices.

### No test harness discovered

Repository code search found no existing `package.json`, Vitest, Jest, or Playwright test harness. Before adding a dependency, inspect the repository workflow and prefer Node's built-in `node:test` for a standalone pure-JavaScript decimal utility test if supported by the available CI runner. Keep browser integration test strategy documented; do not introduce a paid service or a runtime dependency solely for tests.
