-- DigiArz: read-only Auth / PostgreSQL / pg_cron pressure diagnostics
-- Draft only. Run against the intended project during or immediately after an
-- Auth 504 / cron startup-timeout window. SELECT statements only.
-- No settings, jobs, functions, grants, schemas, or data are modified.

-- 1) Relevant live capacity and pg_cron configuration.
select name, setting, unit, source
from pg_catalog.pg_settings
where name in (
  'max_connections',
  'max_worker_processes',
  'max_parallel_workers',
  'cron.max_running_jobs',
  'cron.use_background_workers',
  'cron.launch_active_jobs',
  'cron.host',
  'statement_timeout'
)
order by name;

-- 2) Current connection usage by state and wait event.
select
  coalesce(state, '<null>') as state,
  coalesce(wait_event_type, '<none>') as wait_event_type,
  coalesce(wait_event, '<none>') as wait_event,
  count(*) as connections
from pg_catalog.pg_stat_activity
where datname = current_database()
group by state, wait_event_type, wait_event
order by connections desc;

-- 3) Current active statements, including age and application.
select
  pid,
  usename,
  application_name,
  state,
  wait_event_type,
  wait_event,
  clock_timestamp() - query_start as query_age,
  left(query, 500) as query
from pg_catalog.pg_stat_activity
where datname = current_database()
  and state = 'active'
  and pid <> pg_backend_pid()
order by query_start nulls last;

-- 4) Actual live schedule: identify synchronized every-minute jobs.
select jobid, jobname, schedule, active, command
from cron.job
order by schedule, jobid;

-- 5) Recent run volume, outcomes, and durations by job (last 2 hours).
select
  jobid,
  status,
  count(*) as run_count,
  max(start_time) as latest_start,
  round(avg(extract(epoch from (end_time - start_time)))::numeric, 2) as avg_runtime_seconds,
  round(max(extract(epoch from (end_time - start_time)))::numeric, 2) as max_runtime_seconds
from cron.job_run_details
where start_time >= clock_timestamp() - interval '2 hours'
group by jobid, status
order by jobid, status;

-- 6) Peak overlap among completed cron runs in the last 2 hours.
-- End events sort before start events at the same timestamp.
with run_events as (
  select start_time as event_time, 1 as delta
  from cron.job_run_details
  where start_time >= clock_timestamp() - interval '2 hours'
    and end_time is not null
  union all
  select end_time as event_time, -1 as delta
  from cron.job_run_details
  where start_time >= clock_timestamp() - interval '2 hours'
    and end_time is not null
),
concurrency as (
  select
    event_time,
    sum(delta) over (
      order by event_time, delta
      rows between unbounded preceding and current row
    ) as running_jobs
  from run_events
)
select max(running_jobs) as peak_overlapping_completed_jobs
from concurrency;

-- 7) Most recent failures/timeouts with their return messages.
select
  jobid,
  runid,
  status,
  start_time,
  end_time,
  left(coalesce(return_message, ''), 500) as return_message
from cron.job_run_details
where start_time >= clock_timestamp() - interval '2 hours'
  and status not in ('succeeded')
order by start_time desc
limit 100;
