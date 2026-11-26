# DigiArz exact-decimal preflight — 2026-11-15

Repository: `shahram-adim/DigiArz`
Branch: `main`
Supabase project: `gfoaubfilhttnwjykaox`
Scope: read-only Production inspection only. No DDL, DML, order placement, balance mutation, or pair activation was performed.

## Confirmed numeric column types

| Table.column | Current type |
|---|---|
| market_prices.price | numeric(38,18) |
| orders.amount, orders.price | numeric(24,8) |
| orders.filled_amount, orders.remaining_amount | unconstrained numeric |
| trades.amount, trades.price | numeric(24,8) |
| asset_balances.balance | numeric(28,8) |
| order_reservations.reserved_amount, released_amount, consumed_amount | unconstrained numeric |
| conditional_orders.amount, trigger_price, limit_price, executed_price | unconstrained numeric |
| wallets.balance_usdt, transactions.amount | numeric(24,8) |

## Read-only stored-value scan

The inspected Production tables currently contain 3 orders, 3 trades, 1 asset-balance row, and zero rows in order_reservations and conditional_orders.

| Field | Rows | Max observed integer digits | Max observed scale | Nulls | Invalid sign |
|---|---:|---:|---:|---:|---:|
| orders.amount | 3 | 1 | 8 | 0 | 0 |
| orders.price | 3 | 5 | 8 | 0 | 0 |
| orders.filled_amount | 3 | 1 | 8 | 0 | 0 |
| orders.remaining_amount | 3 | 1 | 0 | 0 | 0 |
| trades.amount | 3 | 1 | 8 | 0 | 0 |
| trades.price | 3 | 5 | 8 | 0 | 0 |
| asset_balances.balance | 1 | 1 | 8 | 0 | 0 |
| order_reservations.* | 0 | n/a | n/a | 0 | 0 |
| conditional_orders.* | 0 | n/a | n/a | 0 | 0 |

Observed values do not determine the future maximum integer range. The existing numeric(24,8) columns permit up to 16 integer digits; the final target typmod must be selected after reviewing documented business limits and all callers, not merely current rows.

## Trading RPC inventory

All listed functions exist as SECURITY DEFINER with empty search_path:

- execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric)
- place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric)
- cancel_limit_order(p_order_id uuid)
- process_limit_orders()
- place_stop_limit_order(p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric)
- process_stop_limit_orders()
- place_conditional_exit_order(p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric)
- cancel_conditional_exit_order(p_order_id uuid)
- process_conditional_orders()

## Constraints and indexes

Important accounting constraints confirmed:
- orders: filled_amount + remaining_amount = amount; filled and remaining are bounded and nonnegative.
- trades: amount and price positive.
- asset_balances: balance nonnegative.
- order_reservations: consumed/released amounts nonnegative and their sum cannot exceed reserved amount.
- conditional_orders: amount/trigger positive; Stop-Limit requires positive limit_price.

No indexes directly include the numeric columns targeted for precision widening. Existing indexes use identifiers, user/status/time, and order references. All constraints must be preserved and revalidated by any future migration.

## Confirmed implementation risk

The repository's STOP_LIMIT_QA_MATRIX records that process_limit_orders can generate partial-fill quantities beyond 8 decimals while trades and asset_balances currently round to 8 decimals. It also records that Limit quote gross/fee/net are not explicitly quantized once before wallet, transaction, and reservation updates. Market execution rounds quote amounts but still needs consistent base-asset precision.

## Still open before implementation

1. Complete a source-level inventory of all browser RPC call sites and order-critical Number/parseFloat/toFixed paths.
2. Confirm documented integer caps and validate all related numeric columns/consumers, including reservation and conditional-order fields.
3. Review function bodies and grants/dependencies before designing replacement RPCs.
4. Build isolated tests before changing browser or SQL implementation.

## Safety gate

This report is not approval to apply Production DDL. No Production migration or financial test is authorized by this preflight. Continue with source inventory and isolated tests; Production rollout remains separately gated by explicit owner authorization.
