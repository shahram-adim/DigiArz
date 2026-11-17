# Interpretation of pg_cron "job startup timeout" in DigiArz

Date: 2026-11-17  
Branch: diagnostics/auth-cron-connection-pressure

## Corrected chronology: Auth and Cron failures overlap in the same incident window

The explicit Auth loopback connection error was logged at approximately 2026-11-17 13:10 UTC:
`failed to connect to host=localhost user=supabase_auth_admin database=postgres: dial error (dial tcp [::1]:5432: operation was canceled)`.

A targeted PostgreSQL log query for 13:08–13:12 UTC found repeated pg_cron startup timeouts in the same interval (jobs 2, 3, 4, 5, 8, 9, 11, 12, 16, and 18). The same interval also contained:
- `canceling statement due to statement timeout` for `public.process_iran_exchange_asset_sync()`;
- Auth's `supabase_auth_admin` backend disconnecting with `Connection reset by peer` and `unexpected EOF on client connection with an open transaction`;
- several incoming localhost SSL connections ending with `Connection reset by peer`.

A further pg_cron burst occurred at 14:21–14:22 UTC for jobs 2, 3, 4, 5, 8, 9, 11, 12, 14, 16, and 18.

A later recurrence was observed at 14:25–14:38 UTC:
- At 14:25:17–14:25:21, pg_cron startup timeouts occurred for jobs 2, 3, 4, 5, 8, 9, 14, and 18.
- At 14:27:26–14:27:28, `refresh_market_prices()` and `private.auto_activate_verified_exchange_pairs()` were canceled by statement timeout.
- At 14:38:13, startup timeouts were logged for jobs 2, 3, 4, 5, 8, 9, 11, 12, 16, and 18.
- At 14:38:11, a long Supabase Admin/observability query against `extensions.pg_stat_statements` was itself canceled by statement timeout. This is evidence that even a platform monitoring query was not completing within its timeout, but it does not independently identify whether CPU, I/O, locks, or another cause was responsible.

The latest Auth log query (through 14:35 UTC) returned password-token failures at 13:57:42 and 14:10:19 UTC, each taking about 15–19 seconds and ending with `error finding user: context canceled` and HTTP 500 in the Auth service logs. No later Auth event was returned in that sample. The app's displayed HTTP 504 may be a gateway-facing status different from the Auth service's logged 500.

## What the pg_cron message means in this configuration

Live settings observed on the project:
- `cron.use_background_workers = off`
- `cron.host = localhost`
- `cron.max_running_jobs = 32`

With background-worker mode off, pg_cron uses its libpq connection path to start each scheduled command. In the pg_cron implementation, the task remains in its CONNECTING state while `PQconnectPoll()` attempts to establish the connection. If that connection does not complete before the startup deadline, pg_cron sets the error message `job startup timeout`.

Therefore, this message is evidence of failure to complete the job's startup/connection phase. It is **not** evidence that the SQL body of each job ran slowly. It also does not, by itself, prove max_connections exhaustion.

Reference implementation (Debian-packaged pg_cron source, showing CONNECTING/PQconnectPoll and jobStartupTimeout):
https://sources.debian.org/src/pg-cron/1.3.0-2/src/pg_cron.c

## What the sampled logs establish

- Auth connection failures, pg_cron startup timeouts, statement timeouts, and PostgreSQL client/SSL connection resets overlap in the 13:08–13:12 UTC incident window.
- Similar pg_cron startup-timeout bursts recur at 14:21–14:22, 14:25, and 14:38 UTC.
- Statement timeouts affect application refresh/sync work and a Supabase Admin observability query.
- A targeted search in the 14:20–14:24 PostgreSQL log window did not find explicit messages containing too many connections / remaining connection slots, out of memory, fork failure, or terminating connection. Absence of these strings in the filtered sample does not rule out transient connection, CPU, memory, I/O, or platform-level pressure.
- A live `pg_stat_activity` snapshot at a different time showed 11 connections (6 active, 4 idle, 1 null-state), so sustained max_connections exhaustion is not established.
- Repeated management SQL attempts to read `pg_stat_activity` and `cron.job_run_details` now also terminate with connection timeout, so a current connection snapshot and reliable per-job runtime history remain unavailable.

## Revised diagnosis

The strongest current evidence points to a recurring PostgreSQL responsiveness incident affecting more than one client class: Supabase Auth, pg_cron startup connections, application refresh/sync queries, and at least one platform observability query. This is more consistent with a database/host-level responsiveness or resource-pressure problem than with one isolated SQL function. The long-running Iran exchange sync and other refresh jobs may contribute, but their causal role is not proven.

Still unproven:
1. whether the local TCP listener was unavailable, overloaded, or slow;
2. whether transient CPU, memory, I/O, worker, or connection pressure caused the delays;
3. whether particular scheduled jobs materially contribute to the incident;
4. whether a managed platform/database host event caused the symptoms;
5. whether staggered scheduling alone would materially reduce the problem.

## Safe next steps

1. Obtain Supabase Database Observability metrics for 13:08–13:12, 14:20–14:24, 14:25–14:28, and 14:37–14:39 UTC: CPU, memory/swap, IOPS/latency, active connections, and database restarts.
2. Because management SQL and monitoring queries are also timing out, ask Supabase Support to inspect host-level PostgreSQL listener/connectivity, process restarts, resource-pressure, and connection-reset events for these UTC intervals.
3. Capture `pg_stat_activity` and `cron.job_run_details` during a recurrence only if the database management endpoint is responsive; do not repeatedly run heavy diagnostics while it is timing out.
4. Only if run history and metrics show job overlap or resource spikes correlated with failures, prepare a staged/staggered schedule candidate in an isolated PostgreSQL 17 test. Preserve jobs 8, 9, and 12 at their existing one-minute cadence.
5. Do not switch `cron.use_background_workers` on in Production as a speculative fix. That changes the execution model, consumes background-worker capacity, and would require a carefully validated capacity/restart plan.

## CI note

The GitHub Actions run associated with this PR completed successfully, including the repository's existing exact-decimal, PostgreSQL arithmetic, and order-engine integration/race tests. This run did **not** execute the new read-only diagnostic SQL against Production and does not validate or remediate the Supabase incident.

## Safety

No production settings, cron schedules, functions, migrations, grants, order engines, wallets, or financial data were changed.
