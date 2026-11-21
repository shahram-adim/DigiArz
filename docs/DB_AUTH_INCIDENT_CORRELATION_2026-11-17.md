# DigiArz — expanded Auth/PostgreSQL incident correlation

**Observed:** 2026-11-17, unified logs queried through approximately 14:58 UTC  
**Project:** `gfoaubfilhttnwjykaox` (region `us-west-2`)  
**Scope:** read-only inspection of Supabase project metadata, advisors, and unified logs. No Production changes.

## Current project and advisor state

- Supabase Management API reports project status `ACTIVE_HEALTHY`, PostgreSQL 17.11.0.018, region `us-west-2`.
- Health advisors returned no findings.
- Performance advisors reported 9 unindexed foreign keys and 11 RLS init-plan warnings. These are optimization findings, not proof of the immediate Auth incident cause.
- The unified log stream had recent records through approximately 14:58 UTC on 2026-11-17.

## Quantified incident evidence (last 24 hours)

The following are log-event counts from read-only ClickHouse queries; repeated events are not necessarily unique job executions:

- PostgreSQL: **257** events with exact message `canceling statement due to statement timeout`, first observed 08:31:00.563 UTC and last observed 14:58:21.099 UTC.
- pg_cron launcher: repeated `job startup timeout` events. Examples include job 11 (218), job 8 (218), job 12 (215), job 4 (213), job 2 (212), job 9 (210), job 5 (210), job 18 (199), and job 3 (197). These events span 08:28–14:55 UTC.
- PgBouncer: **13** server-side `connect timeout (age=15s)` events across two server connection identifiers, from 09:11 to 13:16 UTC (7 + 6). Additional failed-cancel and idle-client cancel events occurred.
- Auth: **4** `request_timeout` responses with HTTP **504**, between 13:09:59 and 13:16:44 UTC; average logged duration approximately 11.6 seconds.
- Auth: **8** `unexpected_failure` responses with HTTP **500**, between 2026-11-16 15:11 and 2026-11-17 14:10 UTC; average logged duration approximately 11.93 seconds.
- Auth logs also contain explicit `context deadline exceeded`, `error finding user: context canceled`, and a failed connection attempt to `localhost:5432` for `supabase_auth_admin`.

## Important new observation after the previously documented 14:35–14:45 window

PostgreSQL duration logs at approximately 14:57 UTC show:
- `public.process_iran_exchange_asset_sync()` took about **14.65 seconds** in one run and **17.51 seconds** in another.
- `private.auto_activate_verified_exchange_pairs()` took about **17.81 seconds**.
- Multiple Cron jobs (including 3, 4, 8, 9, and 12) also logged successful completion around 14:57 UTC.

This matters because it shows that some scheduled work can complete, while other jobs are still repeatedly failing at startup. The issue is intermittent and not accurately described as a fully unavailable database.

## Interpretation

The evidence now supports a broader and stronger diagnosis than a single slow sync function:

1. PostgreSQL statement timeouts are frequent.
2. pg_cron repeatedly fails during job startup for many jobs.
3. PgBouncer separately records server connection timeouts to the local PostgreSQL endpoint.
4. Auth password-token requests fail after long waits, with errors consistent with database lookup/connection cancellation.

Together these observations strongly support an intermittent PostgreSQL responsiveness / local connection-establishment problem affecting both Auth and scheduled work. They do **not** identify the underlying host-level cause (CPU, memory pressure, storage latency, worker starvation, connection/listener behavior, or a platform-side issue), and they do not prove that any one Cron function is the sole cause.

## Safety and next actions

- Keep PR #10 as Draft. Do not merge.
- Do not change Production Cron schedules/jobs, PostgreSQL settings, Auth settings, grants, functions, migrations, wallets, orders, balances, or financial data as part of this diagnosis.
- Do not run `supabase db push`; migration drift remains unresolved.
- The next decisive evidence must come from Supabase Database Reports / resource metrics for 08:25–15:00 UTC on 2026-11-17: CPU, memory, disk IOPS and latency, connection counts, restarts, and any compute throttling.
- Escalate to Supabase Support with project ref, region, UTC window, representative Auth request IDs, PgBouncer connect-timeout samples, and PostgreSQL/pg_cron counts. Ask them to inspect database host health and local connection establishment.
- Continue to treat the one-minute Iran asset sync and other long-running scheduled functions as candidate workload contributors. Validate query plans and indexes only in a disposable PostgreSQL 17 environment with representative data before proposing a Production change.

This document records diagnostic evidence only; it changes no Production object or data.
