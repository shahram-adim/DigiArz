-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261115103227
-- Name: auto_list_verified_exchange_assets
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.


create or replace function private.auto_list_verified_exchange_asset()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
 if new.match_status='matched' and new.is_active is true and new.coingecko_id is not null then
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
end; $$;
revoke all on function private.auto_list_verified_exchange_asset() from public,anon,authenticated;
drop trigger if exists trg_auto_list_verified_exchange_asset on public.exchange_asset_observations;
create trigger trg_auto_list_verified_exchange_asset after insert or update of match_status,coingecko_id,is_active
on public.exchange_asset_observations for each row execute function private.auto_list_verified_exchange_asset();
insert into public.admin_market_listings(coingecko_id,added_by)
select distinct ca.coingecko_id,null::uuid from public.exchange_asset_observations o
join public.crypto_assets ca on ca.coingecko_id=o.coingecko_id
where o.match_status='matched' and o.is_active is true and ca.is_active is true
and ca.current_price_usd>0 and ca.last_updated>=now()-interval '24 hours'
and (select count(*) from public.crypto_assets c2 where c2.is_active is true and upper(c2.symbol)=upper(ca.symbol))=1
and not exists(select 1 from public.admin_market_listings l join public.crypto_assets c2 using(coingecko_id) where upper(c2.symbol)=upper(ca.symbol) and l.coingecko_id<>ca.coingecko_id)
and not exists(select 1 from public.demo_trading_pairs dp where dp.pair_symbol=upper(ca.symbol)||'USDT' and dp.base_coingecko_id<>ca.coingecko_id)
on conflict(coingecko_id) do nothing;
