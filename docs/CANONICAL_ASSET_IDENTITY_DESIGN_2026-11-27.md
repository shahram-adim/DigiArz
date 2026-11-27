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


### Limit-order prototype extension (2026-11-27)

- The disposable fixture now also models limit-order placement, quote/base reservations by canonical `asset_id`, pair-keyed worker execution, fee-aware release of unused quote reservation, and stale-price retry without releasing the wrong asset.
- It tests one buy Limit and one sell Limit on two same-ticker assets and confirms each reservation and fill remains attached to the correct canonical ID. It also checks that a stale quote leaves the order pending and reserved until a fresh observation arrives.
- This extension is awaiting the current PostgreSQL 17 CI run; it is not yet a passed regression and is not Production code.

### Authoritative TP/SL and Stop-Limit source audit (2026-11-27)

The current migration bodies were fetched from this candidate branch, rather than inferred from the miniature canonical fixture:

- 20261113162051_add_demo_take_profit_stop_loss_engine.sql defines conditional_orders with symbol, and the placement RPC derives v_base by removing the USDT suffix. It checks demo_trading_pairs.pair_symbol, reserves order_reservations.asset, and reads/updates asset_balances.asset using text tickers. process_conditional_orders() reads the price by symbol and delegates execution to the existing ticker-based Market engine.
- 20261113181827_add_stop_limit_order_engine.sql extends the same conditional table. place_stop_limit_order() derives the base ticker, checks pair_symbol, and creates a text-asset reservation. process_stop_limit_orders() finds market_prices by symbol and delegates triggered children to ticker-based place_limit_order(). Parent/child linkage is by order UUID, but neither side carries canonical base/quote asset IDs or a canonical pair ID.
- These authoritative functions therefore remain incompatible with duplicate-ticker canonical ledger identity even though the separate Market/Limit disposable prototype passes. The real TP/SL and Stop-Limit call chains must be upgraded together; simply adding asset_id to a parent row or changing display symbols is insufficient.
- The current order_kind check includes take_profit, stop_loss, and stop_limit only. There is no OCO order kind or linked TP/SL sibling lifecycle in these migrations; OCO must be designed/tested separately, not assumed covered by TP/SL.
- Required next source-parity work: carry pair_id, base_asset_id, and quote_asset_id through conditional parent/child orders, reservations, trades and worker calls; key price lookup by pair; retain service-role-only worker ACLs, RLS, account-active guards, advisory/row locks, retry/fail-closed behavior, and existing one-minute worker cadence. Do not edit Production or run migrations as part of this design/test stage.


### CI source-parity boundary (2026-11-27)

Inspection of .github/workflows/exact-decimal-tests.yml shows an important limit on the passing CI claim:

- The canonical identity step creates a fresh database and executes only supabase/tests/canonical_asset_identity_candidate.sql. That file creates its own isolated canonical_asset_candidate schema and miniature functions; it does not apply the authoritative production migrations.
- Existing TP/SL and Stop-Limit integration steps load supabase/tests/exact_decimal_stop_limit_setup.sql plus supabase/drafts/2026-11-15_exact_decimal_entrypoint_candidates.sql and related draft worker SQL. They validate the exact-decimal candidate, not the current 2026-11-13 authoritative TP/SL and Stop-Limit migration bodies.
- Therefore run 46036165275 proves that the canonical prototype fixture compiles and passes in PostgreSQL 17, but it does not prove canonical identity is integrated with actual TP/SL/Stop-Limit SQL, nor that the production migrations themselves are compatible with duplicate ticker IDs.
- A dedicated source-parity harness is required: bootstrap the real schema dependencies, apply or extract the exact authoritative migration definitions in a disposable database, then apply the canonical-ID candidate and exercise the real RPC/worker call graph. Where migrations cannot be applied verbatim because of Supabase-only dependencies, the harness must document and assert each dependency substitution rather than silently replacing financial functions with miniature lookalikes.
- Until that harness exists and passes, mark canonical identity as prototype-only and all-catalog trading as not implemented end-to-end.
