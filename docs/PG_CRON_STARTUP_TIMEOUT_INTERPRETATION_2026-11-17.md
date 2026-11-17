# Interpretation of pg_cron "job startup timeout" in DigiArz

Date: 2026-11-17  
Branch: diagnostics/auth-cron-connection-pressure

## Important correction: the Auth and Cron samples are not from the same minute

The explicit Auth loopback connection error was logged at approximately 2026-11-17 13:10 UTC:
`failed to connect to host=localhost user=supabase_auth_admin database=postgres: dial error (dial tcp [::1]:5432: operation was canceled)`.

The sampled pg_cron launcher burst occurred later, around 2026-11-17 14:21–14:22 UTC. These are separate observed episodes, not a proven simultaneous incident. They share a local PostgreSQL connection path, but temporal causation has not been established.

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

At 14:21:20–14:21:35 UTC, pg_cron launcher process 4625 logged startup timeouts for jobs 2, 3, 4, 5, 8, 9, 11, 12, 14, and 18. Multiple unrelated job commands failed in the connection/startup phase over roughly 15 seconds.

A targeted search in the same four-minute PostgreSQL log window did not find explicit messages containing:
- too many connections / remaining connection slots;
- could not connect to server;
- out of memory;
- fork failure;
- terminating connection.

Absence of those strings in this filtered log sample does not rule out transient connection, CPU, memory, or platform-level pressure.

A live `pg_stat_activity` snapshot at a different time showed 11 connections (6 active, 4 idle, 1 null-state), so sustained max_connections exhaustion is not established. A separate query against `cron.job_run_details` repeatedly timed out at the management SQL layer, leaving per-job runtimes and success/failure history unavailable.

## Revised diagnosis

The most precise current finding is: pg_cron repeatedly fails to establish scheduled-job startup connections through its configured local connection path, and Supabase Auth has separately logged a canceled connection attempt to the same local PostgreSQL TCP endpoint. This makes local PostgreSQL connection/listener responsiveness a stronger shared investigation target than the SQL body of one market-sync function.

Still unproven:
1. whether the local TCP listener was unavailable, overloaded, or slow;
2. whether transient resource pressure or connection limits caused the delay;
3. whether a managed platform/database host event caused both classes of symptoms;
4. whether staggered scheduling alone would materially reduce the problem.

## Safe next steps

1. Obtain Supabase Database Observability metrics for the exact UTC intervals 13:08–13:12 and 14:20–14:24: CPU, memory/swap, IOPS/latency, and active connections.
2. Capture a short `pg_stat_activity` snapshot and `cron.job_run_details` immediately during a recurrence, without changing schedules.
3. Ask Supabase Support to inspect host-level PostgreSQL listener/connectivity and resource-pressure events for those UTC intervals if metrics are missing or the errors recur.
4. Only if run history shows job overlap or connection spikes correlated with startup failures, prepare a staged/staggered schedule candidate in an isolated PostgreSQL 17 test. Preserve jobs 8, 9, and 12 at their existing one-minute cadence.
5. Do not switch `cron.use_background_workers` on in Production as a speculative fix. That changes the execution model, consumes background-worker capacity, and would require a carefully validated capacity/restart plan.

## Safety

No production settings, cron schedules, functions, migrations, grants, order engines, wallets, or financial data were changed.
