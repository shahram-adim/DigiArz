-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: private.auto_list_verified_exchange_asset()
-- PostgreSQL md5(pg_get_functiondef(...)): 49880c0892cad6081acb6ce071090a5d
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=false, service_role=false.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION private.auto_list_verified_exchange_asset()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if new.match_status='matched'
    and new.is_active is true
    and new.coingecko_id is not null
    and (
      tg_op='INSERT'
      or old.match_status is distinct from new.match_status
      or old.coingecko_id is distinct from new.coingecko_id
      or old.is_active is distinct from new.is_active
    )
 then
  insert into public.admin_market_listings(coingecko_id,added_by)
  select ca.coingecko_id,null::uuid from public.crypto_assets ca
  where ca.coingecko_id=new.coingecko_id and ca.is_active is true
    and ca.current_price_usd>0 and ca.last_updated>=now()-interval '24 hours'
    and (select count(*) from public.crypto_assets c2 where c2.is_active is true and upper(c2.symbol)=upper(ca.symbol))=1
    and not exists(select 1 from public.admin_market_listings l join public.crypto_assets c2 using(coingecko_id) where upper(c2.symbol)=upper(ca.symbol) and l.coingecko_id<>ca.coingecko_id)
    and not exists(select 1 from public.demo_trading_pairs dp where dp.pair_symbol=upper(ca.symbol)||'USDT' and dp.base_coingecko_id<>ca.coingecko_id)
  on conflict(coingecko_id) do nothing;
 end if;
 return new;
end;
$function$
;
