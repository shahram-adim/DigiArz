-- DigiArz: read-only Production compatibility preflight
-- Date: 2026-11-17
-- Purpose: collect the live facts required before reviewing or applying
-- process_iran_exchange_asset_sync() race-fix candidate.
-- SAFETY: SELECT-only. This script does not alter schema, data, functions,
-- grants, cron jobs, or migration history. Run against the intended Supabase
-- project and retain the complete output with the deployment review.

-- 1) Confirm the pg_net response table and the exact id column type.
select
  n.nspname as schema_name,
  c.relname as table_name,
  a.attname as column_name,
  pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,
  a.attnotnull as is_not_null,
  a.attidentity as identity_kind
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
join pg_catalog.pg_attribute a on a.attrelid = c.oid
where n.nspname = 'net'
  and c.relname = '_http_response'
  and a.attname = 'id'
  and a.attnum > 0
  and not a.attisdropped;

-- 2) Confirm pg_net extension installation and schema.
select
  e.extname,
  e.extversion,
  n.nspname as extension_schema
from pg_catalog.pg_extension e
join pg_catalog.pg_namespace n on n.oid = e.extnamespace
where e.extname = 'pg_net';

-- 3) Capture the live worker signature, owner, security mode, search_path,
--    ACL, and effective execute privileges for the relevant API roles.
select
  p.oid::regprocedure as function_identity,
  pg_catalog.pg_get_userbyid(p.proowner) as owner_name,
  p.prosecdef as security_definer,
  p.proconfig as function_settings,
  p.proacl as raw_acl,
  pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
  pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute,
  pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE') as service_role_can_execute,
  pg_catalog.pg_get_functiondef(p.oid) as live_function_definition
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'process_iran_exchange_asset_sync'
  and p.pronargs = 0;

-- 4) Report the runtime type inferred for an aggregate of response IDs.
--    This is deliberately derived from the live column, not assumed from CI.
select
  pg_catalog.pg_typeof(pg_catalog.array_agg(r.id)) as response_id_array_type,
  count(*) as visible_response_rows,
  min(r.id) as minimum_response_id,
  max(r.id) as maximum_response_id
from net._http_response r;

-- 5) Estimate the largest currently visible pending-request/response join
--    and its ID-array type. This is an observational snapshot only.
select
  pg_catalog.pg_typeof(pg_catalog.array_agg(r.id)) as matched_response_id_array_type,
  count(*) as matched_pending_response_count,
  count(distinct q.id) as matched_request_count,
  min(r.created) as oldest_matched_response_created,
  max(r.created) as newest_matched_response_created
from public.exchange_asset_sync_requests q
join net._http_response r on r.id = q.request_id
where q.processed_at is null;

-- 6) Inspect the live cron entries that invoke the request and processing
--    functions, if pg_cron is installed and its catalog is accessible.
select
  jobid,
  jobname,
  schedule,
  active,
  command
from cron.job
where command ilike '%request_iran_exchange_asset_sync%'
   or command ilike '%process_iran_exchange_asset_sync%'
order by jobid;
