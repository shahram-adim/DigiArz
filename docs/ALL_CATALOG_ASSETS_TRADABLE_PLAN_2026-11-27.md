# DigiArz — All catalog assets must be demo-tradable
**Plan / source audit — 2026-11-27**

## Owner decision

Every asset that exists in the DigiArz catalog now, and every asset added to that catalog in the future, must support demo buy and sell. There is no fixed 12-pair cap and no display-only class for an asset that has been admitted to the DigiArz catalog.

This means catalog admission and demo-trading eligibility must become one coherent lifecycle. It does **not** mean bypassing price validation, symbol uniqueness, account authorization, balance/reservation checks, or ledger integrity.

## Current implementation: source findings

### Catalog, discovery, and pair activation

- `crypto_assets` is the catalog metadata source referenced by the UI and market metadata joins.
- `get_admin_market_listings()` exposes curated listings; `get_exchange_discovered_market_assets()` is a read-only discovery endpoint. Discovery does not itself create an enabled trading pair.
- `auto_list_verified_exchange_asset()` writes to `admin_market_listings`, not directly to `demo_trading_pairs`; its path includes eligibility and collision checks.
- `admin_enable_market_pair(p_coingecko_id)` in migration `20261113180000_add_admin_pair_activation_engine.sql` currently requires:
  1. asset already present in `admin_market_listings`;
  2. `crypto_assets.is_active = true`;
  3. positive metadata price and metadata no older than 24 hours;
  4. 24-hour volume at least USD 1,000,000;
  5. market-cap rank no worse than 2,000 when rank is present;
  6. symbol matching `^[A-Za-z0-9]{2,15}$`, excluding USDT;
  7. no pair-symbol collision with a different CoinGecko asset;
  8. positive CoinGecko-sourced `market_prices` no older than two minutes.
- The volume/rank/curated-list requirements are product eligibility gates, not financial safety controls. They conflict with the owner's rule when an otherwise valid asset is already admitted to DigiArz but does not pass those gates.
- Existing uniqueness protections are useful but incomplete as a global invariant: reviewed safeguards cover curated ticker collisions and pair-symbol conflicts, while earlier source review found that they do not prove unique `crypto_assets.symbol` / `demo_trading_pairs.base_coingecko_id` mapping across every write path.
- The repository review did not recover the complete authoritative body of the catalog refresh writer `refresh_crypto_assets()`. Do not claim all symbol write paths or database-wide uniqueness are fully proven until that definition and its callers are recovered.

### UI trade entrypoints

- `loadMarkets()` reads enabled `demo_trading_pairs` and joins `crypto_assets` metadata. An asset not provisioned into the enabled-pair table is not a normal market row.
- `loadFeaturedMarketAssets()` obtains curated and exchange-discovered assets, but discovery is not equivalent to an enabled trading pair.
- `trade()` explicitly rejects missing market rows and `auto_discovered` rows before calling `execute_demo_trade`.
- `placeLimitOrder()` explicitly rejects missing market rows and `auto_discovered` rows before calling `place_limit_order`.
- `placeConditionalExitOrder()` explicitly rejects missing market rows and `auto_discovered` rows before calling `place_conditional_exit_order`.
- These client-side guards must be changed only together with server-side provisioning and server-side validation; removing them alone would only expose a server rejection.

### Authoritative financial entrypoints and workers

All reviewed current entrypoints are USDT-quoted and require a matching enabled row in `demo_trading_pairs`:

| Flow | Server entrypoint / worker | Current pair dependency |
|---|---|---|
| Market buy/sell | `execute_demo_trade` | enabled `demo_trading_pairs` row; fresh positive `market_prices` |
| Limit buy/sell | `place_limit_order` | enabled pair; reservation and wallet/asset balance checks |
| Limit matching | `process_limit_orders` | rechecks enabled pair before fill; consumes fresh market price |
| Take-profit / stop-loss | `place_conditional_exit_order`, `process_conditional_orders` | enabled pair; base-asset reservation and conditional lifecycle |
| Stop-Limit | `place_stop_limit_order`, `process_stop_limit_orders` | enabled pair; parent/child order and reservation lifecycle; child delegates to Limit path |

The RPCs and workers must keep their current authorization boundaries: authenticated users may invoke user entrypoints; service-role-only workers process queues. Pair provisioning must not grant users direct writes to pair tables or financial tables.

## Target invariant

For every active catalog asset with a valid, globally unambiguous ticker and a supported USDT market:

1. exactly one canonical base-asset identity maps to exactly one `BASEUSDT` pair;
2. that pair is enabled for demo trading automatically as part of the catalog-admission lifecycle;
3. all trading entrypoints and all order workers resolve eligibility through the same authoritative mapping;
4. the pair cannot be enabled for trading until a positive, sufficiently fresh, trusted market price is available;
5. if identity, ticker uniqueness, provider mapping, or price freshness is ambiguous, provisioning fails closed and surfaces a resolvable catalog error — it must not silently choose an asset or permit a trade;
6. newly admitted catalog assets become eligible without a fixed count cap or manual per-asset activation step.

An asset may be visible as a *pending catalog admission* before it is eligible to trade, but once DigiArz marks it active/admitted in its canonical catalog, the system must provision its pair or clearly fail the admission transaction. It must not silently create a permanent display-only catalog asset.

## Proposed implementation sequence — isolated test branch first

### Phase A — recover authoritative inputs

- Recover the exact applied definition and callers of `refresh_crypto_assets()` from migration history / Supabase schema metadata without modifying Production.
- Enumerate every writer of `crypto_assets.symbol`, `crypto_assets.coingecko_id`, `crypto_assets.is_active`, and every writer of `admin_market_listings` / `demo_trading_pairs`.
- Verify table constraints, indexes, triggers, grants, RLS, RPC owners, and current uniqueness data before proposing a permanent invariant.
- Verify supported provider/market coverage and quote-asset assumptions. Current financial RPCs are USDT-only; adding an asset to the catalog must not imply unsupported quote markets.

### Phase B — implement one catalog-to-pair provisioning path

- Introduce one reviewed server-side provisioning function invoked by the canonical catalog-admission writer (and by a safe backfill/reconciliation path).
- Use a transaction-scoped lock keyed by canonical asset ID and a database-enforced unique mapping after collision inventory is complete.
- Remove only business filters that conflict with owner intent (curated-list membership, minimum volume, market-cap rank). Retain strict identity, symbol, provider, price, freshness, and account/ledger controls.
- Make provisioning idempotent and safe under concurrent catalog refreshes. Do not reactivate a pair mapped to a different canonical asset.
- Ensure price refresh coverage includes every enabled pair and newly admitted asset; preserve existing one-minute financial worker cadence and do not slow/disable workers.

### Phase C — unify consumers

- UI: remove the `auto_discovered` display-only trade blocks only after server provisioning is authoritative; render a pending/error state if price or identity validation prevents admission.
- Server: centralize pair validation used by Market, Limit, TP/SL, Stop-Limit and all workers. Do not trust a client-supplied symbol-to-asset mapping.
- Keep the existing fresh-price check, balance locks, reservations, fees, active-account enforcement, RLS, SECURITY DEFINER search paths, and service-role worker grants.

### Phase D — regression and operational proof

Required tests in disposable PostgreSQL / test branch:
- existing catalog asset with low volume and rank above 2,000 is still provisioned when identity and price are valid;
- new asset admitted to catalog is provisioned automatically without manual admin activation;
- concurrent duplicate admission is idempotent and yields one pair;
- duplicate ticker / same ticker with different canonical IDs fails closed without selecting a winner;
- USDT as a base symbol, malformed symbols, missing provider ID, zero/negative price, stale price, and unsupported quote are rejected;
- missing/disabled pair is rejected by every server entrypoint and worker;
- Market, Limit, TP/SL and Stop-Limit can complete their lifecycle for a newly admitted asset in a disposable environment;
- worker cannot fill an order if pair mapping or price becomes invalid/stale;
- unauthenticated callers cannot submit trades; users cannot write pair tables; only service_role can invoke workers;
- catalog refresh retry and partial provider failure do not leave a half-admitted asset or stale enabled pair.

Required source-parity checks:
- test SQL must execute the real selected migration/function bodies, not miniature lookalikes;
- verify all production dependencies, grants, triggers, and worker paths are represented;
- do not claim Production equivalence from a simplified fixture.

## Explicit non-actions / release gates

This plan is source review and design only. It does not modify Production, enabled pairs, prices, balances, orders, trades, reservations, cron jobs, workers, Edge Functions, grants, RLS, or infrastructure. No migration or `supabase db push` is authorized. No merge, deploy, APK/Pages release, or paid plan change is authorized. Any Production rollout requires separate explicit owner approval after test evidence and a reviewed migration plan.


### Phase A addendum — privileged writer boundary discovered (2026-11-27)

Before implementing provisioning, Phase A must also reconcile these Production writer paths:

- `public.refresh_crypto_assets()` upserts canonical catalog metadata and may change the ticker from CoinGecko.
- Active Edge Function `admin-refresh-crypto-asset` v2 also updates `crypto_assets.symbol` using the service-role key. Its current source validates ticker syntax but does not check all active catalog collisions or atomically update/reject a conflicting existing pair mapping.
- `public.refresh_market_prices()` is not the only `market_prices` writer: active Edge Functions `index-ts` v3 and `refresh-market-prices` v5 also upsert a hard-coded limited Binance symbol set. A future price scheduler must define precedence across these writers and full-catalog coverage; it cannot assume the SQL Cron function is the sole writer.
- `anon`/`authenticated` are SELECT-only on the four core tables and their RLS policies are read-only, but `service_role` has broad direct DML privileges. Inventory every active Edge Function and external service-role caller before claiming complete write-path coverage.
- `exchange_asset_observations` sync and the `auto_list_verified_exchange_asset` trigger stage/list observations; they do not themselves create canonical `crypto_assets` rows or trading pairs. `admin_market_listings` is not the canonical asset catalog.

**Blocking design requirement:** all mutations that can change canonical ID, active status, or ticker must pass one shared collision-aware admission/reconciliation path. Metadata refresh may update price/name/image fields, but a ticker change that conflicts with another active canonical asset or an enabled pair must fail closed or be atomically reconciled under the same canonical-identity lock. No such change is implemented in this PR yet.


### Provider-observed timestamp contract (added 2026-11-27)

- A price observation must carry two distinct timestamps: provider-observed/update time and local receive/process time. The latter must never be substituted for the former when deciding whether a quote is fresh.
- CoinGecko's `/simple/price` endpoint supports `include_last_updated_at=true` and returns `last_updated_at` as a Unix timestamp per canonical CoinGecko ID. The future scheduler request must ask for it explicitly, convert seconds to `timestamptz`, and fail closed/retry if the field is absent, invalid, stale, or implausibly future-dated. See CoinGecko support documentation: https://support.coingecko.com/articles/7785031254-how-can-i-determine-if-the-pricing-data-for-the-coin-is-outdated-or-stale and API reference: https://coingecko-api-v3.readme.io/v3.0.1/reference/simple-price.
- Keep `received_at` separately for latency/operations metrics. For KuCoin/Gate.io and any additional provider, first verify the meaning and units of its source timestamp; do not treat a last-fetch timestamp as a last-price-update timestamp without evidence.
- The current captured Production CoinGecko simple-price request does not include `include_last_updated_at`; its current `market_prices.updated_at` therefore records local processing time, not an independently proven provider observation time. This is a blocker for strict provider-observed freshness until the request/response contract is changed in a reviewed candidate.
- Candidate fixture now parses `last_updated_at`, passes that observation time to the freshness validator, and retries responses with missing/invalid observation timestamps. Its CI remains required before further design claims.


### Duplicate ticker versus canonical ledger identity — blocking architecture item (2026-11-27)

- Production has a large number of duplicate active ticker groups. `crypto_assets` has no unique active-symbol constraint; `demo_trading_pairs` instead enforces unique `pair_symbol` and unique `base_coingecko_id`.
- The current financial schema is ticker/string-oriented: `orders.symbol`, `trades.symbol`, `conditional_orders.symbol`, `asset_balances.asset`, and `order_reservations.asset` are text fields. Reviewed RPCs/workers derive the base asset by stripping the `USDT` suffix from `symbol` and use that base string for balances/reservations.
- Therefore merely creating synthetic pair symbols for duplicate tickers is not a safe complete solution: it can leak synthetic aliases into balances, reservations, portfolio display, and worker matching. Rejecting duplicate ticker IDs is safe fail-closed behavior, but it does not yet satisfy the owner's all-catalog-assets-tradable requirement.
- Before claiming all catalog assets can trade, design and test a canonical internal asset identity (preferably immutable provider/canonical asset ID) through pair mapping, orders, trades, reservations, balances, portfolio display, and all workers. Public/display ticker may remain non-unique; internal ledger identity must not.
- The disposable candidate must add two separate cases: (1) duplicate ticker IDs remain distinct and can trade using an approved unique internal mapping; (2) any ambiguous/unresolved mapping fails closed without crediting or reserving the wrong asset. No Production schema change is proposed or performed here.
