# Ledger text-key consumer inventory — 2026-11-28

**Scope:** repository source inventory on the Draft branch at the start of Shahram 211. This is a bounded source audit, not a complete live Production catalog fingerprint. It is not executable SQL and authorizes no Production changes.

## 1. Evidence boundary

Before the audit, the live GitHub state was rechecked:

- PR #67 remained open, Draft, unmerged, and `mergeable=false`.
- Branch HEAD: `2756c0037cc41f0aae55aa347a2a3491f7b1f6bf`.
- Main: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`.
- Compare: 245 ahead, 8 behind, diverged.
- Check Runs on the starting HEAD: zero.

The audit used the branch tree, the checked-in dependency manifest, the recovered Market/Limit migration, the TP/SL and reservation RPC migrations, and captured read-only function snapshots. The repository contains only 197 paths at this HEAD (144 source-like files); it does not contain a full export of Production functions, grants, policies, triggers, Cron, deployed Edge Function versions, or external service-role writers.

## 2. Direct financial consumers confirmed in source

| Consumer | Evidence | Observed use of legacy text key | Required coordinated migration |
|---|---|---|---|
| `public.execute_demo_trade` | `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` | derives base ticker; reads/writes `asset_balances.asset`; subtracts `order_reservations.asset` | pair_id + base/quote IDs; exact mapped ledger key; same reservation availability semantics |
| `public.place_limit_order` | same migration | derives reserve asset from ticker/side; reads balance and inserts text reservation | canonical pair and exact base/quote reservation identity |
| `public.process_limit_orders` | same migration | validates reservation text against ticker-derived base/USDT and settles `asset_balances` | pair-keyed price and exact canonical reservation/ledger identity |
| `public.place_conditional_exit_order` | `20261113162051_add_demo_take_profit_stop_loss_engine.sql` | checks base balance and existing reservations using ticker-derived base; inserts reservation text | conditional parent and reservation share exact pair/base/quote IDs |
| `public.process_conditional_orders` | same migration and `20261113162202_record_conditional_reservation_consumption.sql` | reads reservation row and compares `asset` to ticker-derived base; consumes/releases reservation | canonical reservation identity; worker execution and Market child share same pair tuple |
| `public.place_stop_limit_order` | captured snapshot `canonical_identity_live_place_stop_limit_order_snapshot.sql` | checks USDT wallet and base `asset_balances`; inserts text reservation | parent/child pair tuple and canonical reservation key remain identical |
| `public.process_stop_limit_orders` | stop-limit production source snapshots and parity suite | worker settlement uses reservation and legacy base asset key | child Limit order and parent stop-limit must preserve exact canonical identity |
| `public.cancel_limit_order` | authoritative cancellation source/tests in repo | reservation release by order/user and text reservation asset | release exact stored canonical asset once; no ticker-based re-resolution |
| `public.cancel_conditional_exit_order` | conditional source/test migrations | parent/child reservation release | preserve parent/child canonical equality and race safety |
| `public.cancel_stop_limit_order` | stop-limit source snapshots/tests | reservation release during parent/child cancellation | exact canonical reservation and atomic cancel/worker race |
| `public.deactivate_my_account` | dependency manifest / source inventory | account-wide open order/conditional cleanup reaches reservations and ledgers | atomic cleanup over all canonical pairs; race tests against each worker |
| `public.get_my_order_reservations(uuid[])` | `20261114143035_get_my_order_reservations_rpc.sql` | returns `r.asset` text for owner-scoped orders | return asset_id + pair_id while retaining ownership and bounded input |

## 3. Catalog, price, and read dependencies that can indirectly select the legacy key

These do not all directly read `asset_balances`; they can still create or select ticker identities that flow into financial consumers.

- `public.refresh_crypto_assets()`: catalog writer; CoinGecko identity exists but symbol is mutable.
- `private.auto_list_verified_exchange_asset()`: exchange observation to curated listing; requires a unique ticker/catalog match.
- `private.auto_activate_verified_exchange_pairs()`: provisions/activates symbol-oriented pairs.
- `public.admin_enable_market_pair(text)`: admin pair activation and price selection use symbol-oriented context.
- `public.admin_disable_market_pair(...)`: pair disable/cancellation path includes symbol-based order selection in the audited source.
- `public.process_iran_exchange_asset_sync()` and `public.process_bit24_exchange_sync()`: exchange observation/matching and alias handling; raw observation is not canonical identity.
- `public.refresh_market_prices()`: scheduled market price writer maps provider IDs/exchange symbols into ticker-keyed prices.
- `private.request_market_price_overflow()`: overflow scheduler feeding market refresh; its fairness and cadence are separate release gates.
- `public.get_crypto_assets()`, `public.get_crypto_market()`, `public.get_admin_market_listings()`, `public.get_exchange_discovered_market_assets()`: read projections that expose catalog, pair, or ticker state.
- Market/portfolio/order-history/trade-form/active-orders UI: symbol-oriented contracts need stable IDs end-to-end.

## 4. External and privileged writer boundary

The checked-in dependency manifest identifies `index-ts` and `refresh-market-prices` Edge Function versions as possible price/catalog writers requiring exact deployed-code review. The current branch contains `supabase/functions/sync-iran-exchange-assets/index.ts` and `refresh-toman-market-prices/index.ts`; their existence does not prove they write either legacy ledger table. `app-assets/index.ts` is a static asset-serving function and showed no direct legacy-ledger key reference in the inspected source.

Not yet proven exhaustively:

- every deployed Edge Function and its deployed version/hash;
- all Cron/job command bodies and service-role invocation paths;
- direct SQL/service-role/dashboard/operator writes;
- every view, trigger, policy, generated API type, client query, report, and downstream consumer of the text key;
- every Production-only function not represented in the repository or captured snapshots.

These are explicit unknowns, not assumed absent.

## 5. Mapping consequences

1. The existing `asset_balances(user_id, asset)` primary/unique key means two canonical assets cannot safely share one legacy text key for the same user.
2. `order_reservations.asset` must resolve to the same unique ledger key as the canonical asset reserved by the order side.
3. Conditional and Stop-Limit parent/child flows must preserve one exact pair/base/quote identity through trigger, placement, worker, cancellation, and journal.
4. A ticker rename must not move a balance or alter reservation ownership.
5. Ambiguous existing balance/reservation keys must be quarantined; no automated split, rename, merge, or re-attribution.
6. USDT continues through the existing `wallets.balance_usdt` path unless a separate reviewed quote-currency design explicitly changes it.

## 6. Remaining read-only evidence gates

- Obtain a complete current Production metadata-only inventory of functions, triggers, views, policies, grants, Cron, Edge Functions/deployed versions, and relevant table dependencies. Do not query user/business rows.
- Cross-check every item against this bounded repository manifest; mark source hash, live hash, role (read/write/indirect), and privilege context.
- Enumerate all direct and indirect consumers of `asset_balances.asset` and `order_reservations.asset`, including client-side queries and service-role paths.
- Recover missing applied migrations and reconcile migration-ledger discrepancies before any deployable schema proposal.
- Build and run the candidate only in disposable PostgreSQL after authoritative prerequisites are recovered.

## 7. Safety boundary

No Production SQL, schema fingerprint query, business/user row read, migration, DDL, backfill, balance/reservation change, RPC/worker/Cron invocation, Edge Function deployment, RLS/ACL change, merge, rebase, db push, APK/Pages publication, or infrastructure spend was performed in this stage.
