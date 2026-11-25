# DigiArz — Limit worker settlement precision audit

**Date:** 2026-11-25  
**Status:** READ-ONLY FINDING / TEST DESIGN — NOT A PRODUCTION CHANGE  
**Project:** `gfoaubfilhttnwjykaox` (Production catalog queried with SELECT only)  
**Related:** PR #62 — `feature/persian-asset-name-candidates-2026`

## 1. Evidence collected

The live Production definitions were read with `pg_get_functiondef`; no RPC was invoked.

| Function | Live definition MD5 | Owner | SECURITY DEFINER | search_path |
|---|---|---|---|---|
| `public.place_limit_order(text,text,numeric,numeric)` | `3eab167c47bf8ff2e1705b9f243380ec` | postgres | yes | empty |
| `public.process_limit_orders()` | `00ab429596fb99392666632967cde9c0` | postgres | yes | empty |
| `public.cancel_limit_order(uuid)` | `69360684173b6aabebc5ff4e4de2eed9` | postgres | yes | empty |
| `public.get_demo_trading_fee_rate(text,text)` | `546d80d7105228ed97da26c5ed0c7b7f` | postgres | yes | empty |

The current worker:
- chooses `LEAST(remaining_amount, amount * 0.25)` for each fill;
- writes each fill quantity to `trades.amount` and `asset_balances.balance`;
- accumulates `orders.filled_amount` and reservation fields independently;
- calculates `v_gross` and `v_fee` without explicit 8-place quantization;
- reuses the resulting values in wallet, transaction and reservation accounting.

Read-only `information_schema.columns` inspection confirmed these live types:

| Column | Production type |
|---|---|
| `orders.amount`, `orders.price` | `numeric(24,8)` |
| `orders.filled_amount`, `orders.remaining_amount` | unconstrained `numeric` |
| `trades.amount`, `trades.price` | `numeric(24,8)` |
| `asset_balances.balance` | `numeric(28,8)` |
| `wallets.balance_usdt`, `transactions.amount` | `numeric(24,8)` |
| `market_prices.price` | `numeric(38,18)` |
| `order_reservations.reserved_amount`, `consumed_amount`, `released_amount` | unconstrained `numeric` |

## 2. Concrete base-quantity drift

For an order amount of `0.12345678`, each 25% worker pass selects:

`0.12345678 × 0.25 = 0.030864195`

A `numeric(24,8)` trade row stores that quantity as `0.03086420`. Four trade rows therefore sum to `0.12345680`, while the order's unconstrained fill accumulator can reach exactly `0.12345678`. The trade history is higher by `0.00000002`.

For a sell starting from a base balance of `1.00000000`, repeated assignment of `balance - 0.030864195` to `numeric(28,8)` can round after each pass; the resulting balance is not guaranteed to equal the initial balance less the order's exact filled amount. This is a separate storage-rounding path from the trade-row sum.

This is a confirmed type/arithmetic incompatibility. It does not require invoking a live order to establish the mathematical mismatch. The same risk was documented in the repository's earlier exact-decimal review, but this read-only catalog/function check independently reconfirms that the live Production definitions and column typmods still exhibit the relevant conditions.

## 3. Quote settlement and reservation

The worker calculates gross/fee/total/net at unconstrained numeric precision, while wallet and transaction amounts are `numeric(24,8)`. Reservation `consumed_amount` remains unconstrained. Without one explicit 8-place quantization point reused by wallet, transaction and reservation writes, a rounding discrepancy can arise between those ledgers. The remaining buy reserve is also derived from an unquantized expression.

The placement function computes buy reserve as `amount × limit_price × (1 + maker_fee_rate)` without explicit quote-scale rounding. The cancellation function releases `reserved_amount - consumed_amount` and requires exactly one valid active reservation; it does not repair an earlier settlement mismatch.

## 4. Safe next test phase

Before proposing any Production migration or function replacement:

1. Build a separate disposable PostgreSQL 17 fixture with the exact currently observed 8-place column types and synthetic rows only.
2. Install the exact current Production worker definition into that fixture and characterize buy and sell partial-fill drift, including a four-pass order and a final residual pass.
3. Install the existing review-only exact-decimal candidate in a separate disposable database with the proposed widened base-quantity columns; run equivalent tests and compare all invariants.
4. Assert: sum(trade base quantity) = order filled amount; base balance delta = signed filled amount; buy reservation consumption = total USDT wallet debit = transaction sum; sell wallet credit = transaction sum; consumed + released never exceeds reserved; cancellation releases only the unconsumed remainder.
5. Include non-terminating quarter fills, tiny/zero-rounded quote notional, boundary values, and partial-fill cancellation.
6. Keep the current fee NULL regression as a separate passing test. Do not silently combine the NULL helper fix with the precision candidate.

The repository already contains review-only candidate artifacts under `supabase/drafts/` and isolated exact-decimal test fixtures. Those candidates must not be mistaken for live Production definitions or proof of Production parity. The current CI run for PR #62 does not execute the full exact-decimal candidate workflow.

## 5. Safety and release state

- Production queries in this audit were SELECT-only catalog and information-schema reads.
- No Production function was called.
- No orders, trades, wallets, balances, reservations, RLS, grants, triggers, functions, migrations, Cron jobs, or schedules were changed.
- No merge, deployment, db push, migration, paid resource, or project branch was created.
- The candidate files remain review-only; any Production change requires separate explicit owner approval.
