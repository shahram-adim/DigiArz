# Canonical Asset Identity for All-Catalog Demo Trading
Date: 2026-11-27
Status: design proposal only — not a migration or Production implementation

## 1. Problem statement

DigiArz must allow demo buy/sell for every asset admitted to its catalog, including future additions. A ticker is a display attribute, not a globally unique asset identity. Production currently has many duplicate active ticker groups, while the trading pair and financial ledger paths use ticker-derived text values.

The live read-only audit found:
- 19,012 active catalog assets;
- 2,365 duplicate active ticker groups;
- 6,662 active asset rows inside those groups;
- `crypto_assets` is keyed by `coingecko_id`, but has no unique active-symbol constraint;
- `demo_trading_pairs` uniquely constrains `pair_symbol` and `base_coingecko_id`;
- `orders.symbol`, `trades.symbol`, `conditional_orders.symbol`, `asset_balances.asset`, and `order_reservations.asset` are text columns. Current RPCs/workers derive a base asset code by stripping the `USDT` suffix from a pair symbol.

Consequently, a ticker-only design cannot represent two different canonical assets with the same display ticker without either selecting the wrong asset or introducing synthetic aliases that leak into the ledger.

## 2. Proposed identity model

Use an immutable internal UUID for each canonical DigiArz asset. Provider IDs (CoinGecko IDs and future provider identifiers) remain external mapping keys, not the only internal identity.

Conceptual entities:

| Entity | Stable key | Purpose |
|---|---|---|
| Canonical asset | `asset_id UUID` | Immutable DigiArz identity; one row per asset |
| Provider mapping | `(provider, provider_asset_id)` | Maps an external provider identity to one canonical asset |
| Trading pair | `pair_id UUID` | Internal pair identity; references base and quote asset IDs |
| Price | `pair_id` + source/observation | Price belongs to a canonical pair, never a ticker string |
| Balance | `(user_id, asset_id)` | Distinct balances for same-ticker assets |
| Order / trade | `pair_id`, `base_asset_id`, `quote_asset_id` | Ledger identity independent of display ticker |
| Reservation | `asset_id` | Reserves the exact canonical asset |
| Conditional order | `pair_id` and canonical asset IDs | TP/SL and Stop-Limit use the same mapping |

The current `crypto_assets` row can receive an internal `asset_id` while retaining `coingecko_id` as a unique provider mapping. A separate provider-mapping table is preferable if additional data providers or provider-ID changes are expected.

## 3. Pair and UI behavior

- Keep `display_symbol` non-unique. The same ticker may appear on more than one canonical asset.
- A pair's action/route key is `pair_id`, not a ticker-derived string.
- The display label can remain familiar (for example BTC/USDT), while asset name, Persian name, provider identity and logo disambiguate rows that share a ticker.
- CoinGecko price requests use the exact provider ID mapped to `asset_id`; no symbol-only provider lookup may choose a canonical asset.
- Price rows are keyed by `pair_id` and include provider-observed time separately from local receive/process time.
- UI market rows, trade forms, portfolio, order history and balances must resolve by canonical IDs. Display strings are snapshots for humans only.

## 4. Financial RPC and worker contract

Every market/limit/conditional/stop-limit entrypoint accepts or resolves an authoritative `pair_id`. It must:
1. load the enabled pair and canonical base/quote IDs from the database;
2. validate the active canonical asset and supported USDT quote;
3. validate a positive, fresh, trusted price for that exact pair;
4. use canonical asset IDs for balances, reservations, fills and trades;
5. never infer an asset by parsing `pair_symbol` or trusting a client-supplied ticker-to-ID mapping.

All workers must use the same pair/asset mapping. Service-role workers keep their existing authorization boundary. Users still cannot write pair, price, balance, reservation or order tables directly.

## 5. Catalog admission invariant

Discovery is not admission. A new asset becomes an admitted/tradable catalog asset only when one transaction:
- resolves or creates its immutable `asset_id`;
- validates provider identity and display metadata;
- confirms a supported USDT price path and a valid provider-observed quote;
- creates exactly one canonical pair for the asset and quote;
- initializes price coverage/priority queue state;
- commits all linked records atomically.

If any requirement fails, the transaction must not silently create an active display-only catalog row. The UI should show an explicit pending/error state for a discovered but not yet admitted asset. The owner requirement applies to every asset admitted to the DigiArz catalog; no fixed count, rank, liquidity or manual activation cap is permitted. Identity and trusted-price checks remain mandatory.

## 6. Migration/backfill strategy — proposal only

1. Add immutable `asset_id` to catalog rows and create provider mapping records.
2. Add `pair_id` and canonical base/quote IDs to pair and price records.
3. Add canonical asset IDs to orders, trades, conditional orders, reservations and balances; retain old symbol/text columns temporarily as display snapshots and backward-compatibility fields.
4. Backfill each legacy pair using its existing `base_coingecko_id`, not by ticker alone.
5. Backfill historical ledger rows through the exact pair/order/reservation relationships. Any row that cannot be mapped uniquely must be quarantined for reconciliation; never guess from a duplicate ticker.
6. Move all RPCs/workers/UI reads and writes to canonical IDs.
7. Only after source-parity, regression and reconciliation tests pass, consider removing legacy ticker-based authority.

The earlier Production snapshot showed zero orders, trades, reservations and conditional orders, but the live counts must be rechecked immediately before any future approved migration. No assumption about future data is permitted.

## 7. Required disposable tests

- Two distinct canonical assets sharing one display ticker receive distinct `asset_id` and `pair_id` values and distinct prices.
- Buy/sell for each duplicate-ticker asset changes only its own balance.
- Limit orders, reservations, partial fills, TP/SL, OCO and Stop-Limit retain the correct canonical IDs throughout worker execution.
- A client cannot substitute another asset ID for a pair or price.
- A duplicate provider ID cannot map to two canonical assets; a ticker collision does not merge assets.
- Missing provider mapping, stale/missing observation timestamp, unsupported quote, disabled asset, disabled pair or invalid price fails closed.
- Concurrent admission of the same provider asset is idempotent; concurrent conflicting identity admission cannot create two mappings.
- Portfolio, order history, asset search and market rows display same-ticker assets distinctly without relying on synthetic aliases.
- Legacy backfill refuses ambiguous symbol-only rows and leaves financial totals unchanged.

## 8. Release gates and non-actions

This document is an architecture proposal only. It creates no SQL migration and authorizes no Production write. No schema, RPC, worker, Edge Function, Cron, pair, price, balance, order, reservation, grant, RLS policy, infrastructure, deployment or release was changed. No `db push`, merge, APK/Pages release or paid service change is authorized. Any implementation or Production rollout requires separate owner approval after the disposable end-to-end tests and a reviewed migration plan.


## Disposable proof-of-concept status (2026-11-27)

- First isolated SQL proof: `supabase/tests/canonical_asset_identity_candidate.sql`.
- It models two canonical assets with the same DOT display ticker and same DOT/USDT display pair, but different immutable asset IDs, provider IDs, pair IDs, price rows and balances. Market buy/sell uses pair_id and stores canonical IDs on orders/trades; stale price and duplicate provider ID are rejected.
- GitHub Actions run 46033780380 on commit `c74bdb268c09c97b86c0dfd3131e830b8a836f13` passed all 25 workflow steps, including this fixture and the separate fair-scheduler concurrency test.
- Scope limitation: this proof covers Market buy/sell only. Limit reservations, TP/SL, OCO, Stop-Limit, worker authorization, RLS, catalog admission concurrency, portfolio/UI mapping and a safe Production backfill are not yet implemented or tested. This remains a disposable prototype, not a Production migration.
