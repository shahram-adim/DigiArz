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

A further pg_cron burst occurred at 14:21–14:22 UTC for jobs 2, 3, 4, 5, 8, 9, 11, 12, 14, 16, and 18. Thus, the failure pattern recurred later; it was not limited to one short incident.

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

- At 13:08–13:12 UTC, Auth connection failures, pg_cron startup timeouts, an Iran exchange sync statement timeout, and PostgreSQL client/SSL connection resets occurred in the same incident window.
- At 14:21:20–14:21:35 UTC, pg_cron launcher process 4625 logged startup timeouts for 11 jobs over roughly 15 seconds.
- A targeted search in the 14:20–14:24 PostgreSQL log window did not find explicit messages containing too many connections / remaining connection slots, out of memory, fork failure, or terminating connection. Absence of these strings in the filtered sample does not rule out transient connection, CPU, memory, or platform-level pressure.
- A live `pg_stat_activity` snapshot at a different time showed 11 connections (6 active, 4 idle, 1 null-state), so sustained max_connections exhaustion is not established.
- A separate query against `cron.job_run_details` repeatedly timed out at the management SQL layer, leaving per-job runtimes and successful/failed run history unavailable.

## Revised diagnosis

The strongest current evidence points to a PostgreSQL local connection/startup responsiveness incident affecting more than one client class: Supabase Auth, pg_cron, and incoming local SSL connections. A long-running/statement-timed-out Iran exchange sync function was also present in the 13:08–13:12 window and may have contributed to load, but it is not proven to be the cause. The later 14:21–14:22 burst shows recurrence.

Still unproven:
1. whether the local TCP listener was unavailable, overloaded, or slow;
2. whether transient resource pressure or connection limits caused the delay;
3. whether the long-running exchange-sync query materially contributed to the incident;
4. whether a managed platform/database host event caused the symptoms;
5. whether staggered scheduling alone would materially reduce the problem.

## Safe next steps

1. Obtain Supabase Database Observability metrics for 13:08–13:12 and 14:20–14:24 UTC: CPU, memory/swap, IOPS/latency, and active connections.
2. Capture a short `pg_stat_activity` snapshot and `cron.job_run_details` immediately during a recurrence, without changing schedules.
3. Ask Supabase Support to inspect host-level PostgreSQL listener/connectivity, connection resets, and resource-pressure events for these UTC intervals, especially if metrics are missing.
4. Only if run history shows job overlap or connection spikes correlated with startup failures, prepare a staged/staggered schedule candidate in an isolated PostgreSQL 17 test. Preserve jobs 8, 9, and 12 at their existing one-minute cadence.
5. Do not switch `cron.use_background_workers` on in Production as a speculative fix. That changes the execution model, consumes background-worker capacity, and would require a carefully validated capacity/restart plan.

## Safety

No production settings, cron schedules, functions, migrations, grants, order engines, wallets, or financial data were changed.
