# Supabase Support request — DigiArz Auth / PostgreSQL timeouts

**Project:** DigiArz (`gfoaubfilhttnwjykaox`) · **Region:** `us-west-2` · **Postgres:** 17.11.0.018 · **Plan:** Free / shared Nano compute  
**Affected services:** Auth password-token endpoint, PostgreSQL, pg_cron, PgBouncer  
**Incident window:** 2026-11-17, approximately 08:25–15:13 UTC

## Summary and impact

Intermittent password-login requests to `/auth/v1/token` failed after roughly 10–19 seconds with HTTP 504 or 500. Auth logs include `context deadline exceeded`, `error finding user: context canceled`, and failed local connections to PostgreSQL at `[::1]:5432`. Login reliability remains unconfirmed; absence of newer Auth log entries is not evidence of recovery.

## Verified evidence

- Earlier six-hour query: 241 PostgreSQL `canceling statement due to statement timeout` events and 185 PgBouncer log events.
- Latest one-hour query (through 15:12:24 UTC): 40 PostgreSQL statement-timeout events and 265 pg_cron startup-timeout events. These are log-event counts, not unique execution counts.
- In that one-hour sample, startup timeouts repeatedly affected jobs 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16, 17, and 18. Jobs 11 and 9 each had 27 startup-timeout events; job 18 had 26.
- Latest observed pg_cron startup-timeout event was 15:12:10 UTC; latest PostgreSQL statement-timeout event was 15:12:24 UTC.
- Earlier PgBouncer entries explicitly reported local server `connect timeout (age=15s)`. No matching PgBouncer connect-timeout event appeared in the latest one-hour query; this does not prove local connection health.
- Auth logs include HTTP 504 and 500 responses. Representative request IDs: `01a1e9a1-58b1-7509-96e3-e33b76581058` and `01a1e9a0-8250-71e3-bf22-5e704ccfef78`. No Auth timeout marker appeared in the latest one-hour query.
- At 15:00:10 UTC, multiple Cron jobs reported startup timeouts within the same second.
- Some outbound market-data requests showed unusually long DNS/TCP/TLS phases; whether related to Auth is unknown.
- The project API reports `ACTIVE_HEALTHY` and health advisors currently return no lints. Neither establishes healthy query latency or local connection establishment.

## Request

Please correlate host-level CPU throttling, memory/OOM/restarts, disk latency/IOPS, worker saturation, local PostgreSQL listener/connection health, and network path issues during this window. Please explain why Auth and PgBouncer could not establish local PostgreSQL connections while the project reported `ACTIVE_HEALTHY`, and recommend the lowest-risk remediation.

**Do not change database settings, Cron schedules, functions, or data without discussing the proposed action first.** Customer-side investigation so far has been read-only; no Production database changes were made.