# Canonical pair-ID consumer inventory and versioned RPC contract — 2026-11-28

**Status:** source-derived inventory and candidate API contract only. No application code, migration, or Production object changed.

## Evidence boundary

- PR #67 branch: `plan/all-catalog-assets-tradable-2026-11-27`.
- The client source inspected is `index.html` (blob `33f4acf028b1cdf799a9b55643ef9d9b2bd0ac5b`); the earlier frontend audit also inspected `src/market-holdings.js` (blob `c778aa7e12a011b38d4ec09b9e78a9662cd426a9`).
- The authoritative Market/Limit function bodies were read from `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` on Main.
- This is a bounded checked-in-source inventory. It is not a complete inventory of all app clients, deployed Edge Functions, external service-role writers, or current live Production metadata.

## Confirmed client call sites and data dependencies

| Surface | Observed source contract | Canonical change required |
|---|---|---|
| Spot Market submit | One `execute_demo_trade` RPC call in `index.html`, with `p_symbol`, side, amount and price | Send stable `pair_id`; retain symbol only for display |
| Limit submit | One `place_limit_order` RPC call in `index.html`, with `p_symbol` | Send stable `pair_id`; retain symbol only for display |
| Market list attachment | `market_prices.symbol` joined to enabled `demo_trading_pairs.pair_symbol`; metadata then selected by `base_coingecko_id` | Return/use `pair_id` and canonical asset IDs; do not build an execution identity map keyed by symbol |
| Trade form / sellable balance | Market row selected by symbol; sellable base balance compared against ticker-derived `assetRows[].asset` | Select pair by ID and balance by canonical asset ID / verified ledger mapping |
| Active Limit / conditional / Stop-Limit UI | Price rows selected from `market_prices` by symbol; orders carry symbol | Fetch pair-keyed prices and preserve pair ID in order projections |
| Reservation reads | `get_my_order_reservations` is called from four inspected client locations; current returned `asset` text is used for display/interpretation | Preserve owner scope and 1–100 order-ID bound; add `asset_id` and `pair_id`; display resolved name/symbol separately |
| Holdings | `src/market-holdings.js` indexes by uppercased text `asset` and derives base by stripping `USDT`/`IRT` | Index holdings by immutable asset ID; display symbol/name from catalogue |
| Admin enable/disable | UI calls enable/disable RPCs using CoinGecko ID; captured disable source selects a pair by base CoinGecko ID but cleans up orders by `orders.symbol = pair_symbol` | Disable by exact pair ID; cancel/release only orders/reservations with that same pair ID |

The counts above are observed occurrences in the inspected `index.html`, not a claim that the entire repository or all deployed clients have been exhaustively counted.

## Authoritative Market/Limit blocker reconfirmed

The authoritative migration currently defines:

- `execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric)`;
- `place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric)`;
- `process_limit_orders()`, which selects price by `market_prices.symbol = orders.symbol`.

Market and Limit placement derive the base ledger text key by removing the `USDT` suffix. The worker also derives that base key from the order symbol and performs pair/price validation using `pair_symbol` and `market_prices.symbol`.

Thus adding an asset-to-ledger mapping alone is insufficient. A pair ID must enter through the RPC, persist on the order, select the price row, and remain attached through trade, reservation, worker and cancellation. The existing financial semantics must remain intact: authenticated user and active-account checks, fee helper, Market gross/fee rounding, USDT wallet plus base asset ledger, durable reservation lifecycle, 25%-of-original Limit fill cap, advisory lock, row-locking, and transaction journal.

## Candidate versioned API contract (not implemented)

Prefer explicitly versioned RPC names rather than overloading the existing PostgREST function signatures:

- `execute_demo_trade_by_pair(p_pair_id uuid, p_side text, p_amount numeric)`
- `place_limit_order_by_pair(p_pair_id uuid, p_side text, p_amount numeric, p_limit_price numeric)`

Candidate contract rules:

1. Resolve the pair by immutable `pair_id`; require it enabled and resolve exact `base_asset_id` / `quote_asset_id` from that pair.
2. For the initial supported quote path, require the canonical quote asset to resolve to the existing USDT wallet ledger. Do not silently introduce another quote ledger.
3. Resolve the base asset to one verified, unique ledger key. Reject pending, ambiguous, quarantined, or conflicting mappings before touching balances or financial rows.
4. Select execution price by `market_prices.pair_id`; enforce the existing one-minute freshness and positive-price checks.
5. Persist `pair_id`, `base_asset_id`, and `quote_asset_id` on orders; copy the exact tuple to trades and reservations. Enforce same-pair parent/child identity for conditional and Stop-Limit flows.
6. Worker selection, price lookup, reservation validation, settlement, cancellation and admin-disable cleanup must use the stored pair/asset IDs, never re-resolve identity from a display ticker.
7. Keep the current `symbol` snapshot for historical display/API compatibility; it is not a key.
8. Keep legacy RPCs as compatibility wrappers only if the supplied symbol resolves to exactly one enabled pair. If zero or multiple pairs match, fail closed with an explicit ambiguity error. Do not silently choose the first row.
9. Adapt client read models before enabling duplicate display symbols: market list, holdings, sell sizing, open-order price/freshness, reservation views, history and admin lifecycle.
10. Do not backfill, split, merge, rename or reattribute existing balances/reservations automatically. Ambiguous legacy rows remain quarantined for separately reviewed reconciliation.

## Newly highlighted admin lifecycle risk

The captured `admin_disable_market_pair(text,text)` source identifies a selected pair by CoinGecko ID but scopes order and conditional cleanup by display `symbol`. If duplicate pair symbols are allowed, disabling pair A can affect pair B. The next disposable regression must seed two distinct pair IDs with the same display symbol and prove that disabling A releases/cancels only A's parent/child orders and reservations.

## Remaining evidence gates

- Complete repository-wide inventory of every read/write of `market_prices.symbol`, `orders.symbol`, `asset_balances.asset`, and `order_reservations.asset`, including non-HTML clients and generated types.
- Recover and reconcile missing applied migration sources and timestamp mismatches before any deployable schema proposal.
- Obtain current Production metadata-only fingerprints for functions, tables/constraints/indexes, triggers, views, policies, grants, Cron and deployed Edge Function versions; historical snapshots are not current parity evidence.
- Build the versioned RPC/worker/cancellation candidate against the exact authoritative Market/Limit migration in disposable PostgreSQL, then adapt the real TP/SL and Stop-Limit harnesses.
- Run duplicate-ticker end-to-end and two-session races on the exact candidate commit. No runtime PASS is claimed here.

## Safety boundary

No SQL was executed in Production; no business/user rows were read; no migration, DDL, backfill, RPC, worker, Cron, Edge Function, RLS/ACL, Auth, wallet, balance, order, trade or reservation was changed. No merge, rebase, db push, deploy, APK/Pages publication or cost was incurred.
