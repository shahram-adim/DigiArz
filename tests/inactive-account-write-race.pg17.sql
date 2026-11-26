\set ON_ERROR_STOP on
CREATE SCHEMA IF NOT EXISTS private;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY,
  is_active boolean NOT NULL DEFAULT true,
  deactivated_at timestamptz
);
CREATE TABLE public.orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.profiles(id,is_active)
VALUES ('11111111-1111-4111-8111-111111111111',true);

-- Exact PL/pgSQL body captured from the read-only Production manifest.
CREATE OR REPLACE FUNCTION private.guard_active_account_writes()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
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
$function$;

CREATE TRIGGER guard_active_account_orders
BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION private.guard_active_account_writes();
