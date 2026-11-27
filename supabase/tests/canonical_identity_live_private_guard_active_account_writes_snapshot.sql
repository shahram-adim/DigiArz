-- Read-only live Production trigger-function snapshot captured 2026-11-27.
-- Function: private.guard_active_account_writes()
-- PostgreSQL md5(pg_get_functiondef(...)): 29b8e23c1de8eb4762a8cf1a9c9343ce
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path="".
-- Attached BEFORE INSERT to public.orders, public.trades and public.transactions.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION private.guard_active_account_writes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_active boolean;
begin
  select p.is_active into v_active
  from public.profiles p
  where p.id = new.user_id
  for share;

  if coalesce(v_active, false) is not true then
    raise exception 'Account is inactive; reactivate the account before trading';
  end if;

  return new;
end;
$function$
;