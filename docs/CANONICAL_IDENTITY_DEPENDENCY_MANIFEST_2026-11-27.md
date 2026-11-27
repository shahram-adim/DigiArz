# Canonical Identity Dependency Manifest — 2026-11-27

**Status:** source-audit manifest / implementation gate. Not a migration, not executable SQL, and not approval for Production changes.

## Purpose

This manifest freezes the currently known dependency surface that must move together for the owner requirement: every asset admitted to DigiArz, now or in the future, can be bought and sold in the demo exchange. It prevents a partial rollout in which the UI displays canonical IDs while a privileged writer, RPC, reservation, price job, or worker still selects records by ticker.

A source hit is not automatically a writer. Each item below is classified by observed role and evidence boundary. Production definitions recovered by read-only inspection are distinguished from checked-in migration bodies and test adapters.

## Canonical identity contract

- `asset_id UUID`: immutable DigiArz identity.
- `(provider, provider_asset_id)`: unique external identity mapping to one `asset_id`.
- `pair_id UUID`: immutable trading route identity; references base and quote `asset_id`.
- Pair display symbol and asset ticker are labels only and may be non-unique.
- Price is keyed by `pair_id`; it stores provider-observed timestamp separately from local receive/process timestamp, provider/source, positive value, and validity state.
- Balance key is `(user_id, asset_id)`.
- Orders, trades, conditional parents/children, reservations and execution history carry and validate `pair_id/base_asset_id/quote_asset_id`; reservations additionally identify the exact `asset_id` reserved.
- The initial supported quote remains USDT. An asset without a supported, trusted, fresh USDT execution route is not yet admissible as tradable. Do not silently substitute catalog valuation for an executable pair quote.

## A. Catalog admission and mutation paths

| Path | Observed role | Current identity / hazard | Required canonical behavior |
|---|---|---|---|
| `public.refresh_crypto_assets()` | Confirmed Production catalog writer; exact applied body recovered read-only | Upserts by CoinGecko ID but mutates `crypto_assets.symbol` from provider response; does not provision a pair | Resolve provider mapping to immutable asset_id; symbol update cannot change identity; admission and pair provisioning must be atomic or explicitly pending |
| `private.auto_list_verified_exchange_asset()` | Trigger writer to `admin_market_listings` after matched exchange observation | Requires exactly one active catalog row for ticker; ticker collision can block or misdirect curation | Resolve observation to provider ID + asset_id; curated metadata must not be a prerequisite to financial eligibility |
| `private.auto_activate_verified_exchange_pairs()` | Pair provisioning/activation path | Curated-list, volume/rank, ticker uniqueness, fresh CoinGecko and exchange-observation gates; pair key is display symbol | Provision by pair_id and canonical asset IDs; remove product-only curation/volume/rank gates, retain identity, supported quote, trusted price and security checks |
| `public.admin_enable_market_pair(text)` | Admin pair activation RPC | Text/provider ID argument but pair conflict and price selection are symbol-oriented; applies curated/volume/rank gates | Admin action targets exact asset_id/pair_id; never resolve or mutate a pair by ticker |
| `public.admin_disable_market_pair(...)` | Admin pair disable and cancellation path | Historical/live audit found cancellation cleanup by `orders.symbol = pair_symbol`, although selected pair originated from CoinGecko ID | Disable one pair_id; cancel/release only orders and reservations whose canonical IDs match that pair |
| `public.process_iran_exchange_asset_sync()`, `public.process_bit24_exchange_sync()` | Exchange observation/matching writers | Match/stage using ticker/name/alias and preserve ambiguous state; observations are not canonical IDs | Store provider/exchange instrument identity; explicit reviewed mapping to asset_id; ambiguous matches remain unresolved, never guessed |
| Direct privileged table writes / external jobs | Not fully enumerated | SQL functions, Edge Functions, service_role and dashboard/operator writes may bypass repository search | Before implementation, complete grants/policy/trigger/Edge Function inventory; explicitly record unknown external writers |

**Important:** discovery is not admission. The owner rule applies to every asset admitted to the DigiArz catalog, not every unverified raw discovery observation. Admission cannot permanently exclude an otherwise valid catalog asset for rank, volume or curated-list status, but it must reject unresolved identity or unsupported/stale price routes.

## B. Price and market-data paths

| Path | Observed role | Current behavior / hazard | Required canonical behavior |
|---|---|---|---|
| `public.refresh_market_prices()` | Production scheduled price writer; Cron job 3 every minute | Provider response maps CoinGecko IDs / exchange symbols to `market_prices.symbol`; KuCoin/Gate.io can overwrite same ticker row; source priority is not deterministic | Pair-keyed price writes; provider ID-to-asset mapping; exact pair market mapping; deterministic source policy and provider-observed freshness |
| `private.request_market_price_overflow()` | Production overflow scheduler; Cron job 17 at minute offsets 5,15,...55 | Current live guard/back-pressure differs from checked-in historical migration; primary/overflow sequencing may starve IDs beyond first 515 | Durable cursor/batch state, fair retry and auditable requested-ID sets; no changes to current jobs before owner approval |
| `index-ts` Edge Function v3 | Price/catalog writer candidate identified in prior source inventory | Hardcoded symbol-oriented list / mapping requires complete current code review | Provider/pair IDs, not ticker list; versioned source mapping |
| `refresh-market-prices` Edge Function v5 | Price writer candidate identified in prior source inventory | Hardcoded symbol-oriented list / mapping requires complete current code review | Canonical pair mapping and source freshness; inventory exact deployed code and invocation grants |
| Cron jobs 3 and 17 | Active production schedulers | Critical existing cadence; must not be disabled or slowed as part of this work | Preserve cadence and semantics until separately reviewed and approved; tests use disposable PostgreSQL only |

Price freshness must use provider-observed time, not merely local `updated_at`. A positive `crypto_assets.current_price_usd` is catalog valuation and is not automatically an executable USDT pair quote. Five stale enabled pairs were found in the 2026-11-27 audit; do not reactivate or copy catalog valuation into pair prices as a workaround.

## C. Read APIs and user-visible projections

| Path | Current dependency | Required behavior |
|---|---|---|
| `public.get_crypto_assets()` | Catalog/provider rows and display ticker | Return stable asset_id and provider identity alongside Persian/English names and display ticker |
| `public.get_crypto_market()` | Joins catalog with ticker-keyed market_prices; current `trade_enabled` is effectively a fresh positive ticker-price indicator | Join canonical pair/asset IDs and pair-keyed price; `trade_enabled` only when pair is enabled, identity resolved, quote supported, and provider-observed price fresh |
| `public.get_admin_market_listings()` | Curated metadata and indicative prices; currently anon-executable SECURITY DEFINER | Preserve intended public/admin boundary only after owner decision; curated status is not the canonical identity |
| `public.get_exchange_discovered_market_assets()` | Pending/ambiguous/unmatched exchange discovery | Clearly distinguish discovery from admitted catalog; do not expose or imply tradeability until canonical mapping and pair checks pass |
| `public.get_my_order_reservations(uuid[])` | Owner-scoped, bounded (1–100) order IDs; returns ticker text asset | Return canonical asset_id and pair_id with owner-scoped order data; keep bounds and ownership checks |
| Market, portfolio, order history, trade form, active orders UI | Current symbol-oriented API contracts | Carry stable IDs end-to-end; show Persian/English labels and ticker as display only; duplicate tickers must remain distinct |

Security Advisor note: two anon-executable SECURITY DEFINER read functions and 23 authenticated-executable SECURITY DEFINER functions were observed. This manifest does not authorize blanket grant revocation or RLS changes.

## D. Financial RPCs, ledgers and workers

| Layer | Current authoritative path | Required coordinated change |
|---|---|---|
| Market placement/execution | `execute_demo_trade(text,text,numeric,numeric)` | Accept authoritative pair_id; validate active account, pair, trusted fresh pair price; mutate canonical balances; persist canonical IDs on order/trade/transaction |
| Limit placement | `place_limit_order(text,text,numeric,numeric)` | Pair ID input; reserve exact base/quote asset_id; canonical order fields |
| Limit worker | `process_limit_orders()` | Pair-keyed price; canonical partial-fill settlement, trade and reservation consumption; preserve row/advisory locks and accounting |
| Limit cancellation | `cancel_limit_order(uuid)` | Owner-scoped UUID plus canonical reservation identity; release exactly once |
| TP/SL placement | `place_conditional_exit_order(text,text,numeric,numeric)` | Pair ID; canonical parent/conditional IDs; shared exact-asset reservation |
| TP/SL worker | `process_conditional_orders()` | Pair-keyed price; validate canonical reservation; call canonical Market execution with same IDs |
| TP/SL cancellation | `cancel_conditional_exit_order(uuid)` | Preserve locking and owner checks; release only reservation for stored canonical asset |
| Stop-Limit placement | `place_stop_limit_order(text,text,numeric,numeric,numeric)` | Pair ID; persist same canonical IDs on parent and conditional row |
| Stop-Limit worker | `process_stop_limit_orders()` | Pair-keyed price; child Limit order must inherit and match parent IDs |
| Stop-Limit cancellation | `cancel_stop_limit_order(uuid)` | Parent/child identity equality; cancellation-vs-worker race remains atomic |
| Reservation read | `get_my_order_reservations(uuid[])` | Owner-scoped canonical IDs, bounded input |
| Account deactivation | `deactivate_my_account()` | Preserve atomic cleanup across all open orders, conditionals and canonical reservations; test race against all workers |
| Account write guard | `private.guard_active_account_writes()` plus `current_account_is_active()` | Preserve active-account checks and trigger protection; canonical migration must not weaken either guard |
| Fee helper | `get_demo_trading_fee_rate(text,text)` | Fee policy must resolve market/side from authoritative pair context, not ambiguous ticker |
| OCO | No authoritative implementation found | Separate linked-order state machine; design exists in `docs/OCO_LINKED_ORDER_DESIGN_2026-11-27.md`; not implemented |

### Schema relations that must migrate as one financial unit

- `crypto_assets`, provider mapping, `demo_trading_pairs`, `market_prices`
- `orders`, `trades`, `conditional_orders`
- `order_reservations`, `asset_balances`, `wallets`, `transactions`
- Any Stop-Limit parent/child relation and future OCO group/legs

Preserve current constraints: one reservation per order, reservation/order same-user composite ownership, order filled+remaining accounting, conditional parent uniqueness, child FK integrity, nonnegative balances, fee/settlement precision, auth.uid() ownership, active-account guards, row/advisory locks, RLS, SECURITY DEFINER empty search_path, and service_role-only worker execution.

## E. Evidence and test parity matrix

| Evidence source | What it proves | What it does not prove |
|---|---|---|
| Live Production read-only function/schema snapshots (2026-11-27) | Observed Production definitions, selected grants/schedules, ticker-based identity and collision inventory at inspection time | Full database-wide inventory of every external writer; future state |
| Checked-in migrations | Repository history for functions represented there | Exact current Production parity where migration history is incomplete or drifted |
| Authoritative conditional harness | Actual checked-in TP/SL and Stop-Limit migration bodies execute in disposable PG17 | Canonical-ID integration; Market/Limit settlement (explicit adapters are substituted) |
| Canonical identity fixture | Prototype constraints and duplicate ticker isolation in its own schema | Actual Production RPC/worker source parity |
| OCO design document | Required lifecycle and safety invariants | Any executable OCO behavior |

Required next disposable harness must apply the authoritative Market/Limit migrations and canonical candidate together, with exact dependency inventory and no financial-function lookalikes. Any unavoidable Supabase-only adapter must be explicit, minimal, asserted, and excluded from claims of parity.

## F. Hard blockers before migration proposal or rollout

1. Reconcile migration ledger: 17 applied migrations lack local SQL sources, 20 timestamp prefixes differ from applied versions, and 2 local-only migrations remain unrecorded. No `db push`, migration replay, or history repair.
2. Freeze exact current Production source snapshots/fingerprints for every writer, reader, RPC, worker, trigger, Edge Function and scheduler; distinguish Production-only recovered definitions from repository migrations.
3. Resolve duplicate ticker groups through provider IDs and verified exchange instruments. Never auto-select by ticker and never fabricate synthetic asset identity.
4. Define pair-specific executable price source, provider-observed timestamp, source priority and fair overflow scheduler; preserve current cron jobs.
5. Build canonical Market/Limit source-parity harness first, then adapt TP/SL and Stop-Limit to those exact canonical entrypoints.
6. Implement and test OCO separately, including two-session winner/cancel races and shared reservation.
7. Test account deactivation vs every worker, RLS/grants, direct table write denial, stale/missing prices, ambiguous IDs, malformed reservations, retries, duplicate delivery, partial fills, and exact decimal settlement.
8. Only after all tests and independent review, prepare a non-executable migration proposal and rollout/rollback plan for owner approval.

## Explicit non-actions

This manifest does not alter Production. No SQL migration was created or executed. No Production function, table, row, pair, price, balance, order, reservation, cron job, Edge Function, grant, RLS policy, worker, Auth setting, or user record was changed. No merge, db push, migration-history repair, deployment, APK/Pages publication, or infrastructure spend was performed or authorized.
