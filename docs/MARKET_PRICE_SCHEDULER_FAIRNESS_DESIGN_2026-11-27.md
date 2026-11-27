# Fair market-price scheduler candidate design

> Design only. This document is not a migration and does not authorize Production changes. It is intended for a disposable PostgreSQL candidate after the source-snapshot regression in `supabase/tests/market_price_scheduler_production_snapshot.sql`.

## Problem statement

The captured Production scheduler has two independent jobs:

- Job 3 calls `public.refresh_market_prices()` every minute.
- Job 17 calls `private.request_market_price_overflow()` at minute offsets 5, 15, 25, 35, 45, and 55.

The primary function processes completed responses, removes their tracking rows, checks all provider queues and tracked requests, and immediately schedules the first 515 sorted CoinGecko IDs plus the KuCoin and Gate.io full ticker feeds when the queues are empty. The overflow function refuses to schedule if *any* tracked request exists or any CoinGecko request remains queued. The exact-source disposable test demonstrates one repeatable interleaving in which the primary cycle repopulates tracking before the scheduled overflow call, so IDs after position 515 are never requested in that interleaving.

The test does not prove that every historical overflow invocation starved or establish the exact cause of the five stale Production rows. It proves that the captured guards and cadence can create a fairness failure under a controlled sequence.

## Design goals

1. Every enabled DigiArz trading pair has a durable path to price refresh, regardless of catalog size; no 515/420/899/19,012 hard-coded universe limit.
2. Preserve canonical CoinGecko ID as asset identity. Never map a ticker to an arbitrary asset when IDs collide.
3. Record the exact IDs requested per batch and which IDs the provider actually returned.
4. Ensure omitted, stale, malformed, timed-out, and transiently failed IDs are retried fairly.
5. New catalog admissions receive priority without resetting or starving the normal catalog cursor.
6. Prevent duplicate/concurrent requests with a single scheduler lease/advisory lock and idempotent batch records.
7. Make price-source precedence deterministic per pair; response arrival order must not decide which provider overwrites the market price.
8. Keep execution fail-closed: no order path may consume a missing, zero, stale, or ambiguously mapped price.

## Candidate state model (not yet implemented)

### `private.market_price_scheduler_state`

A singleton row containing:

- `scheduler_key` (fixed primary key);
- `last_completed_coingecko_id` (lexicographic cursor);
- `cycle_started_at` and `updated_at`;
- `lease_owner`, `lease_until`, and `last_success_at`.

The cursor advances only after the associated batch reaches a terminal processing state. When no IDs sort after the cursor, the scheduler starts a new catalog cycle and wraps to the first ID. New admissions are not dependent on the current cursor: they enter a separate priority queue.

### `private.market_price_sync_batches`

Durable one-row-per-request ledger:

- generated `batch_id`, provider, request ID (unique), request URL fingerprint;
- exact `requested_coingecko_ids text[]` and batch ordinal/cycle identifier;
- state (`queued`, `in_flight`, `processed`, `retry_wait`, `failed_terminal`);
- attempt count, queued/response/processed timestamps;
- HTTP status, timeout/error, returned-ID set, omitted-ID set;
- next retry time and compact processing diagnostics.

Keep completed batch metadata long enough for operational audit; do not rely on ephemeral HTTP response rows as the only evidence of requested IDs.

### `private.market_price_sync_priority`

One row per newly admitted canonical asset ID, with a unique ID key, enqueue timestamp, attempt count, and next retry time. Pair provisioning inserts this row in the same transaction that creates the canonical pair mapping. The scheduler services priority IDs before normal cursor batches, while preserving fairness for older retries.

### Retry state

Retry missing IDs individually or in small grouped batches with bounded exponential backoff and jitter. A response that is HTTP 200 but omits an exact CoinGecko ID is a per-asset omission, not a successful price update. Do not copy `crypto_assets.current_price_usd` into `market_prices` unless a separately validated quote conversion and source policy explicitly authorizes it.

## Scheduler sequence

1. Acquire a transaction-scoped advisory lock and a short durable lease; if another scheduler owns it, exit without side effects.
2. Process completed batch responses using the durable `request_id` → `requested_ids` ledger.
3. For each returned ID, require exactly one enabled pair mapped by `base_coingecko_id`, a positive finite price, and valid response metadata. Update only that pair's price.
4. For every omitted or invalid ID, write/update retry state; do not mark it complete.
5. Mark the batch terminal with returned/omitted IDs and response diagnostics.
6. Compute capacity from configured maximum in-flight batches and provider rate-limit budget. Do not require every provider queue to be empty before making progress on unrelated IDs.
7. Schedule due new-admission priority IDs and retries fairly; then schedule the next lexicographic cursor batch.
8. Advance the cursor only when a batch's requested IDs have been accounted for (priced, retry-scheduled, or explicitly rejected with a reason).
9. Revisit stale enabled pairs through a separate freshness sweep so an asset cannot silently fall out of the rotation.

The exact maximum in-flight count, batch size, rate-limit budget, and retry delays must be measured in disposable tests and checked against provider limits before any future Production proposal.

## Price-source policy

The current captured function allows CoinGecko, KuCoin, and Gate.io responses to update the same `market_prices.symbol`; response processing order determines the final source. Candidate code must replace this with an explicit per-pair policy, for example:

- canonical provider-ID source for CoinGecko;
- exchange ticker sources only when an exact, independently verified base/quote mapping exists for the pair;
- explicit source priority and freshness thresholds;
- no overwrite by a lower-priority or older observation;
- retain source, provider observation time, received time, and exact asset/pair mapping evidence.

A matching ticker string alone is not sufficient proof of canonical identity, especially with the observed duplicate-ticker catalog.

## Admission and trading integration

The all-catalog-assets requirement means a catalog asset cannot be admitted as a permanently display-only row. The eventual canonical admission transaction must:

1. validate canonical provider ID and identity;
2. validate global symbol uniqueness or apply a separately approved unique pair-symbol policy;
3. provision exactly one canonical pair row idempotently;
4. enqueue immediate priority price work;
5. expose a clear pending-price state until a trusted fresh quote exists;
6. enable demo execution only after the price is fresh and the server-side identity mapping is unambiguous.

The same pair identity and freshness rule must be enforced by Market, Limit, Stop-Limit, TP/SL placement, all workers, and UI market loading. Client-supplied ticker/ID mappings are never authoritative.

## Required disposable PostgreSQL 17 tests

- Catalog sizes 516, 899, 19,012, and larger than one full cycle; no fixed-size truncation.
- Cursor reaches the final ID, wraps, and does not starve any ID.
- An ID inserted lexicographically before/after the cursor is eventually serviced; a newly admitted asset receives priority.
- HTTP 200 with an omitted ID creates a retry; retries do not block unrelated IDs.
- HTTP errors, timeouts, malformed JSON, zero/negative/non-finite prices, partial batches, and delayed responses preserve durable state.
- Duplicate request/response delivery is idempotent; stale/late response cannot overwrite a newer accepted price.
- Two scheduler sessions cannot claim the same IDs or create duplicate in-flight batches.
- Provider omission and exchange coverage gaps remain visible as per-asset status, not silent stale prices.
- Source priority is deterministic under every response-arrival order.
- Duplicate ticker / distinct canonical IDs fail closed unless a separately validated unique pair-symbol strategy exists.
- Newly provisioned pair receives price work and cannot trade until fresh trusted price is available.
- All Spot/Market, Limit, Stop-Limit, TP/SL, and worker entrypoints use the same canonical pair mapping.
- Unauthorized callers cannot mutate scheduler state, batches, priority queue, or pair mappings.

## Release boundary

This candidate remains design-only. Do not change Production Cron, HTTP queues, market prices, pairs, functions, grants, RLS, workers, Edge Functions, or infrastructure. Any future schema/function migration must first pass exact-source and candidate tests in disposable PostgreSQL and then receive explicit owner approval before any Production action.
