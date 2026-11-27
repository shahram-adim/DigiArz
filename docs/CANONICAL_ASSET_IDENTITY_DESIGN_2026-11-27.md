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



## Exact authoritative conditional call-chain audit — 2026-11-27

This section records a second pass over the checked-in migration bodies, not an implementation claim:

| Layer | Exact source function | Current identity used | Required canonical replacement |
|---|---|---|---|
| TP/SL placement | `place_conditional_exit_order(text,text,numeric,numeric)` in `20261113162051_add_demo_take_profit_stop_loss_engine.sql` | `p_symbol`, suffix-derived `v_base`, `demo_trading_pairs.pair_symbol`, `asset_balances.asset`, `order_reservations.asset` | Accept/resolve `pair_id`; load base/quote IDs from the enabled pair row; reserve by `asset_id`; persist all three IDs on parent and conditional row |
| TP/SL execution | `process_conditional_orders()` in the same migration | `conditional_orders.symbol`, `market_prices.symbol`, ticker-derived reservation validation; calls `execute_demo_trade(symbol,...)` | Load pair and assets by immutable IDs; read price by `pair_id`; validate reservation asset ID; execute Market with the same pair/asset IDs |
| TP/SL cancellation | `cancel_conditional_exit_order(uuid)` | Parent UUID + text-asset reservation | Preserve parent/row locking and exact one-row transitions, but validate/release the reservation for the stored canonical asset ID |
| Stop-Limit placement | `place_stop_limit_order(text,text,numeric,numeric,numeric)` in `20261113181827_add_stop_limit_order_engine.sql` | suffix-derived base ticker, pair_symbol, text reservation asset | Pair ID is the authoritative input; reserve base or quote asset ID; parent order and conditional row persist pair/base/quote IDs |
| Stop-Limit trigger | `process_stop_limit_orders()` in the same migration | `conditional_orders.symbol`, `market_prices.symbol`, text reservation validation; calls `place_limit_order(symbol,...)` | Pair-keyed price and ID reservation validation; create child through canonical Limit entrypoint with the same IDs; assert parent/child ID equality |
| Stop-Limit cancellation/sync | `cancel_stop_limit_order(uuid)` and the triggered-child sync loop | UUID parent-child relation, but child/parent rows do not carry canonical IDs | Preserve UUID linkage, copy/fail closed on mismatched pair/base/quote IDs, and keep cancellation-vs-worker serialization |
| Market execution | `execute_demo_trade(text,text,numeric,numeric)` in `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` | pair_symbol, symbol-keyed market price, suffix-derived base, text balances/reservations, symbol-only orders/trades | Canonical pair and asset IDs must drive price, balances, orders, trades and transactions; display symbol is a snapshot only |
| Limit placement/worker | `place_limit_order(text,text,numeric,numeric)` and `process_limit_orders()` in the same migration | pair_symbol, ticker-derived base, symbol-keyed price, text reservation and asset balance | Canonical pair/asset IDs must flow from placement through partial fills, reservation consumption/release and trades |

### Structural consequences

1. Merely adding nullable UUID columns is unsafe. Every write path must populate and validate them, and workers must reject rows whose IDs do not agree with the referenced pair.
2. The current pair model's `pair_symbol` uniqueness and the current ticker-derived price lookup cannot distinguish two canonical assets that share the same display ticker/pair label. The canonical model must make `pair_id` authoritative and allow display labels to be non-unique; all indexes, conflict targets and upserts must be reviewed together. Do not remove legacy uniqueness until every reader/writer has moved and duplicate-ticker reconciliation is complete.
3. A compatibility adapter that accepts a symbol and chooses a pair by ticker is not an acceptable canonical entrypoint. If legacy RPC signatures must remain temporarily, they may resolve only when exactly one enabled pair matches; zero or multiple matches must fail closed.
4. Conditional parent and Stop-Limit child must carry the same `pair_id/base_asset_id/quote_asset_id`. A child with a different pair identity must never be accepted even if its display symbol matches.
5. The successful authoritative harness still substitutes downstream Market/Limit entrypoints with explicitly isolated adapters. It proves conditional/Stop-Limit lifecycle logic and its stale/malformed-reservation guards, not canonical-ID source parity or actual Market/Limit settlement.
6. Existing passing CI runs `46038710233` (commit `966a7ce`) and `46038816951` (latest code commit `ce83b536`) both completed SUCCESS. Steps 17–22, 25 and 26 all passed in both. The new stale-price and malformed-reservation assertions therefore pass in the authoritative conditional/Stop-Limit disposable harness. They do not close the canonical-ID integration gap.

### Next implementation gate

Build the next candidate as a coordinated set, not piecemeal nullable columns: (a) canonical pair/asset schema and pair-keyed price source; (b) canonical Market and Limit RPC/worker bodies; (c) canonical TP/SL and Stop-Limit placement/worker/cancel bodies calling those engines; (d) RLS/grant and active-account invariants; (e) exact migration-source parity plus duplicate-ticker, stale-price, malformed-reservation, retry, and two-session cancel/worker race tests. OCO remains a separate linked-order state machine. Until all pieces pass in disposable PostgreSQL, the owner requirement is not end-to-end implemented.



## Recovered schema metadata reference (Recovery-Test snapshot only) — 2026-11-27

A metadata-only `list_tables(verbose=true)` read was made against the existing isolated `DigiArz-Recovery-Test` project (`zrriqwyolcjhbappocuw`, PostgreSQL 17.11.0.019, ACTIVE_HEALTHY). No table rows or user records were queried, and this project was not used for tests. This is a restored historical backup snapshot, not a current Production schema assertion.

The returned metadata confirms these structural facts in that snapshot:

- `crypto_assets`: primary key `coingecko_id`; `symbol` is ordinary text and the table metadata reports no symbol uniqueness constraint. Provider ID and display ticker are distinct concepts.
- `demo_trading_pairs`: primary key `pair_symbol`; `base_coingecko_id` is separately unique and FK-references `crypto_assets.coingecko_id`; `quote_asset` is constrained to USDT. This schema cannot represent two enabled canonical pairs with the same display pair label.
- `market_prices`: primary key `symbol`, not pair UUID. It is therefore a symbol-addressed price relation in this snapshot.
- `orders.symbol`, `trades.symbol`, `conditional_orders.symbol` and `order_reservations.asset` are text columns. `asset_balances.asset` is also text. Canonical asset IDs are absent from these rows.
- `orders`, `trades`, `conditional_orders`, `order_reservations`, `asset_balances`, `wallets`, `market_prices`, `crypto_assets` and `demo_trading_pairs` all report RLS enabled in this snapshot.

This confirms the design direction, but not current Production parity: Recovery-Test was restored from a backup and its ACLs were deliberately omitted during restore. The next schema candidate must not copy its grants/owners blindly. Reconcile this metadata against an authorized current Production catalog snapshot when the service is stable, and separately recover the original base DDL/missing migration sources. Do not query business rows or use this backup project as a test database.



### Index/constraint/trigger detail from the same historical snapshot

A read-only catalog query on Recovery-Test (PostgreSQL 17.11) also captured exact indexes, constraints, triggers and policies for the relevant tables. Important details:

- `demo_trading_pairs_pkey` is unique on `pair_symbol`; `demo_trading_pairs_unique_base` is unique on `base_coingecko_id`.
- `market_prices_pkey` is unique on `symbol`. A ticker collision cannot be represented as two independent price rows in this model.
- `crypto_assets_pkey` is unique on `coingecko_id`; `crypto_assets_symbol_idx` is only a non-unique lower(symbol) index.
- `asset_balances_user_asset_unique` enforces one text-asset balance per user. Canonical migration must replace the conflict target with `(user_id, asset_id)` while preserving no-duplicate-balance semantics.
- `order_reservations_order_unique` preserves one reservation per order; `order_reservations_order_user_fk` binds it to the same user as the parent order. Keep both invariants while adding the canonical asset FK.
- `orders_id_user_id_unique` is the referenced composite key for the reservation FK; the order accounting checks enforce filled + remaining = amount and bounded filled/remaining values.
- `conditional_orders_order_id_key` is unique; parent/conditional one-to-one relationship must remain. Stop-Limit child linkage remains a separate `execution_order_id` FK.
- The snapshot's three custom account-guard triggers are BEFORE INSERT on `orders`, `trades` and `transactions`, all calling `private.guard_active_account_writes()`. No custom trigger on `crypto_assets` was present in the returned relevant-table trigger set.
- RLS is enabled but not FORCE RLS on the listed tables in this snapshot. Policies include public/anon read for catalog/pairs/prices and own-row reads for financial tables. New canonical tables and ID columns must preserve the least-privilege model; workers stay service_role-only.

These are historical Recovery-Test facts, not current Production assertions. The restored project's ACLs were omitted; its role/function privileges are not a valid source for production grants. The source-faithful candidate must retain the current Production ACLs from a separate authorized catalog capture or authoritative migration source.
