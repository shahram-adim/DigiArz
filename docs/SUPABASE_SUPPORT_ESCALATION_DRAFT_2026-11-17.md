# Supabase Support escalation draft — DigiArz Auth / PostgreSQL incident

**Project:** DigiArz  
**Project ref:** `gfoaubfilhttnwjykaox`  
**Region:** `us-west-2`  
**Postgres:** 17.11.0.018  
**Plan:** Free (Nano/shared compute)  
**Affected service:** Supabase Auth password grant, PostgreSQL, pg_cron, PgBouncer  
**Incident window:** 2026-11-17 08:25–15:01 UTC (with earlier Auth 500 evidence on 2026-11-16)

## Request to Supabase Support

Please investigate intermittent PostgreSQL host responsiveness and local connection establishment for this project. Auth password-token requests intermittently fail after 10–16 seconds, while PostgreSQL logs show frequent statement timeouts, pg_cron launcher startup timeouts, and PgBouncer connection timeouts to the local PostgreSQL endpoint.

Please correlate host-level CPU/CPU throttling, memory and OOM/restarts, disk IOPS/throughput/latency, connection slots and listener health, worker/process saturation, DNS/network path to external price providers, and any platform maintenance or host events.

Please confirm whether the project experienced compute throttling, database restarts, local listener/connection-establishment degradation, or resource exhaustion during the stated window. We are not asking Support to change database settings, schedules, functions, or data without discussing the proposed action first.

## Representative evidence

- Project status returned `ACTIVE_HEALTHY` during investigation; this did not prevent intermittent failures.
- PostgreSQL: 257 statement-timeout events in the prior 24-hour log query; a narrower two-hour query returned 75 such events.
- pg_cron: repeated launcher `job startup timeout` events across jobs 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16, 17 and 18. At 15:00:10 UTC, many jobs emitted startup timeouts within the same second.
- PgBouncer: 13 server-side `connect timeout (age=15s)` events in the 24-hour sample, targeting `postgres/pgbouncer@[::1]:5432`.
- Auth: 4 HTTP 504 `request_timeout` events from 13:09:59 to 13:16:44 UTC, plus 8 HTTP 500 `unexpected_failure` events. Representative request ID: `01a1e9a1-58b1-7509-96e3-e33b76581058` (HTTP 504, 2026-11-17 13:11:00 UTC). Another representative request ID: `01a1e9a0-8250-71e3-bf22-5e704ccfef78` (HTTP 500; failed local connection to `localhost:5432`, 2026-11-17 13:10:23 UTC).
- PostgreSQL/Auth errors include `context deadline exceeded`, `error finding user: context canceled`, and a failed local TCP connection to `[::1]:5432`.
- Market-price provider calls also showed severe DNS/TCP delays: CoinGecko DNS lookup around 84.6 seconds in one log; other CoinGecko/Gate.io/KuCoin calls showed multi-second DNS and TLS/TCP handshake delays and timed out. Please determine whether these outbound network delays reflect provider/network conditions or shared host/network pressure. They may be a separate contributor and are not proven to cause Auth failures.
- `public.process_iran_exchange_asset_sync()` was canceled twice with SQLSTATE 57014 in the 14:35–14:45 UTC window; later runs took approximately 14.65 and 17.51 seconds. This is a candidate workload contributor, not a proven sole root cause.

## Questions

1. Did the underlying database host have CPU, memory, disk, worker, connection/listener, or restart events during 08:25–15:01 UTC?
2. Why did PgBouncer fail to establish local connections to `[::1]:5432` while the project status remained active?
3. Are the pg_cron launcher startup timeouts caused by local PostgreSQL connection-establishment delays, worker starvation, or another platform issue?
4. Are the prolonged DNS/TCP handshake times for external price providers expected for this region/compute, or do they indicate a networking issue?
5. What is the lowest-risk remediation? Please provide any expected cost and downtime before recommending a compute change.

## Safety / customer-side actions

We have not changed Production cron schedules, PostgreSQL settings, Auth configuration, functions, grants, wallets, orders, balances, or financial data. We are preserving the diagnostic PR as Draft and are not running `supabase db push` because the repository has unresolved migration drift.
