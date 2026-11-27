# DigiArz — Production catalog writer and uniqueness audit
**Read-only source/schema audit — 2026-11-27**

## Scope and safety
This document records read-only inspection of the linked Production database schema and function definitions. No function was invoked. No table data, grants, policies, schedules, pairs, prices, balances, orders, workers, or infrastructure were changed.

## Recovered authoritative catalog writer
The exact applied definition of `public.refresh_crypto_assets()` was retrieved with `pg_get_functiondef`.

Observed behavior:
- `SECURITY DEFINER`, empty `search_path`; execution is granted to `service_role`, not `anon` or `authenticated`.
- Acquires transaction advisory lock `(20261108, 500)`.
- Consumes queued CoinGecko market pages from `private.crypto_assets_sync_requests` and `net._http_response`.
- Inserts `crypto_assets` rows keyed by `coingecko_id`; on conflict it updates `symbol = UPPER(provider symbol)`, name, image, rank, price, volume, timestamps, and sets `is_active = TRUE`.
- It accepts any non-empty provider ID/symbol/name and positive numeric current price; the SQL does not apply the pair-format regex or ticker uniqueness before updating the catalog row.
- It does not itself provision a row in `demo_trading_pairs`.
- It marks page scan state and queues the next CoinGecko page; per-page failures are caught and scheduled for retry.

Implication: `crypto_assets.symbol` is mutable through the recurring catalog refresh path. Pair identity must therefore not be treated as a permanent derivation from an unchecked ticker string.

## Current schema constraints and indexes
Read-only catalog inspection found:
- `crypto_assets`: primary key on `coingecko_id`; no unique constraint/index on `symbol`. Existing symbol indexes are non-unique.
- `demo_trading_pairs`: primary key on `pair_symbol`; unique constraint on `base_coingecko_id`; foreign key to `crypto_assets(coingecko_id)`; quote constrained to `USDT`; pair format constrained to `^[A-Z0-9]{2,15}USDT$`.
- `admin_market_listings`: primary key on `coingecko_id`, FK to `crypto_assets`.
- A BEFORE INSERT/UPDATE trigger on `admin_market_listings` calls `private.enforce_unique_admin_market_listing_symbol()`.
- No trigger was returned for `crypto_assets` or `demo_trading_pairs` in the inspected trigger catalog.
- RLS is enabled on all four inspected tables: `crypto_assets`, `admin_market_listings`, `demo_trading_pairs`, and `market_prices`.

## Live data collision inventory
Read-only aggregate counts at inspection time:
- Active catalog assets: **19,012**.
- Active ticker groups with more than one asset ID: **2,365**.
- Active rows belonging to those duplicate-ticker groups: **6,662**.
- Enabled demo pairs: **420**.
- Enabled pairs without a matching `market_prices` row: **0**.

The duplicate inventory is a material blocker to automatically enabling every active catalog row by `UPPER(symbol) || 'USDT'`. A ticker alone is not a canonical asset identity. A large number of existing active catalog assets share tickers, so a bulk pair backfill or a unique active-symbol constraint cannot safely be added before a collision-resolution/admission policy exists.

## Additional activation-path findings
Definitions retrieved read-only show:
- `private.auto_activate_verified_exchange_pairs()` still requires curated listing, active asset, valid ticker, fresh CoinGecko price, metadata freshness, USD 1m volume, rank <= 2000 when present, recent matched exchange observation, and exactly one active catalog row for the ticker. It inserts pairs with `ON CONFLICT (pair_symbol) DO NOTHING`.
- `private.auto_list_verified_exchange_asset()` is an exchange-observation trigger function that inserts into `admin_market_listings` only when there is exactly one active catalog row for the ticker and the name/identity checks pass.
- `public.admin_enable_market_pair(text)` requires super-admin, curated listing, liquidity/rank gates, symbol validity, no pair-symbol collision, and positive CoinGecko price updated within two minutes. It uses a transaction advisory lock keyed by the CoinGecko ID.
- The current model therefore has multiple activation paths and product eligibility gates that are not yet unified.

## Consequences for the target design
1. Keep canonical provider asset ID as the primary identity; never infer identity from ticker alone.
2. Do not remove all ticker ambiguity checks. Owner intent means every admitted catalog asset is intended to be tradable, but ambiguous tickers must be resolved at catalog admission or assigned an explicitly supported alternative market symbol/quote. Do not silently select one asset.
3. Distinguish the broad discovery feed from the curated/tradable catalog. A raw provider-discovered row should not automatically become an admitted tradable asset before identity, supported market, price, and ticker mapping checks pass.
4. The current USDT-only financial model and pair constraints must be respected. A future asset with no valid USDT quote/price path cannot be marked tradable until a supported market route exists.
5. The existing active catalog contains substantial historical ambiguity. Before enabling more pairs, prepare a read-only reconciliation report identifying which duplicate IDs are already listed/paired, provider IDs, names, market observations, and any ticker migrations. Do not mutate or disable any existing row as part of this audit.
6. A safe implementation needs one canonical admission/provisioning path, transactional/idempotent behavior, collision-aware errors, and price-refresh coverage; then update all user RPCs and workers together. Preserve current financial authorization, reservation, fee, and ledger invariants.

## Next steps
- Finish writer inventory for `crypto_assets`, `admin_market_listings`, `demo_trading_pairs`, and `market_prices`, including all exchange sync functions, triggers, cron invokers, and table grants/policies.
- Produce a compact duplicate-ticker reconciliation dataset (not a write operation) and determine whether any valid collision-safe market-symbol mapping exists for each group.
- Verify price refresh coverage for all future provisioned pairs.
- Only then design disposable-PostgreSQL source-parity tests and a reviewed migration proposal.

## Explicit non-actions
No Production writes, pair activation/deactivation, migrations, db push, function execution, cron/worker changes, Edge Function changes, grants/RLS changes, merge, deployment, APK/Pages release, or paid infrastructure changes were performed or authorized.
