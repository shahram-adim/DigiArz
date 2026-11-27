# Canonical Trading Ledger Source Recovery Gate — 2026-11-27

**Purpose:** establish what can and cannot be treated as authoritative when moving DigiArz trading from ticker keys to canonical asset/pair IDs.

## Findings from repository source review

### 1. What the passing Market/Limit source-parity step actually proves

CI #2391 step 28 applies the exact three function bodies from migration `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql`:

- `public.execute_demo_trade(text,text,numeric,numeric)`
- `public.place_limit_order(text,text,numeric,numeric)`
- `public.process_limit_orders()`

It then executes them in a disposable PostgreSQL 17 database. This is stronger than testing miniature replacement functions and is a valid regression baseline for those three checked-in function bodies.

**Scope limit:** the test bootstrap creates a minimal test schema. It does not install a fully recovered authoritative Production base schema, all production constraints/indexes/triggers/RLS/grants, or the real helper implementations. Therefore the successful test is an exact-function-body test against an isolated compatible scaffold, not a complete Production-schema parity certification.

### 2. Source locations recovered

- Market/Limit function source: `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql`.
- Detailed financial table/constraint fixture: `supabase/tests/exact_decimal_type_widening_setup.sql` (explicitly labelled disposable and describes itself as mirroring relevant Production catalog).
- Stop-Limit QA snapshots of live function definitions captured 2026-11-26:
  - `supabase/tests/stop_limit_production_place_limit_order_snapshot.sql`
  - `supabase/tests/stop_limit_production_process_limit_orders_snapshot.sql`
- The snapshots include source digests and limited function metadata, but they are function snapshots, not the complete schema, trigger, helper, RLS or ACL inventory.
- `docs/FINANCIAL_RACE_BOOTSTRAP_PLAN_2026-11-21.md` records that the repository search did not recover a complete authoritative base DDL and helper/trigger/role inventory. The current review confirms that this limitation still applies to the material gathered here.

### 3. Canonical identity has a cross-cutting ledger consequence

The authoritative Market/Limit RPCs derive base asset from `symbol` and write `asset_balances(user_id, asset text)`. Reservations also identify their reserved currency using `asset text`. These keys cannot distinguish two distinct canonical assets with the same display ticker.

A pair_id-only addition to `orders` or `market_prices` is therefore insufficient. The financial identity must propagate through at least:

- asset balance rows: `(user_id, asset_id)` (or a rigorously proven compatibility ledger);
- order reservations: canonical `asset_id` for the reserved base/quote asset, plus order/pair identity;
- orders and trades: `pair_id, base_asset_id, quote_asset_id`;
- market prices: `pair_id`, with provider observation time and local receive time kept distinct;
- conditional parent and execution child rows: same pair/base/quote identity;
- all reads, RPCs, workers, cancellation, account deactivation and UI reservation queries that currently use ticker strings.

The current legacy `asset_balances` ticker primary/unique key is a hard compatibility boundary. Do not silently map an ambiguous legacy ticker balance to one canonical asset. Any migration needs an explicit, reviewable reconciliation policy and must stop on ambiguous mappings.

### 4. Fee helper is not recovered as an authoritative source here

The passing CI fixture defines `get_demo_trading_fee_rate('USDT', kind)` as a constant 0.1% test helper. The checked-in financial RPCs call that helper, but the reviewed material does not establish that the fixture's constant body is the complete current Production implementation. Fee parity must therefore remain a separate unresolved dependency until the exact live helper definition, volatility/plan-dependent behavior if any, owner, volatility, search_path and grants are captured or an authoritative source migration is located.

### 5. Price freshness requires preserving the actual source contract

The reviewed Market RPC and Limit worker read `market_prices.updated_at >= now() - interval '1 minute'`. That is a local database freshness contract. Provider-observed timestamp is not present in the current function source. A future canonical pair-price design may add provider event time, but must not silently replace the existing one-minute gate or equate receive time with provider freshness. Define both timestamps, document which is authoritative for execution, and test future/stale observations explicitly.

## Mandatory gates before a canonical financial candidate

1. Recover exact Production definitions for the base table schemas, all financial constraints/indexes, active-account helper and write guard trigger, fee helper, relevant RLS policies and function/table grants. If a source cannot be recovered, mark it as a stubbed dependency and limit the test claim accordingly.
2. Recover the full write/read dependency graph for every ticker-based caller, including Market, Limit placement/worker/cancel, TP/SL, Stop-Limit, account deactivation, reservations RPC, pair activation/disable, market-price ingestion and UI/API reads.
3. Define an ambiguity-safe transition from legacy text asset keys to immutable asset UUIDs. Do not auto-assign balances, reservations, orders or trades for ambiguous tickers.
4. Implement a canonical disposable schema that preserves the actual financial semantics and identity model; then test actual candidate bodies, not adapters.
5. Keep two distinct test labels: (a) exact checked-in RPC body against a compatible disposable scaffold; (b) complete source-faithful schema + RPC parity. Do not conflate them.
6. Only after these pass may a deployable migration proposal be assembled. Migration-ledger reconciliation remains an independent hard gate.

## Safety and non-actions

This is a repository-only source review. No Production database was queried or changed in this step. No migration, function, grant, RLS, trigger, cron, worker, account, wallet, order, reservation, trade or balance was changed. No db push, merge, deploy, APK/Pages publication or cost was incurred.
