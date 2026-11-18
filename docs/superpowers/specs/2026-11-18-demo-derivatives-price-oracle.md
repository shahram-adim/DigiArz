# DigiArz Futures Mark/Index Price Oracle — Design Specification

Date: 2026-11-18
Repository: shahram-adim/DigiArz
Branch: feat/demo-derivatives-trading
Status: design + deterministic consensus primitive; no live collector, migration, or Production changes.

## 1. Problem and current-state finding

The current public.market_prices path is a last-price cache. Scheduled ingestion currently stores one row per symbol and overwrites price, source, and updated_at as CoinGecko, KuCoin, and Gate.io responses arrive. It does not preserve simultaneous per-provider observations, provider timestamps, index values, mark values, or a durable source quorum. It is suitable for market display, not an automated liquidation oracle.

The existing Futures external-reduction RPC accepts a trusted worker-supplied execution price and fee. It is a position-reduction primitive, not a price source, mark-price calculator, or liquidation engine.

## 2. Provider adapters to evaluate

Use public, read-only linear USDT perpetual market-data endpoints; no exchange account credentials or trading permissions are needed.

| Provider ID | Instrument scope | Required values | Provider time |
|---|---|---|---|
| binance_usdm | USDⓈ-M perpetual, BTCUSDT style | markPrice, indexPrice | time |
| bybit_linear | category=linear, BTCUSDT style | markPrice, indexPrice | response envelope time |
| okx_swap | instType=SWAP, map BTC-USDT-SWAP to BTCUSDT | markPx plus separately fetched index ticker idxPx | each response ts |

Provider product listing must be checked before accepting a symbol. Do not infer that a spot pair has a corresponding perpetual contract. Provider response timestamps and server receipt timestamps are both mandatory.

Official API references:
- Binance USDⓈ-M premiumIndex: https://developers.binance.info/en/docs/catalog/core-trading-derivatives-trading-usd-s-m-futures/api/rest-api/market-data
- Bybit V5 linear tickers: https://bybit-exchange.github.io/docs/v5/market/tickers
- OKX public market data: https://www.okx.com/docs-v5/en/

## 3. Trust and ingestion boundary

- A separate trusted server-side collector owns provider HTTP/WebSocket connections. Android, browser JavaScript, and user-callable RPCs cannot submit price observations.
- Prefer provider WebSocket streams for low-latency collection; REST polling may be used for startup/reconciliation and bounded fallback only. Do not run a second-by-second liquidation loop in a browser, or rely on minute-granularity pg_cron for a latency-sensitive risk oracle.
- The collector normalizes decimal strings and provider timestamps, stamps received_at on the server, validates instrument mapping, and submits batches through a narrow authenticated server-only ingestion RPC.
- No exchange API key is required for public market data. Any collector credential is server-only; Supabase service_role is never placed in the app or sent to users.
- Raw observations are append-only; partition/retention policy is decided from measured volume. Do not overwrite one venue with another.
- Keep oracle tables/functions in a non-exposed schema (prefer private), revoke all client-role privileges, and do not add public Data API grants. Supabase's 2026 Data API change means newly-created public tables are not automatically exposed by default, but that is not a substitute for private-schema isolation and explicit grants.

## 4. Deterministic consensus contract

A pure exact-decimal consensus helper is introduced separately from transport adapters. It:
1. Accepts only the explicit provider allowlist and one normalized symbol.
2. Requires unique provider contribution; duplicate observations from one venue cannot increase quorum.
3. Rejects invalid/non-positive decimal strings, symbol mismatches, malformed timestamps, future timestamps, and stale observations.
4. Checks each venue's own mark/index basis against a pair policy.
5. Computes exact-decimal medians for mark and index independently.
6. Rejects cross-venue outliers against the median; at least the configured independent-source quorum must remain.
7. Recomputes medians from the accepted source set and checks aggregate mark/index basis.
8. Returns healthy only with quorum; otherwise returns no price (stale, insufficient_quorum, or deviation). No last-known-good price is returned as current.
9. Exposes the oldest accepted provider timestamp as asOfMs; the snapshot expires at asOfMs + maxAgeMs.

The deterministic policy interface requires explicit values: minimum sources (2 or 3), maximum age, allowed future clock skew, maximum cross-source mark deviation, maximum cross-source index deviation, and maximum mark/index basis deviation. Thresholds are configuration, not user input. Final per-symbol limits require historical replay/backtesting and must not be guessed or silently widened in code.

## 5. Snapshot and risk consumption model (next database slice)

Proposed private objects, names subject to schema review:
- private.demo_derivative_price_observations: immutable one-row-per-provider/symbol observation with provider, instrument ID, mark, index, provider timestamp, server receipt timestamp, response hash, and validation outcome.
- private.demo_derivative_price_snapshots: immutable accepted/rejected consensus result with source set, source count, mark, index, oldest observation timestamp, policy version, and reason code.
- private.demo_derivative_price_policies: admin-controlled versioned per-symbol thresholds, provider eligibility, quorum, freshness, and enabled state. Client roles get no write access.
- A private latest-snapshot pointer/view may be added only as a cache; immutable snapshot rows remain the audit source.

Every risk-increasing order, fill, funding calculation and liquidation evaluation must read the same currently valid snapshot under the account-first transaction contract. A missing, expired, insufficient, or deviating snapshot blocks risk-increasing activity. Automated liquidation must also fail closed on bad prices; stale data must never be interpreted as a breach.

The next implementation must define atomic snapshot publication so a partially ingested batch cannot be mistaken for a completed source cycle. An ingestion batch/cycle ID and provider completion metadata are required.

## 6. Risk engine boundary

This price oracle does not decide liquidation. After the oracle is tested, separately specify:
- versioned maintenance tiers by symbol/notional, maximum leverage, initial and maintenance margin rates;
- cross-account equity aggregation and liabilities already booked versus accrued;
- close-fee reserve, conservative execution/slippage assumptions, partial-liquidation sizing and retry bounds;
- liquidation fee accounting, insurance fund/deficit waterfall, and explicit behavior if the virtual insurance fund is insufficient;
- deterministic event IDs, idempotent retries, account-first locking, and concurrency with order placement/fill/cancel/manual reduction;
- long/short and isolated/cross boundary tests, stale/outlier recovery, and mark/index discontinuity scenarios.

The existing external reduction RPC must not be wired to a timer or exposed to authenticated clients as a liquidation endpoint. A trusted risk worker may call it only after a separately approved risk engine supplies a server-authoritative execution price and fee.

## 7. Required tests before collector or liquidation RPC

- exact median for odd/even quorum and 18-decimal values;
- two-source disagreement fails closed;
- one outlier among three is excluded only if the remaining quorum agrees;
- one source cannot satisfy quorum even if otherwise fresh;
- duplicate provider rows cannot inflate quorum;
- stale, future-dated, malformed, non-positive and wrong-symbol observations are rejected;
- per-provider and aggregate mark/index basis limits;
- atomic batch publication and crash/retry behavior;
- provider timeout, rate limit, symbol delisting and partial-cycle handling;
- concurrency between new snapshot publication and risk RPCs;
- historical replay/backtesting before final production thresholds.

## 8. Release gates

- No production Supabase object, schedule, Edge Function, secret, or data change in this slice.
- No Data API exposure for oracle objects.
- No derivatives UI activation.
- No use of market_prices as mark/index or liquidation input.
- No automatic liquidation implementation until source quorum, risk tiers, fees, insurance, and worker recovery semantics are approved and tested.
