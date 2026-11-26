create or replace function public.get_my_order_reservations(p_order_ids uuid[])
returns table (
  order_id uuid,
  asset text,
  reserved_amount numeric,
  consumed_amount numeric,
  released_amount numeric,
  status text
)
language sql
stable
security definer
set search_path = ''
as $function$
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
$function$;

revoke all on function public.get_my_order_reservations(uuid[]) from public;
revoke all on function public.get_my_order_reservations(uuid[]) from anon;
grant execute on function public.get_my_order_reservations(uuid[]) to authenticated;

comment on function public.get_my_order_reservations(uuid[])
is 'Read-only, authenticated owner-scoped reservation lookup for at most 100 supplied order IDs. Returns only reservation display fields.';
