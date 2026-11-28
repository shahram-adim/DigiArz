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

## Captured Production fee-helper dependency

The exact Production function body is captured at `supabase/tests/canonical_identity_live_public_get_demo_trading_fee_rate_snapshot.sql` (2026-11-27 fingerprint `546d80d7105228ed97da26c5ed0c7b7f`). It validates maker/taker, reads the enabled quote-asset row from `public.demo_trading_fees`, chooses the configured maker or taker rate, and raises when no enabled configuration exists. Its recorded metadata is owner postgres, SECURITY DEFINER, empty search_path, anon execution denied, authenticated/service_role execution allowed.

The disposable authoritative Market/Limit CI step loads this captured helper after the minimal fee-table fixture and before the exact Market/Limit migration. The fixture currently supplies a 0.1% USDT maker/taker row only to make deterministic tests possible. That row is **test data**, not evidence that Production currently configures 0.1%. The table's complete Production DDL, policies/grants and configuration values remain unverified; do not infer them from this function snapshot.

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

## Canonical identity extension blueprint (no DDL applied)

The safe direction is an additive identity extension of the existing financial ledger, not a second wallet system:

| Existing financial record | Canonical identity to carry | Compatibility rule |
|---|---|---|
| demo_trading_pairs | pair_id, base_asset_id, quote_asset_id | Pair ID is authoritative; pair_symbol remains display/API compatibility only |
| market_prices | pair_id | Price lookup for execution is by pair ID; symbol may remain a denormalized display snapshot |
| orders | pair_id, base_asset_id, quote_asset_id | Preserve symbol as historical display snapshot; never resolve the traded asset from it |
| trades | Same pair/base/quote IDs as the parent order | Enforce same-order identity with composite foreign keys |
| order_reservations | Canonical asset_id in addition to legacy asset | Keep existing consumed/released/status ledger; the ID is authoritative for identity, legacy text is compatibility only |
| asset_balances | Canonical asset reference for its existing asset key | Preserve the current user/asset balance ledger; do not create a parallel generic balance table |
| wallets | No new token-specific balance model | Keep the existing USDT wallet as the quote-currency ledger |

### Invariants for the future disposable candidate

1. Pair identity is immutable and unique by (base_asset_id, quote_asset_id). A pair's display ticker is not a key and duplicate display tickers must be allowed when the underlying asset IDs differ.
2. Every order's (pair_id, base_asset_id, quote_asset_id) must reference one exact pair tuple. Every trade must reference the same tuple as its parent order.
3. Execution price is fetched by pair_id; never use display_pair or ticker text as an execution join.
4. Reservation identity must agree with the order side: a buy reserves the pair's quote asset; a sell reserves its base asset. Preserve the authoritative reservation amount, consumed amount, released amount, status, and cumulative formulas.
5. Keep the production fee helper, wallet and base-ledger tables, row-lock sequence, journal writes, and active-account checks unchanged in semantics.
6. The canonical asset ID must resolve to the existing balance asset key through an explicit, unique mapping. Do not silently equate provider IDs, display symbols, and legacy balance symbols.
7. Migration DDL must be additive and backfillable with a deterministic, reviewed mapping. Ambiguous legacy symbols must be quarantined for review rather than auto-assigned.
8. Candidate functions must be exercised only in a disposable PostgreSQL database after applying the exact authoritative migration and all verified prerequisites. No Production data/function is a test target.

### Deliberate non-decisions

- No DDL is proposed here because the full applied migration chain, constraints, indexes, triggers, RLS, grants, and all 17 unrecovered migration sources are not yet reconciled.
- No assumption is made that the legacy asset text can be converted to a canonical ID without an ambiguity audit.
- No change is made to Market/Limit fee precision or to the Limit worker's current per-fill arithmetic.
