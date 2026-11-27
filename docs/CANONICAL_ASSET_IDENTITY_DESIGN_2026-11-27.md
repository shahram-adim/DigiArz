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



## Catalog-admission and pair-admin call-chain audit — historical Recovery-Test source

A metadata/function-definition-only read on the restored Recovery-Test snapshot recovered these function fingerprints. They are historical source evidence, not proof of the current Production definitions:

| Function | Snapshot fingerprint | Relevant behavior / canonical requirement |
|---|---|---|
| `refresh_crypto_assets()` | 8,885 bytes; MD5 `f14765ffd1166380f58e391b34163259` | Upserts by `coingecko_id` and updates mutable `crypto_assets.symbol` from provider data. The recovered snapshot had no unique symbol constraint; duplicate tickers can persist. Every provider mapping must resolve to immutable `asset_id`, not symbol. |
| `private.auto_list_verified_exchange_asset()` | 1,298 bytes; MD5 `49880c0892cad6081acb6ce071090a5d` | Trigger on matched active exchange observations inserts `admin_market_listings` only if exactly one active catalog asset has that ticker and no curated/pair collision exists. This is a product curation gate, not a financial identity guarantee. |
| `admin_enable_market_pair(text)` | 4,131 bytes; MD5 `848f7c1ebe114c558c1ce73e76dd13bd` | Requires an admin-curated listing, active asset, metadata age <=24h, volume >= USD 1,000,000, rank <=2,000 when present, no pair-symbol collision, and fresh CoinGecko price <=2 minutes. Volume/rank/curation gates conflict with the owner's all-admitted-assets requirement; valid identity and fresh trusted price remain mandatory. |
| `admin_disable_market_pair(text,text)` | 2,858 bytes; MD5 `07ff2862b133f6dbeb3c0cf5d33c5878` | Finds the selected pair by `base_coingecko_id`, but cancels conditional orders, reservations and orders by `orders.symbol = pair_symbol`, then disables by `pair_symbol`. If same-label pairs are admitted, this symbol-wide cleanup can affect a different canonical asset. All cancellation and reservation cleanup must be scoped by `pair_id` and canonical asset IDs. |
| `refresh_market_prices()` | 3,101 bytes; MD5 `4c45f1aab59eb15194638bd930015e51` in the historical snapshot | Historical body only. The later checked-in 515-ID migration is a different definition and must remain the source for current source review. It builds provider mappings from `pair_symbol/base_coingecko_id`; a pair-keyed price store and deterministic provider-to-pair mapping are required. |

### Updated admission/admin invariant

- Discovery, exchange matching, curated listing, canonical catalog admission and pair provisioning must become one deterministic lifecycle. A ticker collision must not cause an otherwise valid catalog asset to be permanently display-only, nor may the system pick one asset by symbol.
- Product gates such as curated-list membership, minimum 24h volume and top-2,000 rank must not block an admitted valid asset. Financial gates remain: immutable identity mapping, supported quote, active asset/pair, trusted positive fresh pair price, account authorization and reservation/accounting invariants.
- Pair disable must operate on a single `pair_id`; it must never cancel by display symbol. Conditional parent, Stop-Limit child, ordinary Limit child and reservations must all match the same canonical pair/base/quote IDs.
- The read-only fingerprint now includes catalog writer/admin functions so a future current Production snapshot can verify whether these historical definitions still match. No function from Recovery-Test is copied into Production or used as a live-source claim.


## Authoritative TP/SL and Stop-Limit identity call-chain — source review 2026-11-27

Reviewed the exact mainline migration sources:
- `20261113162051_add_demo_take_profit_stop_loss_engine.sql` (blob `3360c21a69b7fae83a7f2494428367d1b7658e81`)
- `20261113181827_add_stop_limit_order_engine.sql` (blob `3f421c6380630d74b846cd66dc7b121786237c0f`)

### TP/SL source behavior that must be migrated together
- `place_conditional_exit_order(text,...)` accepts `p_symbol`, derives `v_base=left(symbol,length-4)`, validates `demo_trading_pairs.pair_symbol`, reads `asset_balances.asset` and active reservations by ticker text, then creates the parent `orders`, `order_reservations` and `conditional_orders` rows with only `symbol`.
- `process_conditional_orders()` reads `market_prices` by `symbol`, validates reservation asset against the ticker-derived base, releases the parent reservation in a subtransaction, sets the user's JWT claims, calls `execute_demo_trade(symbol,...)`, and records the returned execution order ID on `conditional_orders`.
- `cancel_conditional_exit_order(uuid)` locks conditional parent and reservation by order/user, releases the unconsumed reservation, then updates parent and conditional states. The cancellation must additionally prove that reservation, parent and pair/base/quote identity all agree.
- Therefore canonical migration cannot be a UI adapter: placement, trigger worker, called Market RPC, cancellation, parent/child linkage, and reservation validation must all carry the same `pair_id/base_asset_id/quote_asset_id`. The current symbol-only path cannot disambiguate duplicate ticker pairs.

### Stop-Limit source behavior that must be migrated together
- `place_stop_limit_order(...)` is also symbol-input based; it derives base ticker text and writes the conditional parent and reservation using text asset/symbol.
- `process_stop_limit_orders()` reads price by symbol, validates reservation asset against the ticker-derived base (or USDT for buys), releases the parent reservation transactionally, sets JWT claims and calls `place_limit_order(symbol,...)` to create the child, then stores `execution_order_id` on the conditional row.
- The synchronization pass joins parent and child by IDs and copies child fill/status to the parent. The source lock clause is `FOR UPDATE OF c,parent SKIP LOCKED`; the child is read but not included in that lock list. Preserve and explicitly test the authoritative lock semantics unless a separately reviewed change is approved.
- `cancel_stop_limit_order(uuid)` has two distinct branches: pending parent cancellation releases its reservation; triggered cancellation calls `cancel_limit_order(child_id)`, then synchronizes parent and conditional status from the child. Pair identity must be checked across parent, conditional row, child, reservation and called Limit RPC before cancellation or synchronization.

### Required canonical invariants
1. Parent order, conditional row, execution child, reservation and trade must share the same immutable user/pair/base/quote tuple. Enforce with composite FKs where possible, not only PL/pgSQL checks.
2. Price reads and trigger evaluation must use `pair_id`, not display symbol.
3. A trigger worker may only create a child for the exact parent pair; it must not resolve the child by ticker alone.
4. Pair disable must cancel/release only rows carrying that `pair_id`; same-label pairs remain untouched.
5. Keep existing advisory locks, row-lock order, SKIP LOCKED semantics, bounded retry behavior, account-active guards, RLS, SECURITY DEFINER ownership/search_path and service_role-only worker grants source-faithful.
6. Backfill of historical symbol-only rows remains ambiguous when one ticker maps to multiple canonical assets. Quarantine ambiguous rows; never guess a mapping or merge balances.

### OCO scope boundary
No authoritative OCO table, placement/cancellation RPC or worker was found in the reviewed source search. OCO must be designed as a separate linked-order state machine (one parent group, two mutually exclusive legs, atomic winner/loser transition, reservation ownership and race/idempotency guarantees). It is not implemented by the TP/SL or Stop-Limit candidate above and must not be claimed as complete.

This is source-review/design evidence only. No migration or Production function was changed or executed.


## Current Production metadata-only baseline — 2026-11-27

Project gfoaubfilhttnwjykaox was read as ACTIVE_HEALTHY, PostgreSQL 17.11.0.018, region us-west-2. The following was captured through list_tables and pg_catalog metadata queries only. No order, trade, reservation, balance, wallet or user rows were selected.

### Live canonical-identity schema facts

| Relation | Live identity / key shape | Consequence |
|---|---|---|
| public.crypto_assets | PK coingecko_id; mutable symbol text | CoinGecko ID is the stable provider key, but it is not yet a first-class internal UUID. Never use symbol as asset identity. |
| public.demo_trading_pairs | PK pair_symbol; UNIQUE base_coingecko_id; quote constrained to USDT | Pair identity is still display ticker; this key cannot represent two distinct assets with the same pair label. |
| public.market_prices | PK symbol | Two canonical pairs with the same display symbol cannot hold separate price observations. |
| public.orders | symbol text; unique (id,user_id); check filled_amount+remaining_amount=amount | No pair_id/base_asset_id/quote_asset_id; order-to-pair identity is not referentially enforced. |
| public.trades | symbol text; FK order_id to orders(id) | Trade history has no canonical pair/asset references. |
| public.conditional_orders | symbol text; unique order_id; execution_order_id FK to orders | Parent/child linkage exists, but does not enforce same user/pair/base/quote tuple. |
| public.order_reservations | text asset; FK (order_id,user_id) to orders(id,user_id); accounting checks | Owner linkage is enforced, but reservation asset is ticker text, not canonical asset ID. |
| public.asset_balances | text asset; UNIQUE (user_id,asset) | Duplicate tickers cannot be represented as distinct balance rows for the same user. |
| public.wallets | unique user_id; USDT and IRR balances | Quote-wallet remains separate from base-asset balance identity. |

The target financial tables above have RLS enabled but not FORCE RLS. Existing policies are SELECT-only owner/public-market reads as appropriate; no canonical columns or pair-composite foreign keys are present in this live metadata snapshot.

### Current Production function fingerprints and execution boundary

Read-only pg_get_functiondef + pg_proc metadata was captured for these exact live definitions. Each new snapshot under supabase/tests/canonical_identity_live_*_snapshot.sql is test-only and explicitly not a migration.

| Function | Live md5 | EXECUTE anon | authenticated | service_role |
|---|---|---:|---:|---:|
| execute_demo_trade(text,text,numeric,numeric) | 4289e358b0c7293fc33f86c2511486d7 | no | yes | yes |
| place_conditional_exit_order(text,text,numeric,numeric) | e4de4667d89e6663f04d92d47ac4d5cf | no | yes | yes |
| cancel_conditional_exit_order(uuid) | efa4c8a200d299f76b0d2cbe2d0b49e9 | no | yes | yes |
| process_conditional_orders() | 5cfbf0e2e73474ae64e42643b3feb28a | no | no | yes |
| place_stop_limit_order(text,text,numeric,numeric,numeric) | d6f4ff7478b83fbabbab519c7c711bcd | no | yes | yes |
| cancel_stop_limit_order(uuid) | 82cedc2c442b0c826a8684044aed5f8d | no | yes | yes |
| admin_disable_market_pair(text,text) | 07ff2862b133f6dbeb3c0cf5d33c5878 | no | yes | yes |
| refresh_market_prices() | 3788666d57957a66bf59031f54ceff03 | no | no | no (postgres only) |
| place_limit_order(text,text,numeric,numeric) | 3eab167c47bf8ff2e1705b9f243380ec | no | yes | yes |
| cancel_limit_order(uuid) | 69360684173b6aabebc5ff4e4de2eed9 | no | yes | yes |
| process_limit_orders() | 00ab429596fb99392666632967cde9c0 | no | no | yes |
| process_stop_limit_orders() | 66357ab4a2247019f22a8b6ab6eac6fe | no | no | yes |

All listed functions are owned by postgres, SECURITY DEFINER and use an empty search_path, except refresh_market_prices(), which uses search_path=pg_catalog. This is the ACL/owner baseline to preserve; do not broaden worker execution to authenticated or anon. A Node source-contract test now pins the eight newly captured fingerprints and asserts the known ticker-keyed call chains so any silent source drift fails CI.

### Live implementation blockers confirmed by the captured source

- Market entrypoint derives base from the trailing USDT ticker, validates demo_trading_pairs.pair_symbol, and reads market_prices.symbol.
- TP/SL placement and worker still store/read symbol; the worker calls execute_demo_trade(v_cond.symbol,...).
- Stop-Limit placement still validates by pair_symbol; cancellation follows the child by execution_order_id and calls cancel_limit_order(child_id), but does not verify a canonical pair tuple.
- Pair disable cancels conditional/order/reservation rows using orders.symbol = v_pair.pair_symbol; this is the live symbol-wide cleanup hazard for same-label pairs.
- Market price refresh maps pair_symbol to CoinGecko IDs and upserts market_prices with ON CONFLICT(symbol). KuCoin/Gate.io observations are also admitted by symbol.

The newly added tests/canonical-asset-production-source.test.js validates exact md5 fingerprints and explicitly asserts these legacy paths. This test documents the current behavior to be replaced; it does not mark the behavior as acceptable or claim canonical support is already deployed.

### Separate Supabase Advisor finding — backup-table RLS

The metadata listing returned a CRITICAL Advisor warning because private.digiarz_pg_net_queue_backup_20261121 and private.digiarz_pg_net_response_backup_20261121 have RLS disabled. A follow-up metadata-only privilege check found:
- both tables have no direct SELECT/INSERT/UPDATE grants to anon, authenticated or service_role; the only table grants returned were to postgres;
- authenticated has USAGE on schema private, while anon does not;
- pgrst.db_schemas was unset in the queried setting.

Therefore the Advisor's broad exposure warning is not corroborated by the current direct table grants; public Data API reachability was not established. RLS-disabled remains a defense-in-depth finding and should be reviewed separately. No RLS change was applied: enabling RLS without an access design could block intended recovery access, and any remediation requires explicit owner approval.

This live capture supersedes the older Recovery-Test schema snapshot for the relations/functions listed above. It does not resolve the missing applied Migration SQL inventory (17 absent source files and timestamp mismatches remain a separate deployment blocker).


## Catalog discovery, admission, and display dependency inventory — live Production 2026-11-27

A second metadata-only catalog scan found 33 public/private functions whose source references the catalog, pair, price, order, reservation, balance or conditional-order relations. The canonical migration must account for the complete catalog path, not only the trading RPCs.

The relevant catalog/discovery chain was captured as test-only live snapshots and pinned by tests/canonical-asset-catalog-source.test.js:
- Catalog refresh: public.refresh_crypto_assets() (f14765ffd1166380f58e391b34163259) upserts by coingecko_id but updates mutable symbol from provider response.
- Exchange observation auto-listing: private.auto_list_verified_exchange_asset() (49880c0892cad6081acb6ce071090a5d) auto-lists only when exactly one active catalog asset has the ticker and rejects curated/pair ticker collisions.
- Listing uniqueness trigger: private.enforce_unique_admin_market_listing_symbol() (6e9a7e9f7d8cd5f0ac20f3216ee5f0b3) blocks another curated asset with the same ticker and a collision with an existing pair symbol.
- Pair auto-activation: private.auto_activate_verified_exchange_pairs() (fd177baeee1a5bdd927458413f69bfb6) joins curated listings and market_prices by ticker; it also requires volume >= USD 1,000,000, rank <= 2,000 when present, fresh CoinGecko price <= 2 minutes and a recent matched exchange observation.
- Admin pair activation: public.admin_enable_market_pair(text) (848f7c1ebe114c558c1ce73e76dd13bd) applies the curated-list, volume, rank and ticker-price gates before writing pair_symbol.
- Market display/read: public.get_crypto_assets(text,integer,integer,text) (b85d4a1073e425c2ac29899152168cf2) reads catalog rows; public.get_crypto_market(text,integer,integer,text,boolean) (6cf991bfee5e7fb759fec4112962f788) derives trade_enabled using ticker-keyed pair and price relations.
- Exchange discovery/matching: public.process_iran_exchange_asset_sync() (889c3728e54154a799e55ed8b9bc2edb) stages observations and uses ticker/name/alias candidate matching, explicitly preserving ambiguous status; public.get_exchange_discovered_market_assets() (87f9f56829abb50b2ff1fb878684e89c) exposes staged discovery.
- Additional captured support paths: private.request_market_price_overflow(), public.admin_add_market_listing(), public.admin_review_market_listings(), public.admin_search_market_assets(), public.get_admin_market_listings(), public.process_bit24_exchange_sync(), public.recover_stale_crypto_assets_sync(), public.refresh_crypto_assets_toman(), and public.request_market_price_refresh().

### Requirement impact

- The current pipeline has two distinct kinds of exclusion that must not be conflated: unresolved identity ambiguity (a legitimate safety hold) and product-selection gates (curated membership, minimum volume and rank). The owner's rule requires every valid catalog asset, present or future, to become tradable; product-selection gates must not permanently keep a valid asset view-only.
- Ambiguous exchange matches must remain quarantined until a deterministic canonical provider mapping is proven. Never auto-pick by ticker or merge balances.
- Provider symbol changes must update display metadata, not internal asset identity. CoinGecko ID mapping is a provider identity; an internal immutable asset UUID should be the financial FK.
- Pair activation must be keyed by canonical asset + quote asset and pair_id. Price refresh from CoinGecko, KuCoin and Gate.io must resolve provider observations to that pair ID before upsert; market display must bind to the same pair_id.
- A ticker collision should no longer block a distinct asset's catalog admission or pair activation. Display labels can remain duplicated; financial keys cannot.
- The live catalog source snapshots and hash assertions are TEST FIXTURES ONLY. They record the current behavior to be replaced, not a production patch.

### Active-account trigger boundary

A separate read-only trigger query confirmed:
- public.orders has BEFORE INSERT trigger guard_active_account_orders;
- public.trades has BEFORE INSERT trigger guard_active_account_trades;
- public.transactions has BEFORE INSERT trigger guard_active_account_transactions;
- all three call private.guard_active_account_writes(), live md5 29b8e23c1de8eb4762a8cf1a9c9343ce, owner postgres, SECURITY DEFINER, empty search_path.

This guard must remain attached to the same financial write paths after canonical columns and functions are introduced. A test-only snapshot and hash/behavior assertion were added.

### Migration-ledger reconciliation recheck

The current live Supabase migration ledger and GitHub main tree were re-compared on 2026-11-27:
- 55 applied ledger entries; 40 SQL files under supabase/migrations/.
- 17 applied migrations still have no corresponding local SQL source.
- 20 local filenames have timestamp prefixes that differ from their applied ledger versions.
- 2 local-only migrations remain unrecorded remotely (the KuCoin and Gate.io intermediate market-price replacements).
This is unchanged from the last recorded reconciliation. It remains a hard stop for any db push/replay. Do not repair migration history or replay the local-only market-price files.


### Additional display/API correctness issue confirmed

The live public.get_crypto_market(...) function computes trade_enabled from a positive market_prices row for ca.symbol || 'USDT' updated within one minute. It does not join demo_trading_pairs and does not check is_enabled. Thus the UI's trade_enabled flag is currently a ticker-price freshness indicator, not proof that a supported pair is enabled. The canonical read API must derive tradability from the same active pair_id + supported quote + fresh pair-price relation used by order entry; do not rely on the current flag.
