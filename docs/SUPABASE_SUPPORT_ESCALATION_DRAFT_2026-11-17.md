# Supabase Support request — DigiArz Auth / PostgreSQL timeouts

**Project:** DigiArz (`gfoaubfilhttnwjykaox`) · **Region:** `us-west-2` · **Postgres:** 17.11.0.018 · **Plan:** Free / shared Nano compute  
**Affected services:** Auth password-token endpoint, PostgreSQL, pg_cron, PgBouncer  
**Incident window:** 2026-11-17, approximately 08:25–15:08 UTC

## Summary and impact

Intermittent password-login requests to `/auth/v1/token` fail after roughly 10–19 seconds with HTTP 504 or 500. Auth logs include `context deadline exceeded`, `error finding user: context canceled`, and failed local connections to PostgreSQL at `[::1]:5432`. Login is unreliable; the logs do not establish that the issue has recovered.

## Verified evidence

- 241 PostgreSQL `canceling statement due to statement timeout` events in a six-hour query; latest at 15:07:39 UTC.
- Repeated pg_cron `job startup timeout` events across many job IDs, continuing through 15:08:12 UTC.
- 185 PgBouncer log events in the six-hour sample, continuing through 15:07:59 UTC; earlier entries explicitly report local server `connect timeout (age=15s)`.
- Auth logs include HTTP 504 and 500 responses. Representative request IDs: `01a1e9a1-58b1-7509-96e3-e33b76581058` and `01a1e9a0-8250-71e3-bf22-5e704ccfef78`.
- At 15:00:10 UTC, multiple Cron jobs reported startup timeouts within the same second.
- Some outbound market-data requests also show unusually long DNS/TCP/TLS phases; whether related is unknown.

## Request

Please correlate host-level CPU throttling, memory/OOM/restarts, disk latency/IOPS, worker saturation, local PostgreSQL listener/connection health, and network path issues during this window. Please explain why Auth and PgBouncer could not establish local PostgreSQL connections while the project reported `ACTIVE_HEALTHY`, and recommend the lowest-risk remediation.

**Do not change database settings, Cron schedules, functions, or data without discussing the proposed action first.** Customer-side investigation so far has been read-only; no Production database changes were made.