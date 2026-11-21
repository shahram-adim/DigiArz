# DigiArz Auth / pg_cron connection-pressure investigation

Date: 2026-11-17  
Project: `gfoaubfilhttnwjykaox` (PostgreSQL 17.11, region us-west-2)

## Observed evidence

- Auth password-token requests to `/auth/v1/token` repeatedly fail while looking up the user. Recent Auth events include `context deadline exceeded`, `error finding user: context canceled`, and one explicit failed connection attempt to `localhost:5432` as `supabase_auth_admin`.
- PostgreSQL logs show bursts of `pg_cron launcher` messages `job startup timeout`. In the sampled minutes, 32 startup timeouts were recorded in one minute alongside 37 start/timeout-related events; similar bursts recur across several minutes.
- The live project reports `max_connections=60`, `max_worker_processes=6`, `cron.max_running_jobs=32`, `cron.use_background_workers=off`, `cron.host=localhost`, and `cron.launch_active_jobs=on`.
- A connection snapshot taken between failures showed 6 active, 4 idle, and 1 null-state connection (11 total). This does **not** prove sustained max-connection exhaustion.
- Ten active jobs are scheduled every minute: jobs 2, 3, 4, 5, 8, 9, 11, 12, 14, and 18. Job 16 runs every 2 minutes; jobs 13 and 15 run every 10 and 30 minutes; job 17 runs every 10 minutes with a 5-minute offset.
- Supabase's current Cron guide recommends no more than 8 concurrent jobs for best performance. This is a recommendation, not proof that the 8-job threshold is a hard limit or that it caused the incident.

## Working diagnosis (not yet proven)

The strongest shared failure domain is PostgreSQL's local connection/startup path: Auth cannot reliably establish its local DB connection, while pg_cron repeatedly fails to start jobs. The evidence is consistent with transient database-side connection/startup pressure or a managed Postgres availability issue. It is not yet enough to distinguish:
1. brief database process/listener unavailability or restart;
2. connection/worker startup pressure caused by synchronized Cron activity;
3. CPU, memory, or I/O saturation making local connection setup exceed timeouts;
4. a platform-side issue independent of application SQL.

A snapshot of only 11 connections means we must not claim that `max_connections=60` was exhausted. The 6-worker setting and `cron.max_running_jobs=32` also do not, by themselves, establish the root cause.

## Safe next measurements

Run `2026-11-17_auth_cron_connection_pressure_diagnostics.sql` during an incident and compare:
- active/idle/waiting connections and active statement ages;
- exact cron schedules;
- `cron.job_run_details` outcomes and runtimes per job;
- peak overlap among completed cron runs;
- current worker and cron settings.

Correlate these results with Auth and PostgreSQL logs for the same UTC minute. Use Supabase Database Reports (CPU, memory, IOPS, and connection charts) for the same interval if available.

## Candidate mitigation to test only in an isolated branch

If run history confirms overlapping non-critical refresh/sync jobs are consuming the available execution capacity, prepare a draft-only schedule change that reduces or offsets non-critical jobs while preserving the one-minute cadence of the order engines:
- `digiarz-limit-orders` (job 8)
- `digiarz-conditional-orders` (job 9)
- `digiarz-stop-limit-orders` (job 12)

Do not disable, slow, or alter those order-processing jobs. Do not alter wallet, balances, order data, grants, functions, or production settings. Before proposing any schedule change, verify freshness requirements for market prices, FX rates, asset listings, exchange sync, and auto-activation.

## Acceptance criteria for a future fix

- Reproduce the schedule/concurrency issue in disposable PostgreSQL 17 with a deterministic test fixture.
- Demonstrate that the candidate schedule keeps required order engines at their existing cadence and reduces measured peak overlap.
- Run the repository's full CI suite and review the complete diff.
- Keep the SQL as a draft until explicit production approval and a separate migration-history reconciliation. Do not run `supabase db push` while the known migration drift remains.
- After a controlled production rollout, verify Auth token requests complete normally and cron startup timeouts disappear or materially decline.

## Safety status

This branch contains read-only diagnostics and this investigation note only. No Production SQL, settings, cron jobs, migrations, functions, grants, order engines, wallet records, or financial data have been changed.
