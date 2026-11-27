-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: get_my_order_reservations(uuid[])
-- PostgreSQL md5(pg_get_functiondef(...)): 97189e59fbf37bb5f85b215dadd13dfd
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.get_my_order_reservations(p_order_ids uuid[])
 RETURNS TABLE(order_id uuid, asset text, reserved_amount numeric, consumed_amount numeric, released_amount numeric, status text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    r.order_id,
    r.asset,
    r.reserved_amount,
    r.consumed_amount,
    r.released_amount,
    r.status
  from public.order_reservations as r
  where (select auth.uid()) is not null
    and r.user_id = (select auth.uid())
    and p_order_ids is not null
    and cardinality(p_order_ids) between 1 and 100
    and r.order_id = any(p_order_ids);
$function$
;
