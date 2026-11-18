# Demo Futures Oracle — Operations, Observability and Incident Contract

Date: 2026-11-18
Status: design-only; no collector, scheduler, alert, production telemetry, or database change is authorized.

## Purpose and boundary

This document defines what a future trusted Oracle collector and publication service must expose to operators without deciding financial policy. It does not choose a quorum, price-deviation limit, freshness limit, symbol eligibility, liquidation trigger, execution policy, or service-level objective. Those require separate risk approval and historical evidence.

All metrics and operational records must distinguish:
- collection/transport health;
- evidence and normalization validity;
- publication lifecycle health;
- price-policy eligibility and risk usability.

A transport-success metric must never imply that a price is healthy or usable for risk.

## Required lifecycle telemetry

Every cycle has a stable cycle ID, symbol, immutable policy version, start/end timestamps, terminal state, and a bounded failure code. Every provider attempt has a stable provider ID, endpoint key, attempt number, request/receive times, HTTP status class, parser version, payload hash, and terminal result. Never put raw payloads, credentials, arbitrary provider error strings, user/account IDs, or unbounded symbol values in metric labels.

### Counters

- cycles_started_total by bounded outcome dimensions (environment, venue-independent service region, terminal state);
- cycles_terminal_total by terminal state and bounded reason code;
- provider_attempts_total by provider, endpoint key, status class, and accepted/rejected/transport-failed result;
- provider_payload_conflicts_total by provider and conflict class;
- snapshot_publication_total by healthy/non-healthy result and bounded reason;
- idempotent_retries_total by operation kind and replay outcome;
- invariant_rejections_total by invariant code;
- collector_restart_total and worker_crash_recovery_total by component.

### Histograms and gauges

- provider_request_duration_seconds by provider and endpoint key;
- cycle_completion_duration_seconds by bounded terminal state;
- publication_transaction_duration_seconds;
- provider_source_age_seconds (receive time minus provider event time; preserve endpoint-level timestamps);
- pending_provider_count by cycle state;
- oldest_open_cycle_age_seconds;
- last_successful_cycle_timestamp_seconds by symbol only where symbol cardinality is explicitly bounded by the supported-instrument registry;
- queue_depth and worker_inflight_count by fixed worker pool;
- policy_version_active gauge only as an operational inventory signal, never as a policy approval signal.

Metric labels must use allowlisted values and bounded cardinality. Detailed symbol/provider/cycle diagnostics belong in access-controlled structured logs or queryable audit records, not metric labels by default.

## Structured event and trace contract

Emit correlated structured events for cycle creation, provider request start/finish, normalization acceptance/rejection, constituent evidence capture, snapshot publication, timeout closure, retry, and crash recovery.

Each event should carry:
- event ID, cycle ID, provider ID where applicable, trace ID, event time, received time;
- symbol and immutable policy version;
- endpoint key, instrument-map version, parser/normalizer version;
- attempt number, HTTP status class, bounded reason code;
- raw-body SHA-256 and canonical observation hash where applicable;
- constituent snapshot ID and hash where applicable;
- publication snapshot ID and final state where applicable.

Never log API credentials, authorization headers, cookies, private keys, service-role tokens, or unrestricted request headers. Avoid logging full raw provider bodies in application logs; preserve raw evidence only in the separately access-controlled immutable evidence store described by the provenance design.

## Alert conditions (thresholds intentionally unset)

The following are alert classes, not numerical thresholds. Thresholds, evaluation windows, routing, and paging severity must be set only after historical replay and an operational SLO review.

1. **Stalled cycle:** a cycle remains open or has pending providers beyond its configured bounded deadline.
2. **No healthy publication:** a supported symbol has no recent healthy snapshot within its approved freshness contract.
3. **Provider degradation:** elevated transport failures, rate limiting, timeouts, or latency for a provider/endpoint.
4. **Evidence rejection spike:** malformed payloads, timestamp anomalies, instrument mismatch, missing constituents, or parser-version incompatibility increase.
5. **Source composition change:** constituent membership, weights, aliases, or source type changes beyond a reviewed change classification.
6. **Quorum/source-family failure:** insufficient eligible source diversity or unmeasurable overlap; do not downgrade silently to an older snapshot.
7. **Publication invariant violation:** duplicate/conflicting provider result, pending provider at publication, source-set mismatch, or non-atomic publication attempt.
8. **Clock anomaly:** provider timestamps are implausibly future-dated, regress unexpectedly, or disagree across endpoints beyond the yet-to-be-approved validation contract.
9. **Crash/replay loop:** repeated restart/retry without terminal cycle closure.
10. **Telemetry blind spot:** metrics, logs, or traces stop arriving while the collector is expected to be active.

Alert payloads must include the cycle/provider IDs and bounded reason code, but no secret or raw private payload. Every alert must link to a runbook and explicitly state whether the affected data is unusable for risk.

## Fail-closed operational state machine

- Missing, stale, malformed, conflicting, or untraceable newest evidence must not be replaced with an older healthy observation.
- A cycle with pending providers cannot publish a healthy snapshot.
- A non-healthy terminal cycle must publish no usable mark/index values.
- If constituent evidence required for independence analysis is absent, stale, or unparseable, the affected venue cannot be counted as an independent source.
- If observability is unavailable, the service must not claim health; fail closed according to the future approved policy.
- Recovery requires a new complete cycle and immutable evidence; operators must not edit old observations or snapshots to restore health.

## Incident runbooks

### Provider timeout or rate limiting
1. Preserve the cycle and attempt IDs and endpoint timestamps.
2. Apply only bounded retry/backoff rules from the approved adapter contract.
3. Do not alter source weights, quorum, or thresholds during incident response.
4. Close the cycle as non-healthy if its deadline expires; publish no usable price.
5. Verify recovery using a new cycle and exact provider evidence.

### Malformed or conflicting payload
1. Preserve raw response hash, parser version, endpoint identity, and bounded rejection code.
2. Do not overwrite the first accepted provider/cycle result.
3. Treat a changed payload under the same idempotency key as a conflict.
4. Escalate schema changes for adapter review; never hot-patch a parser without versioning and replay tests.

### Constituent composition change
1. Archive the raw endpoint response and immutable normalized constituent snapshot.
2. Compare canonical venue/pair identities, weights, multipliers, and source types against the prior snapshot.
3. Keep unknown aliases unresolved; do not infer independence from display names.
4. Suspend independence credit for unmeasurable or stale composition pending risk review.

### Publication or storage invariant failure
1. Stop further publication attempts for the affected cycle.
2. Verify transaction rollback and confirm no partial snapshot/provider state remains.
3. Preserve database error class and trace/cycle IDs without exposing secrets.
4. Retry only with the same idempotency key and identical payload after the cause is resolved; a changed payload requires a new cycle.

### Collector restart or replay
1. Reconcile open cycles and provider states from durable storage, not process memory.
2. Resume only idempotent operations with the same cycle/provider keys.
3. Never synthesize missing provider results or mark pending rows terminal without evidence.
4. Confirm a single terminal snapshot per cycle before enabling subsequent processing.

## Retention, access and audit requirements

Retention periods are NOT DECIDED and must be set by legal, security, storage-cost, and incident-response review before deployment. Until then:
- preserve immutable raw endpoint hashes and normalized evidence linkage;
- retain append-only policy, parser, alias-map, and instrument-map version references;
- restrict raw evidence and diagnostic logs to audited operator roles;
- record every evidence export, access, and administrative action;
- define deletion/compaction only as a versioned, auditable archival policy that does not mutate historical evidence relied upon by a risk decision;
- synchronize clocks and retain both provider event time and trusted server receive time.

## Disposable-CI verification matrix (design only)

Before any collector deployment, add isolated tests for:
- counter/gauge cardinality allowlists and secret redaction;
- cycle/provider/trace correlation across retry and crash recovery;
- alert classification for each bounded failure reason;
- no healthy signal for stale, malformed, conflicting, or constituent-incomplete evidence;
- telemetry outage causing explicit unknown/unhealthy state;
- no older-snapshot fallback after newest-cycle failure;
- log/event emission only after the corresponding transaction commits, with rollback emitting failure evidence but no false publication-success event;
- idempotent recovery after process restart;
- access control and audit of raw evidence and diagnostic exports.

These tests must run only against disposable PostgreSQL and isolated test telemetry sinks. A green CI run is not approval to deploy a collector or use prices for financial risk.

## Explicit non-goals

This contract does not implement telemetry, alerts, an HTTP/WebSocket collector, scheduler, RPC, database migration, price policy, risk engine, liquidation execution, or Futures UI. No production credentials, secrets, cron jobs, or Supabase Production changes are authorized.
