# Private Futures Price Oracle Storage — Design

Date: 2026-11-18
Status: disposable PostgreSQL draft only; no Production migration, collector, or public RPC.

## Trust boundary
All objects live in non-exposed `private`. No anon/authenticated table grants. RLS is enabled as defense in depth; the trusted server collector uses a server-only `service_role` database context. Never ship that credential to Android/browser. This is separate from the existing user-facing derivatives RPC wrappers in the same schema: no oracle table privilege is granted to authenticated users.

## Data model
- `demo_derivative_price_policies`: immutable, versioned per-symbol thresholds and eligible provider allowlist. A partial unique index permits only one enabled policy per symbol. Thresholds remain unset in Production until historical replay.
- `demo_derivative_price_cycles`: one atomic collection cycle per symbol and policy version, with explicit expected providers and terminal state.
- `demo_derivative_price_cycle_sources`: one row per expected provider; records instrument mapping, pending/received/failed state, source timestamp, server receipt timestamp, response hash, and failure reason.
- `demo_derivative_price_observations`: append-only normalized raw mark/index observations or rejection records, one per provider per cycle.
- `demo_derivative_price_snapshots`: append-only consensus result; healthy prices are mandatory only for healthy status. Non-healthy snapshots contain no usable price.

## Atomic publication protocol
1. Trusted collector creates a cycle and all expected-provider rows in one transaction.
2. Each adapter submits one normalized observation and transitions its provider row from pending to received/failed.
3. Snapshot insert is rejected while any provider is pending, unless all providers have terminal outcomes.
4. Snapshot source set must match received provider rows; healthy snapshots must meet the policy quorum.
5. Cycle can become completed only after a snapshot exists; it then becomes immutable.
6. A timeout/failure cycle still publishes a non-healthy snapshot with null prices, then closes. No stale last-known-good price is substituted.
7. Future implementation must wrap cycle creation, per-provider result, and snapshot publication in narrow service-only RPCs or a trusted transaction client; do not grant clients table access.

## Provenance caveat
Three exchange endpoints are three venue operators, not necessarily three statistically independent underlying price feeds. Exchange index prices may themselves aggregate overlapping spot venues. The current design records venue and instrument provenance but does not yet establish constituent-level independence. Do not call the quorum "independent feeds" until constituent coverage, weights, and overlap have been researched. A policy must consider source-family diversity and avoid double-counting correlated index baskets.

## Security / lifecycle invariants
- Policy rows, observations, and snapshots are append-only. Threshold changes create a new policy version.
- Provider/cycle state can transition only from pending/collecting to a terminal result.
- Cycles cannot complete with pending providers or without a snapshot.
- Snapshot publication cannot precede terminal provider results.
- Healthy snapshot requires at least two received sources and a policy quorum.
- Oracle objects are private, RLS-enabled, and not granted to client roles; service_role has no UPDATE/DELETE on immutable evidence.
- These tables do not fetch data, compute medians, authenticate provider HTTP responses, or execute liquidations. The pure JS consensus helper remains the deterministic calculation layer.

## Deferred before any collector
- Validate exchange instrument listing, delisting, API timestamp semantics, WebSocket sequencing, rate limits, and failover.
- Verify raw payload hash canonicalization and signature/transport provenance.
- Design service-only ingestion/publication RPCs with cycle idempotency and concurrent worker safety.
- Backtest per-symbol thresholds and source-family overlap using historical data.
- Add crash/retry, duplicate batch, provider partial timeout, and race tests.


## Provider adapter and constituent-independence research — 2026-11-18

- Binance USDⓈ-M exposes the mark/index pair from `/fapi/v1/premiumIndex` and constituent detail from `/fapi/v1/constituents`.
- Bybit V5 exposes mark/index from `/v5/market/tickers` and underlying basket composition from `/v5/market/index-price-components`.
- OKX requires separate mark and index endpoints; its `/api/v5/market/index-components` endpoint is the candidate constituent source. Exact response schema remains a live-sample verification gate.
- Binance's documented index basket can include Bybit and OKX; Bybit's six-pair spot basket can overlap with Binance/OKX and dynamically changes weights. Therefore the current three venue observations are correlated composites, not three independent feeds.
- Detailed transport, timestamp, exact-decimal, response-hash and constituent-provenance requirements are recorded in [the adapter contract](2026-11-18-demo-derivatives-oracle-adapter-contract.md).
- No final quorum or per-symbol thresholds are approved. Preserve constituents and calculate source-family overlap before enabling risk use.
