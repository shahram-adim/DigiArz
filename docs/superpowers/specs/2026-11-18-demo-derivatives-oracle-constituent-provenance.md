# Oracle constituent provenance schema — 2026-11-18

## Status

Design-only proposal for the demo Futures price Oracle. It is not a migration and has not been applied to any database. Live public API samples could not be retrieved from the current network/browser access path during this checkpoint. Therefore this design deliberately does not assume an unverified OKX response shape.

## Why the current schema is insufficient

The current draft stores one provider timestamp and one response SHA-256 on each provider observation. That is insufficient for venues whose mark, index, and constituent evidence come from separate endpoints. A single timestamp/hash would hide which endpoint supplied which value and would make later source-overlap analysis impossible to reproduce.

## Proposed append-only evidence model

### 1. Endpoint evidence

Add a private append-only table conceptually named `demo_derivative_price_endpoint_evidence`, keyed by (cycle_id, provider, endpoint_key), with:

- provider and stable endpoint key (for example mark, index, constituents);
- requested instrument/index identifier and normalized symbol-map version;
- HTTP status, received_at, request duration, and provider event timestamp when the endpoint exposes one;
- SHA-256 of the exact raw response bytes;
- raw response JSONB for forensic inspection, plus a schema/version marker;
- parser/normalizer version and a terminal accepted/rejected status with a bounded reason code.

Do not store secrets, authorization headers, or arbitrary request headers. Hash raw bytes before JSON parsing. Preserve the exact hash even when parsing fails.

### 2. Constituent snapshot header

Add an immutable header keyed by UUID and linked to the endpoint evidence row. It records provider, index identifier, symbol, constituent timestamp, received_at, raw response hash, parser version, and the number of normalized rows. The raw response remains available through endpoint evidence; normalized rows are a queryable projection, not a replacement.

### 3. Constituent rows

Store one row per constituent with:
- raw venue/exchange label exactly as returned;
- canonical exchange identity (nullable until alias mapping is verified);
- raw spot pair / instrument label;
- canonical spot instrument (nullable until mapping is verified);
- source type as a constrained value only when the provider explicitly exposes it; otherwise `unknown`;
- price, weight, and multiplier as exact decimal strings on ingestion, converted to PostgreSQL numeric only after strict decimal validation;
- row ordinal and provider-specific metadata JSONB for fields not yet normalized.

Do not infer a source type or exchange identity from a display label. Alias mappings must be versioned and independently reviewable.

### 4. Observation linkage

Extend provider observations to reference the endpoint-evidence set and the constituent snapshot used for that observation. Keep legacy aggregate timestamp/hash only as compatibility summaries. Never discard the per-endpoint timestamps or hashes. For mark/index endpoints, retain separate mark and index timestamps and hashes; the conservative observation timestamp may be the minimum, but it is not a substitute for the originals.

## Security and immutability

- All new objects stay in the non-exposed `private` schema with RLS enabled.
- No direct DML grants to `anon`, `authenticated`, or `service_role`.
- Trusted writes occur only through narrow, audited SECURITY DEFINER RPCs with empty search_path and explicit service-role claim checks.
- Evidence, constituent headers, and constituent rows are insert-only; UPDATE/DELETE triggers reject changes.
- Do not add a public read view or Data API grant.
- CI must test RLS, grants, append-only guards, FK integrity, duplicate endpoint rejection, row-count consistency, and atomic linkage to an accepted observation.

## Required validation before adapter implementation

1. Capture real public responses for BTCUSDT and ETHUSDT from each supported venue, including response bytes and HTTP status.
2. Verify the actual OKX endpoint path, query parameters, response envelope, timestamp semantics, and constituent field names from live samples and current official documentation.
3. Build versioned exchange and instrument alias mappings; unknown aliases remain unresolved and cannot count as independent sources.
4. Calculate weighted overlap by canonical underlying spot venue, including any explicitly reported Futures fallback.
5. Only then define effective quorum and risk thresholds. If constituent evidence is absent, stale, or unparseable, the provider must not count as independent.

## Explicit non-goals

This design does not implement an HTTP collector, WebSocket, cron, worker, live Oracle, risk tier, liquidation, or Futures UI activation. It does not authorize a Production migration. All future implementation and tests must remain on the feature branch and disposable PostgreSQL CI until separately reviewed.
