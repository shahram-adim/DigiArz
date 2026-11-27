-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: current_account_is_active()
-- PostgreSQL md5(pg_get_functiondef(...)): d932cd1d0da21bb96bdc0a381f7dcbc3
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.current_account_is_active()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce((
    select p.is_active
    from public.profiles p
    where p.id = auth.uid()
  ), false);
$function$
;
