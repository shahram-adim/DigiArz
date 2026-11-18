# Futures Price Oracle — Provider Adapter and Independence Contract

Date: 2026-11-18  
Status: research/design only. No live collector, Production schema, worker, or trading activation.

## Decision summary

The current venue set (`binance_usdm`, `bybit_linear`, `okx_swap`) is useful for obtaining three venue-published mark/index observations, but it is **not automatically three independent price sources**. Their index values are built from overlapping spot-market constituents, and those constituents can change over time.

Therefore:
- Do not describe a 2-of-3 venue quorum as a 2-of-3 independent-feed quorum.
- Do not set final per-symbol quorum/deviation thresholds from venue count alone.
- Preserve venue observations and constituent-composition snapshots separately.
- Before liquidation/risk use, calculate effective source-family diversity or construct a separately governed reference index from individually observed spot venues.
- Missing/unknown constituent provenance must reduce confidence, never silently count as an independent source.

## Public endpoint contract (initial candidate)

### Binance USDⓈ-M

**Mark and index observation**

- `GET https://fapi.binance.com/fapi/v1/premiumIndex?symbol=BTCUSDT`
- Required fields: `symbol`, `markPrice`, `indexPrice`, `time`.
- Prices are decimal strings; `time` is Unix milliseconds.
- The endpoint returns the venue's mark/index pair, not two independent observations.

**Index constituents**

- `GET https://fapi.binance.com/fapi/v1/constituents?symbol=BTCUSDT`
- Response includes `time` and `constituents[]` with `exchange`, `symbol`, `price`, `weight`.
- Documented request weight: 2.
- Capture this response as a time-versioned provenance snapshot; Binance states constituent composition can change without notice.

### Bybit Linear

**Mark and index observation**

- `GET https://api.bybit.com/v5/market/tickers?category=linear&symbol=BTCUSDT`
- Select exactly one matching `result.list[]` item.
- Required fields: `symbol`, `markPrice`, `indexPrice`; values are decimal strings.
- REST response has top-level `time` in milliseconds. Treat it as response/server-generation time unless the selected transport provides a more precise per-ticker event timestamp.
- WebSocket public ticker messages include a system-generated `ts`; if WebSocket is used, retain snapshot/delta semantics and do not treat omitted delta fields as zero or missing observations.

**Index constituents**

- `GET https://api.bybit.com/v5/market/index-price-components?indexName=BTCUSDT`
- Response includes `updateTime` and `components[]`: `exchange`, `spotPair`, `equivalentPrice`, `multiplier`, `price`, `weight`.
- The published methodology describes a top-six volume-weighted spot basket, hourly weight updates, order-book-derived pricing for abnormal/low-activity constituents, and possible Futures-price fallback when spot data is inadequate. Composition and source type are therefore dynamic.
- Persist the component exchange, spot pair, weight, multiplier, and update timestamp; do not infer independence from the venue name.

### OKX SWAP

**Mark and index observations**

- Mark: `GET https://www.okx.com/api/v5/public/mark-price?instType=SWAP&instId=BTC-USDT-SWAP`
  - Normalize `data[0].markPx` and `data[0].ts`.
- Index: `GET https://www.okx.com/api/v5/market/index-tickers?instId=BTC-USDT`
  - Normalize `data[0].idxPx` and `data[0].ts`.
- Both endpoints are public. These are two HTTP responses, so retain separate endpoint timestamps and hashes.
- For the combined venue observation, use the older of the mark/index timestamps as the conservative observation timestamp. Do not substitute local receipt time for either source timestamp.

**Index constituents**

- Candidate endpoint: `GET https://www.okx.com/api/v5/market/index-components?index=BTC-USDT`.
- The official API change notice confirms the endpoint and `index` query parameter, including support for USDC indices. Before adapter implementation, verify the current response schema and timestamp/weight fields with a live public sample and the current OKX docs; do not code against an SDK's undocumented assumptions.

## Cross-venue dependence finding

- Binance's USDⓈ-M index documentation explicitly lists Bybit and OKX among possible constituent venues, alongside Binance, KuCoin, Gate.io, MEXC, Coinbase, Kraken, Bitget, Bitfinex and others. Binance also includes its own Futures last price as a constituent at its discretion.
- Bybit's methodology uses a weighted basket of six major spot pairs. Its component endpoint exposes the actual exchanges, pairs, weights, multipliers and update time.
- Thus Binance and Bybit index prices can directly share underlying spot venues. OKX's component endpoint must be inspected per index before its overlap can be quantified.
- A change in constituent weights or fallback to Futures prices changes the dependence structure even if the provider set is unchanged.

### Required provenance representation

For every symbol and collection cycle, preserve:
- venue/provider ID and exact instrument mapping;
- endpoint identity and API/normalizer version;
- mark timestamp and index timestamp separately;
- mark and index decimal strings exactly as received;
- raw response-body SHA-256 for each endpoint, plus a deterministic combined observation hash;
- local received timestamp and request latency;
- constituent snapshot timestamp and each constituent's exchange, spot pair, weight, multiplier, and source type (spot/order-book/futures fallback when exposed);
- response status, rejection/failure reason, and retry attempt metadata.

The current observation row stores one `provider_timestamp` and one `response_sha256`. Before production adapter rollout, decide whether to add separate mark/index timestamps and hashes plus a linked immutable constituent snapshot. A single minimum timestamp and combined hash may be retained for compatibility, but must not erase the original endpoint-level evidence.

## Normalization and transport rules

1. Parse prices as decimal strings into the existing exact-decimal representation. Never use `parseFloat`, binary floating-point arithmetic, or JSON number coercion for prices/weights.
2. Validate the requested instrument against a versioned symbol map. Reject mismatched, absent, duplicate, delisted, or unexpected response symbols.
3. Require positive finite decimal mark/index prices, supported precision, valid status codes, and a plausible source timestamp.
4. For multi-endpoint venues, reject the entire provider result if either mark or index endpoint is missing, stale, malformed, or for a different underlying/index family.
5. Keep provider event time distinct from local `received_at`; use the older endpoint timestamp as the conservative bundle timestamp.
6. Hash exact response bytes before parsing. If multiple endpoints contribute to one observation, store each raw-body hash and hash a canonical envelope containing endpoint IDs, instrument IDs, timestamps, and normalized decimal strings.
7. Use bounded connect/total timeouts, bounded retries with jitter for transient network/429/5xx errors, and explicit rate-limit handling. Do not retry malformed payloads as if they were transient.
8. A retry must preserve the same cycle/provider idempotency key and payload hash. A changed payload for an already-recorded provider/cycle remains a hard conflict.
9. No stale last-known-good substitution. Timeout, parse failure, missing constituent evidence, or failed quorum must produce a non-healthy state with no usable prices.
10. Do not place service-role credentials or provider secrets in Android/browser code. The market endpoints above are public; collector credentials are not required for these read-only requests.

## Independence policy gate

Before enabling a price policy for risk use:
- Retrieve and archive current constituents for every supported symbol from every venue.
- Normalize exchange aliases and spot-pair aliases to canonical source identities.
- Build a weighted overlap matrix between venue index baskets, including direct shared exchanges and shared upstream spot venues.
- Flag dynamic fallback to Futures prices separately from spot-derived constituents.
- Decide a conservative effective-quorum rule. If the overlap cannot be measured or the source composition is missing/stale, do not count that venue as independent.
- Backtest the proposed reference index and deviation thresholds through calm, volatile, exchange-outage, stablecoin-depeg, and constituent-change periods.
- Keep liquidation disabled until source diversity, fail-closed behavior, and risk review are approved.

## References

- Binance USDⓈ-M Mark Price endpoint: https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Mark-Price
- Binance USDⓈ-M Query Index Price Constituents: https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Query-Index-Price-Constituents
- Binance index methodology and constituent venue list: https://www.binance.com/en/support/faq/detail/360033525071
- Bybit V5 Get Tickers: https://bybit-exchange.github.io/docs/v5/market/tickers
- Bybit V5 Get Index Price Components: https://bybit-exchange.github.io/docs/v5/market/index-components
- Bybit index calculation methodology: https://www.bybit.com/en/help-center/article/Index-Price-Calculation
- OKX API V5 documentation: https://www.okx.com/docs-v5/en/
- OKX index-component endpoint notice: https://www.okx.com/help/changes-to-v5-api-users-as-okx-supports-usdc-index

## Explicitly not done

No collector, scheduler, WebSocket process, Production migration, secret, cron job, mark/index policy activation, liquidation engine, or Futures UI activation has been deployed or enabled.
