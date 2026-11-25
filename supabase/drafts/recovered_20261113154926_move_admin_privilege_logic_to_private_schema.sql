-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261113154926
-- Name: move_admin_privilege_logic_to_private_schema
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.

begin;
grant usage on schema private to authenticated;

create or replace function private.is_current_user_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and private.is_super_admin();
$$;
revoke all on function private.is_current_user_super_admin() from public, anon;
grant execute on function private.is_current_user_super_admin() to authenticated;

create or replace function private.admin_list_users()
returns table (
  user_id uuid,
  email text,
  is_active boolean,
  created_at timestamptz,
  balance_usdt numeric,
  balance_irr numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not private.is_super_admin() then
    raise exception 'Super administrator access required' using errcode = '42501';
  end if;
  return query
    select p.id, p.email, p.is_active, p.created_at,
           coalesce(w.balance_usdt, 0), coalesce(w.balance_irr, 0)
    from public.profiles p
    left join public.wallets w on w.user_id = p.id
    order by p.created_at desc nulls last, p.id;
end;
$$;
revoke all on function private.admin_list_users() from public, anon;
grant execute on function private.admin_list_users() to authenticated;

create or replace function private.admin_adjust_wallet(
  p_user_id uuid,
  p_currency text,
  p_direction text,
  p_amount numeric,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := auth.uid();
  v_currency text := upper(btrim(p_currency));
  v_direction text := lower(btrim(p_direction));
  v_reason text := btrim(p_reason);
  v_before numeric;
  v_after numeric;
  v_reserved numeric := 0;
  v_delta numeric;
  v_storage_delta numeric;
begin
  if v_admin is null or not private.is_super_admin() then
    raise exception 'Super administrator access required' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (select 1 from public.profiles p where p.id = p_user_id) then
    raise exception 'Target account not found';
  end if;
  if v_currency not in ('USDT','TOMAN') then
    raise exception 'Currency must be USDT or TOMAN';
  end if;
  if v_direction not in ('credit','debit') then
    raise exception 'Direction must be credit or debit';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 1000000000000 then
    raise exception 'Invalid adjustment amount';
  end if;
  if v_reason is null or char_length(v_reason) < 5 or char_length(v_reason) > 500 then
    raise exception 'Reason must contain 5 to 500 characters';
  end if;

  insert into public.wallets(user_id) values (p_user_id)
  on conflict (user_id) do nothing;
  select case when v_currency = 'USDT' then w.balance_usdt else w.balance_irr / 10 end
  into v_before from public.wallets w where w.user_id = p_user_id for update;

  v_delta := case when v_direction = 'credit' then p_amount else -p_amount end;
  v_storage_delta := case when v_currency = 'TOMAN' then v_delta * 10 else v_delta end;
  if v_currency = 'USDT' and v_direction = 'debit' then
    select coalesce(sum(greatest(r.reserved_amount-r.consumed_amount-r.released_amount,0)),0)
    into v_reserved from public.order_reservations r
    where r.user_id = p_user_id and r.asset = 'USDT' and r.status = 'reserved';
    if v_before - v_reserved < p_amount then
      raise exception 'Insufficient available USDT; funds reserved by open orders cannot be withdrawn';
    end if;
  elsif v_direction = 'debit' and v_before < p_amount then
    raise exception 'Insufficient wallet balance';
  end if;

  v_after := v_before + v_delta;
  if v_currency = 'USDT' then
    update public.wallets set balance_usdt = v_after where user_id = p_user_id;
  else
    update public.wallets set balance_irr = v_after * 10 where user_id = p_user_id;
  end if;
  insert into public.transactions(user_id,currency,amount,transaction_type,description)
  values (p_user_id,case when v_currency='TOMAN' then 'IRR' else 'USDT' end,v_storage_delta,'admin_adjustment','مدیریت اعتبار آزمایشی: ' || v_reason);
  insert into private.admin_wallet_adjustments(admin_user_id,target_user_id,currency,direction,amount,balance_before,balance_after,reason)
  values (v_admin,p_user_id,v_currency,v_direction,p_amount,v_before,v_after,v_reason);
  return jsonb_build_object('success',true,'user_id',p_user_id,'currency',v_currency,'direction',v_direction,'amount',p_amount,'balance_before',v_before,'balance_after',v_after);
end;
$$;
revoke all on function private.admin_adjust_wallet(uuid,text,text,numeric,text) from public, anon;
grant execute on function private.admin_adjust_wallet(uuid,text,text,numeric,text) to authenticated;

create or replace function public.admin_list_users()
returns table (user_id uuid,email text,is_active boolean,created_at timestamptz,balance_usdt numeric,balance_irr numeric)
language sql
stable
security invoker
set search_path = ''
as $$ select * from private.admin_list_users(); $$;
revoke all on function public.admin_list_users() from public, anon;
grant execute on function public.admin_list_users() to authenticated;

create or replace function public.admin_adjust_wallet(p_user_id uuid,p_currency text,p_direction text,p_amount numeric,p_reason text)
returns jsonb
language sql
security invoker
set search_path = ''
as $$ select private.admin_adjust_wallet(p_user_id,p_currency,p_direction,p_amount,p_reason); $$;
revoke all on function public.admin_adjust_wallet(uuid,text,text,numeric,text) from public, anon;
grant execute on function public.admin_adjust_wallet(uuid,text,text,numeric,text) to authenticated;

create or replace function public.is_current_user_super_admin()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$ select private.is_current_user_super_admin(); $$;
revoke all on function public.is_current_user_super_admin() from public, anon;
grant execute on function public.is_current_user_super_admin() to authenticated;
commit;