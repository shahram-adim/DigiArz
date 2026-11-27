# Trading Ledger Schema Recovery Evidence — 2026-11-27

## Purpose and scope

This note records the source-recovery result before designing any canonical asset/pair financial schema. It is repository-only documentation. It does not authorize or perform a Production query, schema change, migration, data reconciliation, or release.

## Evidence confirmed on the current PR branch

### 1. CI fixtures are not authoritative base DDL

The following checked-in files construct disposable financial tables:

- `supabase/tests/exact_decimal_type_widening_setup.sql`
- `supabase/tests/exact_decimal_stop_limit_setup.sql`
- `supabase/tests/exact_decimal_conditional_exit_setup.sql`
- `supabase/tests/exact_decimal_limit_worker_setup.sql`

They are useful test scaffolds, but they are not migration sources for the current Production base schema. In particular, the widening fixture explicitly describes itself as a disposable fixture that mirrors relevant catalog details. Its table definitions cannot be promoted to authoritative DDL without a live, reconciled catalog comparison.

The widening fixture currently models:
- `asset_balances` with `UNIQUE(user_id, asset)` where `asset` is text;
- `order_reservations` with text `asset`, an order/user composite FK, accounting checks, and a unique order index;
- `orders`, `trades`, `conditional_orders`, `wallets`, and `transactions` with only the subset required by that test.

It also contains a test-only active-account helper/trigger scaffold and a limited set of RLS policies/grants. It is not a full catalog export.

### 2. Current checked-in Market/Limit migration confirms ticker-keyed financial writes

Migration `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` defines the Market entrypoint, Limit placement, and Limit worker. These function bodies:
- resolve the base asset by parsing the pair ticker string;
- use `demo_trading_pairs.pair_symbol` and `market_prices.symbol` as execution lookup keys;
- read/write `asset_balances(user_id, asset text)`;
- reserve funds through `order_reservations.asset text`;
- use a local `market_prices.updated_at` one-minute freshness check;
- rely on the fee and active-account helpers.

The migration alters functions, not the complete base-table schema. It cannot alone reconstruct all table constraints, triggers, RLS policies, or ACLs.

### 3. Exact helper snapshots are useful but incomplete

The current PR contains read-only captured function-body snapshots for:
- `public.get_demo_trading_fee_rate(text,text)`, digest `546d80d7105228ed97da26c5ed0c7b7f`;
- `public.current_account_is_active()`, digest `d932cd1d0da21bb96bdc0a381f7dcbc3`.

Their comments record owner `postgres`, SECURITY DEFINER, empty search_path, and EXECUTE metadata as captured on 2026-11-27. The fee helper reads enabled maker/taker rates from `demo_trading_fees`; the active-account helper reads `profiles.is_active`.

These snapshots do not supply the authoritative `demo_trading_fees` table DDL/data constraints, `profiles` DDL, account-guard trigger function body/trigger inventory, or the complete current grants and policies for the financial tables. They improve the test harness but do not close schema parity.

### 4. Historical Recovery-Test snapshot is not a Production authority

The repository's earlier recovery record in `docs/FINANCIAL_RACE_BOOTSTRAP_PLAN_2026-11-21.md` reports a metadata-only catalog read from the isolated Recovery-Test project on 2026-11-21:
- 32 tables, 239 columns, 116 constraints, 63 indexes;
- 5 non-system triggers and 21 policies across public/private;
- the principal account-guard triggers were on INSERT for `orders`, `trades`, and `transactions`.

That record explicitly says the snapshot was not compared successfully with Production: read-only Production SQL/list-table attempts timed out. It also records that the Recovery-Test restore used `pg_restore --no-owner --no-acl`, so its ACLs and `has_function_privilege` results cannot establish Production grants. The restored project contains backup data and is not approved as a financial test harness.

The historical helper fingerprints in that note are recovery-snapshot fingerprints, not proof of current Production equivalence. The two 2026-11-27 helper snapshots now in this PR are separate, newer function captures; their existence still does not establish full schema parity.

### 5. Migration-source search did not recover authoritative base table DDL

A repository code search for `CREATE TABLE public.asset_balances`, `order_reservations`, `wallets`, and `transactions` returned disposable test setup files and dependent function migrations, but no authoritative base-table creation migration in the searched source. This is a bounded search result, not proof that no such DDL exists in Git history, backups, or the live database.

## Canonical identity implications

The financial key boundary remains unresolved:
- a text ticker in `asset_balances` cannot distinguish two canonical assets sharing the same ticker;
- text `asset` in reservations has the same ambiguity;
- orders, trades, conditional parents/children, pair activation/disable, market prices, cancellation, account deactivation, reservation readers, ingestion, and UI reads must migrate as one identity graph;
- legacy balances/reservations with ambiguous ticker mappings must be quarantined or explicitly reconciled, never silently assigned to an arbitrary asset.

A canonical Market/Limit candidate must preserve the authoritative behavior (wallet-first lock ordering, fee rounding/configuration, 25%-of-original partial fills, reservation consumption/release, advisory lock/SKIP LOCKED scheduling, active-account guards, transaction ledger semantics, and the one-minute local receive-time gate) while using immutable asset and pair IDs. The current simplified duplicate-ticker fixture is not sufficient.

## Required next evidence gate

1. Obtain a fresh, authorized, metadata-only Production fingerprint for the target financial tables, columns/types/defaults, PK/unique/FK/check constraints, indexes, triggers, RLS flags/policies, table grants, relevant function definitions/owners/config/ACLs, and relevant cron metadata. Do not query business or user rows.
2. Compare that fingerprint with the 2026-11-21 Recovery-Test metadata record and the checked-in source. Treat every mismatch and every unavailable field as a blocker; do not infer missing DDL from fixtures.
3. Reconcile the migration ledger separately. A schema fingerprint alone does not prove which migrations were applied.
4. Only then construct a fully source-faithful disposable PostgreSQL 17 schema and run the canonical candidate through the real lifecycle. Keep all Production writes and rollout actions behind separate explicit owner approval.

## Safety boundary

No Production SQL was run for this note. No business/user rows were read. No migration, function, table, index, trigger, RLS, grant, cron, worker, account, wallet, order, reservation, trade, or balance was changed. No db push, merge, deployment, APK/Pages publication, or cost was incurred.


## Additional historical Production metadata recovered from repository audit records

A second bounded repository search found older read-only Production inspection records on `main`, especially `docs/STOP_LIMIT_QA_MATRIX.md` and `docs/superpowers/reports/2026-11-15-exact-decimal-backend-rpc-review.md`. These records add useful historical schema evidence that was not included in the 2026-11-21 Recovery-Test summary:

- Historical typmods at the 2026-11-15 inspection: `market_prices.price numeric(38,18)`; `orders.amount/price numeric(24,8)`; `trades.amount/price numeric(24,8)`; `asset_balances.balance numeric(28,8)`; `wallets.balance_usdt` and `transactions.amount numeric(24,8)`; order fill/residual, reservation amounts and conditional-order numeric fields were unconstrained numeric.
- Historical constraints: order accounting equality `filled_amount + remaining_amount = amount`, order positive/range checks, nonnegative asset balance, positive trade amount/price, and reservation nonnegative/accounting checks `consumed_amount + released_amount <= reserved_amount`.
- Historical FK dependencies: `conditional_orders` references parent and execution orders; `order_reservations` references order/user; `trades` references orders. These were identifier relationships, not numeric-column dependencies.
- Historical trigger inventory on the four reviewed core tables: account guard triggers on `orders` and `trades`; none recorded on `asset_balances` or `order_reservations`.
- Historical index summary: indexes covered primary/unique identifiers, user/asset, reservation status, order creation time and trade order/time paths; no index keyed/included the numeric amount/price/balance fields.
- Historical RLS summary: user/account-scoped policies on the four reviewed tables; policies did not reference numeric columns. The wider Recovery-Test snapshot later counted 21 policies overall.

**Evidence limits:** these are dated, human-authored audit summaries, not raw catalog export or base-table CREATE DDL. They do not prove the schema stayed unchanged after 2026-11-15, do not provide exact constraint/index/policy names or expressions, and do not close the Production-vs-Recovery-Test comparison. The exact original CREATE TABLE statements, all column defaults/nullability, complete index definitions, policy expressions, table ACLs and current migration ledger remain outstanding. Use these records to guide the metadata fingerprint comparison, never as a substitute for it.


## Current Production metadata-only catalog fingerprint and migration-ledger reconciliation — 2026-11-27

**Capture provenance and safety boundary**
- Captured against Supabase project `gfoaubfilhttnwjykaox` (PostgreSQL 17.11.0.018, status ACTIVE_HEALTHY) on 2026-11-27 at approximately 18:39–18:40 UTC.
- Sources: Supabase management `list_tables(verbose=true)`, `list_migrations`, and read-only SELECTs limited to `pg_catalog`, `information_schema`, `pg_policies`, `pg_indexes`, `pg_proc`, `pg_trigger`, `pg_constraint`, `cron.job`, and privilege predicates. No business/user row contents were selected, and no schema/data/function/ACL/RLS/trigger/Cron state was changed.
- Scope: 12 public tables — wallets, transactions, orders, trades, asset_balances, order_reservations, market_prices, market_fx_rates, crypto_assets, demo_trading_pairs, conditional_orders, demo_trading_fees.
- Catalog totals: 12 tables, 100 columns, 65 constraints, 30 indexes, 3 non-system triggers, 12 policies. RLS is enabled on all 12; FORCE ROW LEVEL SECURITY is enabled on none. This is a current metadata snapshot, not a byte-for-byte original CREATE TABLE migration export.

**Current numeric types, nullability and defaults (selected ledger/market columns)**
- `market_prices.price numeric(38,18) NOT NULL`.
- `orders.amount numeric(24,8) NOT NULL`; `orders.price numeric(24,8) NULL`; `filled_amount numeric NOT NULL DEFAULT 0`; `remaining_amount numeric NOT NULL`.
- `trades.amount` and `trades.price numeric(24,8) NOT NULL`.
- `asset_balances.balance numeric(28,8) NOT NULL DEFAULT 0`.
- `wallets.balance_usdt numeric(24,8) NOT NULL DEFAULT 200`; `wallets.balance_irr numeric(24,0) NOT NULL DEFAULT 1000000000`.
- `transactions.amount numeric(24,8) NOT NULL`.
- `order_reservations.reserved_amount`, `consumed_amount`, `released_amount` are unconstrained `numeric`, all NOT NULL; consumed/released default to 0.
- `conditional_orders.trigger_price`, `amount`, `executed_price`, `limit_price` are unconstrained `numeric`; nullable only for executed_price and limit_price.
- `crypto_assets.current_price_usd numeric(30,12)`, `price_toman numeric(30,2)`, `price_change_percentage_24h numeric(20,8)`, market_cap/volume `numeric(30,2)`; fee rates are `numeric(10,8)`.
- Important follow-up: current Production wallet default `balance_irr=1,000,000,000` differs from the currently approved product default remembered as 50,000,000 Toman. Do not silently change or infer the intended conversion; verify unit semantics and initialization path in a separate product/accounting audit before any future change.

**Current identity and accounting structure**
- `crypto_assets` primary key is `coingecko_id`; `symbol` is non-unique.
- `demo_trading_pairs` primary key is `pair_symbol`, with unique `base_coingecko_id`; quote is constrained to USDT.
- `market_prices` primary key is display `symbol`.
- `orders.symbol`, `trades.symbol`, `conditional_orders.symbol`, `asset_balances.asset`, and `order_reservations.asset` are text, not canonical IDs. `asset_balances` has unique `(user_id, asset)`; reservations have unique `order_id`. Therefore the live ledger still cannot distinguish same-ticker canonical assets.
- Current validated accounting constraints include:
  - orders: `filled_amount + remaining_amount = amount`; filled and remaining ranges; positive amount/price; Limit requires price.
  - asset balances: nonnegative balance and uppercase asset.
  - reservations: `consumed_amount >= 0 AND consumed_amount + released_amount <= reserved_amount`; `released_amount <= reserved_amount`; positive reserve; order/user composite FK.
  - trades: positive amount and price; trade order FK uses ON DELETE SET NULL.
  - wallets: nonnegative USDT/IRR balances; one wallet per user.
- Current 30-index inventory includes the expected primary/unique keys; `asset_balances(user_id,asset)`; `order_reservations(order_id)` and `(user_id,status)`; conditional pending/parent/execution/user-status indexes; orders composite identity and pending Limit index; `trades(order_id,created_at)`. Exact index definitions were read from `pg_indexes`.

**Current triggers, RLS policies and privileges**
- Three enabled non-system account-guard triggers: BEFORE INSERT on `orders`, `trades`, and `transactions`, all invoking `private.guard_active_account_writes()`. No trigger was recorded on `asset_balances` or `order_reservations`.
- 12 policies were captured. Core ledger reads are user/account scoped: wallets, orders, trades and transactions use `auth.uid() = user_id` plus `current_account_is_active()`; asset balances use the same user/account guard; reservations are authenticated owner-only; conditional orders are authenticated owner-only; catalog/pairs/prices/FX have public read policies. RLS is enabled, but table owners do not have FORCE RLS.
- Effective table privilege predicates show authenticated has SELECT only on wallets, orders, trades, transactions and asset_balances; no direct authenticated write grants. `order_reservations` has no authenticated direct table privilege and is accessed through its RPC path. service_role has broad table privileges as expected. The `conditional_orders` table has an anon SELECT grant but no anon SELECT policy; RLS therefore still filters anonymous rows.
- Relevant SECURITY DEFINER functions are owned by postgres and have empty search_path. Authenticated can EXECUTE placement/cancellation/fee/account helper RPCs; anon cannot. The three worker functions `process_limit_orders()`, `process_conditional_orders()`, and `process_stop_limit_orders()` are executable by service_role and not authenticated/anon.
- Active pg_cron metadata: job 3 `digiarz-market-price-refresh` every minute; job 8 `digiarz-limit-orders` every minute; job 9 `digiarz-conditional-orders` every minute; job 12 `digiarz-stop-limit-orders` every minute; job 17 `digiarz-market-price-overflow` every 10 minutes (schedule `5-59/10 * * * *`). All five were active at capture. Preserve these schedules; no cron changes were made.

**Production migration ledger vs repository source — exact reconciliation**
- Current Production ledger reports **55 applied migrations**. Both `main` and `plan/all-catalog-assets-tradable-2026-11-27` contain **40 local SQL migration files** at capture.
- Matching by normalized migration name (not timestamp) yields **18 exact version/name matches, 20 same-name timestamp mismatches, 17 applied migrations with no matching local source file, and 2 local-only migrations absent from the applied ledger**. This reproduces the previously reported 17/20/2 discrepancy and clarifies that the 20 timestamp cases are name matches with differing version prefixes, not unrelated migration names.
- 20 same-name timestamp mismatches (Production applied version → local filename version):
  - `20261113162154 → 20261113162202` record_conditional_reservation_consumption
  - `20261113162233 → 20261113162244` index_conditional_execution_order_reference
  - `20261113163743 → 20261113170000` recover_stalled_crypto_asset_sync
  - `20261113163947 → 20261113171000` add_admin_curated_market_assets
  - `20261113164521 → 20261113172000` harden_admin_market_listing_access
  - `20261113165725 → 20261113180000` add_admin_pair_activation_engine
  - `20261113165747 → 20261113180500` fix_market_price_decimal_parser
  - `20261113165806 → 20261113181000` show_live_prices_for_curated_assets
  - `20261113170056 → 20261113182000` rate_limit_manual_market_refresh
  - `20261113170216 → 20261113183000` index_market_pair_admin_audit
  - `20261113170328 → 20261113184000` prevent_curated_ticker_collisions
  - `20261113173506 → 20261113190000` admin_on_demand_crypto_asset_refresh
  - `20261115134357 → 20261115134500` add_kifpool_to_scheduled_exchange_asset_sync
  - `20261115134855 → 20261115134600` avoid_relisting_unchanged_exchange_asset_matches
  - `20261115142521 → 20261115143000` allow_verified_kifpool_cfg_jup_exact_id_aliases
  - `20261115142620 → 20261115143200` prioritize_exact_name_matches_for_kifpool_assets
  - `20261115143015 → 20261115145000` allow_verified_kifpool_rebrand_aliases
  - `20261115143050 → 20261115145500` allow_verified_kifpool_additional_name_aliases
  - `20261115143223 → 20261115150000` allow_verified_kifpool_exact_id_name_aliases_batch
  - `20261116205451 → 20261117130000` stagger_market_price_overflow_and_refresh_exchange_discovery
- 17 applied ledger entries without a matching local migration name:
  - `20261113153808 approved_wallet_defaults_fees_and_coin_reviews`
  - `20261113154323 assign_confirmed_super_admin`
  - `20261113154736 secure_admin_wallet_management`
  - `20261113154750 add_admin_role_probe`
  - `20261113154844 use_toman_units_in_admin_credit_ui`
  - `20261113154926 move_admin_privilege_logic_to_private_schema`
  - `20261115101709 create_exchange_asset_observations`
  - `20261115102729 schedule_iran_exchange_asset_sync`
  - `20261115102927 fix_exchange_sync_response_json_cast`
  - `20261115103227 auto_list_verified_exchange_assets`
  - `20261115103507 schedule_bit24_exchange_asset_sync`
  - `20261115105721 admin_exchange_asset_sync_monitoring`
  - `20261115105956 restrict_exchange_sync_worker_execution`
  - `20261116201639 auto_activate_verified_exchange_pairs`
  - `20261121045434 digiarz_backpressure_and_exchange_sync_bloat_guards`
  - `20261121045531 snapshot_pg_net_unlogged_queue_before_recovery`
  - `20261121050216 temporarily_throttle_exchange_asset_processors_20261121`
- Two local-only migrations, not recorded as applied in Production:
  - `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql`
  - `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql`
- Do not replay, repair, rename, delete, or mark migrations applied based on this comparison. Recover each missing applied source from trusted Git history/backup and inspect timestamp variants individually. Local-only migrations remain unapplied; they must not be pushed as a side effect of reconciliation.

**What this resolves and what remains open**
- [x] Current Production table columns/types/defaults/nullability, 65 constraints, 30 indexes, 3 triggers, 12 RLS policies, selected table grants, relevant function ACL/SECURITY DEFINER metadata, and active order/market cron schedule metadata have now been captured using catalog-only reads.
- [x] Current Production applied migration ledger was retrieved and reconciled against both main and the active PR branch by migration name and timestamp.
- [!] This is a live catalog metadata fingerprint, not original CREATE TABLE migration source. It does not by itself recover historical DDL sequencing, dropped objects, all grants outside the scoped roles/tables, every external writer, or full function bodies for every dependent routine.
- [!] The 17 missing applied migration source files and 20 timestamp mismatches remain unresolved source-of-truth issues. Do not infer their SQL from current catalog state or neighboring migration files.
- [ ] Next: recover the 17 missing migration bodies from trusted historical Git objects/backups and inspect all 20 timestamp-different source variants; fingerprint relevant writers/readers/Edge Functions against this live catalog; then construct a full source-parity disposable harness. Only after these steps may a coordinated canonical-ID migration be drafted for review. OCO remains a separate missing lifecycle.
- [x] No Production writes, business-row reads, migration replay/repair, schema/function/ACL/RLS/trigger/Cron/worker/Auth change, db push, merge, deploy, APK/Pages publication or cost.


## Correction/addendum — complete current cron inventory and auto-activation source (2026-11-27)

A second metadata-only read broadened the cron filter to include exchange-sync and catalog jobs. This corrects the earlier scoped five-job summary above, which omitted jobs outside the order/market/conditional name filter. The complete relevant active inventory at 2026-11-27 18:41 UTC is:

| Job ID | Job | Active schedule |
|---:|---|---|
| 3 | digiarz-market-price-refresh | `* * * * *` |
| 4 | refresh-crypto-assets | `6-59/10 * * * *` |
| 5 | refresh-crypto-assets-toman | `7-59/10 * * * *` |
| 8 | digiarz-limit-orders | `* * * * *` |
| 9 | digiarz-conditional-orders | `* * * * *` |
| 11 | digiarz-crypto-assets-stale-request-recovery | `3-59/5 * * * *` |
| 12 | digiarz-stop-limit-orders | `* * * * *` |
| 13 | digiarz-iran-exchange-request | `*/10 * * * *` |
| 14 | digiarz-iran-exchange-process | `1,31 * * * *` |
| 17 | digiarz-market-price-overflow | `5-59/10 * * * *` |
| 18 | digiarz-auto-activate-verified-exchange-pairs | `9-59/10 * * * *` |

All 11 were active at capture. In particular, preserve job 8 (Limit), job 9 (conditional) and job 12 (Stop-Limit) at every minute. No job was invoked, paused, edited or rescheduled.

The exact current function snapshot `supabase/tests/canonical_identity_live_private_auto_activate_verified_exchange_pairs_snapshot.sql` has fingerprint `fd177baeee1a5bdd927458413f69bfb6`. It is a read-only captured source artifact, not a migration. It confirms the job's `private.auto_activate_verified_exchange_pairs()` function is postgres-owned, SECURITY DEFINER, empty search_path, and not executable by anon/authenticated/service_role; the cron job is the scheduled execution path. Its current logic still imposes `total_volume_usd >= 1000000`, market-cap rank NULL or <= 2000, recent market data, a CoinGecko market-price row, verified exchange observation, and unique active ticker. It builds `pair_symbol = upper(symbol)||'USDT'` and joins `market_prices.symbol`; therefore this writer remains ticker-keyed and applies product filters that conflict with the owner-approved no-fixed-rank/no-fixed-volume-cap catalog objective. These restrictions must be redesigned in the canonical provisioning plan, while keeping identity, verified mapping, price freshness and account/security guards.

The current live job 14 cadence is `1,31 * * * *` (twice hourly), consistent with the later 2026-11-22 historical reconciliation note, not the older 2026-11-20 `1-59/10` observation. The local timestamp-mismatched migration `20261117130000_stagger_market_price_overflow_and_refresh_exchange_discovery.sql` is not authoritative for this live cadence. Do not replay it or edit cron.

The two local-only migrations `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql` and `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql` are additionally documented in `supabase/MIGRATION_RECONCILIATION.md` as older `refresh_market_prices()` replacements that omit the later 515-ID CoinGecko cap (the second also omits the later combined state). They are unsafe to apply as-is and must remain excluded from any push/replay until source reconciliation is complete.


### Follow-up source-recovery sweep and latest PR CI — 2026-11-27

- [x] Repeated GitHub code search for four representative missing applied migration names: `approved_wallet_defaults_fees_and_coin_reviews`, `create_exchange_asset_observations`, `auto_activate_verified_exchange_pairs`, and `digiarz_backpressure_and_exchange_sync_bloat_guards`. Each search returned only this reconciliation report, not a SQL migration body.
- [x] Inspected recursive Git trees for eight relevant historical branches: `feature/auto-list-iran-exchange-assets`, `fix/iran-exchange-sync-response-race`, `fix/bit24-deduplicate-sync-2026-11-21`, `fix/exchange-observation-hot-updates-2026-11-21`, `perf/iran-exchange-matcher-design`, `perf/iran-exchange-sync-noop-updates`, `audit/production-rpc-manifest-2026-11-25`, and `diagnostics/auth-cron-connection-pressure`. No exact migration filenames for the sampled missing SQL bodies were present in those branch migration trees. This is a bounded branch-tree check, not an exhaustive Git object/backup/deployment-artifact search.
- [x] The full Production migration reconciliation report confirms the 17 missing-source inventory (14 original missing entries plus the three 2026-11-21 entries) and lists their applied version/name pairs. No SQL content was reconstructed from names or live object definitions.
- [x] Latest PR #67 HEAD at this check: `e0e810102d7410bacfc7e03ccf029daf8bffad48`; CI run #2411 / `46051903125` completed SUCCESS on this exact SHA. All 28 substantive steps passed, including authoritative TP/SL and Stop-Limit migration harness, authoritative Market/Limit migration harness, exact-decimal and concurrency checks, duplicate-ticker canonical isolation, and schema fingerprint.
- [!] PR #67 remains Draft, open, unmerged and mergeable. CI success validates the checked-in disposable test suite; it does not recover the 17 missing applied migration bodies or establish complete current Production source parity.
- [ ] Next: seek a trusted deployment artifact/backup or historical Git object containing the missing SQL bodies; inspect all 20 same-name timestamp variants against authoritative deployment records; reconcile the live/local price refresh and catalog auto-activation writer source; then extend the disposable source-parity harness. Do not invent/reconstruct missing SQL, replay/repair migration history, or push the current migration directory.
- [x] No Production writes, business-row reads, migration replay/repair, function/ACL/RLS/trigger/Cron/worker/Auth change, db push, merge, deploy, APK/Pages publication or cost.
