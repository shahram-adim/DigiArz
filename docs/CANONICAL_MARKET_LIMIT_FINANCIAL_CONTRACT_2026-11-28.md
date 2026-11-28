# Canonical Market/Limit financial contract — 2026-11-28

**Status:** source-derived implementation contract and review gate. This document does not define a deployable migration and does not authorize Production changes.

## Authoritative source

The baseline is the checked-in migration:

- `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql`
- Blob SHA: `de09b1cd391790fcd9d94708a916cb41cd9ccc9f`
- Its Market/Limit functions were applied to disposable PostgreSQL 17 in the recorded authoritative source-parity workflow. This is not a claim of full Production schema/ACL/RLS parity.

The existing canonical identity prototype is:

- `supabase/tests/canonical_asset_identity_candidate.sql`
- Blob SHA at review: `42b56965140e6c7f7f20bf26126d06eebd472e24`
- It proves duplicate display-ticker isolation inside a simplified schema only. It is not the financial implementation baseline.

## Exact behavior that a canonical implementation must retain

### Market entrypoint — `public.execute_demo_trade`

1. Derive user identity from `auth.uid()`; reject missing identity and inactive accounts through `current_account_is_active()`.
2. Validate the USDT pair syntax and require the matching enabled `demo_trading_pairs` row.
3. Ignore the caller's price as an execution source: use `market_prices` and reject missing, non-positive, or older-than-one-minute prices.
4. Use `get_demo_trading_fee_rate('USDT','taker')`.
5. Explicitly round **Market gross** `round(amount * price, 8)` and **Market fee** `round(gross * fee_rate, 8)`.
6. Preserve the production ledger split: USDT in `wallets.balance_usdt`; base units in `asset_balances(user_id,asset)`. Respect outstanding `order_reservations` when calculating available funds.
7. Preserve wallet/base balance locks and atomic writes to `orders`, `trades`, and `transactions`.

### Limit placement — `public.place_limit_order`

1. Derive the user from `auth.uid()`; reject unauthenticated and inactive accounts.
2. Require an enabled USDT pair and validate side, amount, and limit price.
3. Use the maker fee helper `get_demo_trading_fee_rate('USDT','maker')`.
4. Buy reserve formula is exactly `amount * limit_price * (1 + maker_fee_rate)`; sell reserve is exactly the base quantity.
5. Preserve the existing `wallets` and `asset_balances` ledgers and their row locks. Check outstanding reservations before accepting the order.
6. Insert the pending `orders` row and a durable `order_reservations` row with `reserved_amount`, `consumed_amount`, `released_amount`, and `status`.

### Limit worker — `public.process_limit_orders`

1. Acquire transaction advisory lock `739201126`; return without processing if another cycle owns it.
2. Select pending/partially-filled Limit orders for active profiles in creation order using `FOR UPDATE SKIP LOCKED`.
3. Revalidate pair enablement and a positive `market_prices` quote updated within one minute.
4. Fill at most `LEAST(remaining_amount, original_order_amount * 0.25)` per cycle. Four equal successful cycles can complete a full order.
5. Lock and validate the durable reservation; preserve the existing wallet-first balance lock discipline and wallet/base-ledger settlement.
6. Use the maker fee helper. For each fill, update order fill/remaining/status and reservation consumed/released/status fields using the authoritative cumulative formulas.
7. Write one `trades` row and one `transactions` row per successful fill.

**Precision clarification:** the authoritative Market function explicitly rounds gross and fee to 8 decimal places. The authoritative Limit worker in this migration does **not** call `round(...,8)` for each fill; it calculates gross and fee directly and relies on the actual deployed column types/constraints. Do not silently impose Market rounding on Limit or claim that this migration itself implements explicit per-fill 8-decimal rounding. Any Limit rounding change must be a separately reviewed financial behavior change with its own cumulative-reservation and regression analysis.

## Why the current canonical prototype cannot be promoted

The current fixture differs in material financial behavior:

| Area | Authoritative Market/Limit | Canonical prototype |
|---|---|---|
| Balance model | `wallets.balance_usdt` plus `asset_balances` | Generic `balances(user_id,asset_id)` |
| Fee | Configured fee helper; Market taker / Limit maker | Hard-coded `0.001` |
| Price freshness | `market_prices.updated_at >= now()-1 minute` | Provider `observed_at` up to 2 minutes old and 30 seconds future |
| Limit fill | 25% of original amount per worker cycle | Full remaining amount in one pass |
| Reservation | Durable consumed/released/status ledger | Reservation is deleted after fill |
| Worker serialization | Advisory lock `739201126`, ordered row locking, `SKIP LOCKED` | No equivalent global Limit-worker advisory lock |
| Financial journal | `orders`, `trades`, `transactions`, wallets/base balances | No equivalent production transaction journal or wallet table |

The canonical candidate's immutable pair/asset foreign keys are useful and should be retained as identity evidence. They do not compensate for these financial differences.

## Required next implementation shape

1. Keep immutable `asset_id`, `pair_id`, provider mapping, and composite pair/base/quote constraints from the identity design.
2. Extend the real financial ledger model with canonical identity references. Do not create a parallel generic balance ledger.
3. Carry `pair_id`, `base_asset_id`, and `quote_asset_id` through orders, trades, reservations, and pair-keyed prices, with ownership/composite constraints that prevent cross-pair contamination.
4. Rebuild Market/Limit candidate functions against the authoritative wallet, asset-balance, fee-helper, reservation, journal, freshness, and worker contracts above. Keep identity resolution pair_id-authoritative; ticker is display-only.
5. Build a disposable PostgreSQL harness that applies the exact authoritative migration first and then tests the canonical extension. Exercise two distinct pairs with the same display ticker simultaneously.
6. Cover Market buy/sell; Limit buy/sell; four partial fills; stale/missing/future prices; disabled pair and inactive account; insufficient balance; malformed/missing reservation; fee/precision edge cases; transaction journal; cancellation/release; idempotency; and two-session races.
7. Reconcile missing migration sources and schema/ACL/RLS/trigger dependencies before proposing any deployable migration.

## Automated source-contract guard

`tests/canonical-market-limit-financial-contract.test.js` pins the authoritative source behaviors and asserts that the current identity prototype still has known non-parity properties. It is a static source-contract test, not a runtime financial integration test and not Production parity evidence.

Run it in CI with:

```sh
node --test tests/canonical-market-limit-financial-contract.test.js
```

## Release gates and safety

- Do not infer or reconstruct missing applied migrations from this contract.
- Do not change Production schema, data, functions, grants, RLS, triggers, Cron, workers, or Edge Functions.
- Do not invoke Market/Limit/conditional financial RPCs or workers manually.
- Do not merge, rebase, push migrations, deploy, publish APK/Pages, or incur costs without the owner's explicit approval.
