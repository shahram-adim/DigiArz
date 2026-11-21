# DigiArz — repeated Iran exchange sync timeout finding
**Observed:** 2026-11-17, UTC 14:35–14:45  
**Project:** `gfoaubfilhttnwjykaox` (region `us-west-2`)  
**Scope:** read-only log and repository inspection; no Production changes.

## New log evidence
A read-only query of the unified PostgreSQL logs returned:
- `public.process_iran_exchange_asset_sync()` canceled with SQLSTATE `57014` at **14:37:27.259 UTC**. The backend session began at 14:35:25 UTC.
- The same function canceled again with SQLSTATE `57014` at **14:44:24.928 UTC**. The backend session began at 14:42:17 UTC.
- The error context identifies the statement as the function's candidate-matching CTE and UPDATE of `public.exchange_asset_observations`.
- At **14:45:10 UTC**, pg_cron launcher emitted startup-timeout messages for jobs **2, 3, 4, 5, 8, 9, 11, 12, 17, and 18**.

## Repository correlation
The current `supabase/MIGRATION_RECONCILIATION.md` records the live Production schedule:
- Job 13: `*/10 * * * *` — `request_iran_exchange_asset_sync()`
- Job 14: `* * * * *` — `process_iran_exchange_asset_sync()`
- Job 17: `5-59/10 * * * *` — `private.request_market_price_overflow()`

The current repository definition of `process_iran_exchange_asset_sync()` (migration `20261116195814_deduplicate_iran_exchange_sync_rows.sql`) includes a broad candidate-matching pass over active observations and active crypto assets. It repeatedly normalizes names with `regexp_replace(lower(...))`, includes substring matching with leading-wildcard LIKE patterns, and updates matching rows. This is consistent with the SQL text captured in the timeout log.

## Interpretation and limits
This is now a concrete, high-priority workload to investigate: a one-minute scheduled worker repeatedly performs a broad matching/update pass and has been canceled by statement timeout at least twice in this window. It is plausible that the workload contributes to database pressure and degraded service responsiveness.

It is **not yet proven** to be the sole or primary cause of Auth HTTP 504 or pg_cron startup timeouts. A pg_cron `job startup timeout` is a connection/startup-phase failure; it does not prove that the SQL body of every affected job is slow. We still need Supabase CPU, memory, disk IOPS/latency, connection and restart metrics, plus job-run history and confirmation of the live function definition.

## Safety / next steps
1. Do not disable or reschedule job 14 yet; first assess whether its output is business-critical and quantify its workload.
2. Do not change jobs 8, 9, or 12, order execution, wallet logic, balances, or financial records.
3. Do not deploy or run migrations from this branch. Migration history has known drift; `supabase db push` remains prohibited pending reconciliation.
4. Review query plan and indexes only in a disposable PostgreSQL 17 environment using representative, non-production data. Consider reducing the matching scan to changed/new observations and precomputing normalized names only after correctness tests prove no asset mapping regressions.
5. Correlate the exact timeout intervals with Supabase Database Reports and request host-level investigation from Supabase Support.

This note is diagnostic documentation only. It changes no Production object, schedule, setting, grant, order, wallet, or financial data.
