-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261115103507
-- Name: schedule_bit24_exchange_asset_sync
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.


create table if not exists public.bit24_exchange_sync_requests(
 request_id bigint primary key,
 requested_at timestamptz not null default now(),
 processed_at timestamptz,
 http_status integer,
 error_message text
);
alter table public.bit24_exchange_sync_requests enable row level security;
revoke all on public.bit24_exchange_sync_requests from anon,authenticated;
grant all on public.bit24_exchange_sync_requests to service_role;

create or replace function public.request_bit24_exchange_sync()
returns integer language plpgsql security definer set search_path=''
as $$
declare p integer; rid bigint; n integer:=0;
begin
 for p in 1..4 loop
  select net.http_get('https://pro.bit24.cash/api/v3/markets?page='||p||'&per_page=100') into rid;
  insert into public.bit24_exchange_sync_requests(request_id) values(rid) on conflict do nothing;
  n:=n+1;
 end loop;
 return n;
end; $$;
revoke all on function public.request_bit24_exchange_sync() from public,anon,authenticated;

create or replace function public.process_bit24_exchange_sync()
returns jsonb language plpgsql security definer set search_path=''
as $$
declare n integer:=0; p integer:=0;
begin
 with resp as (
  select q.request_id,r.content::jsonb j from public.bit24_exchange_sync_requests q
  join net._http_response r on r.id=q.request_id
  where q.processed_at is null and r.status_code=200 and r.content is not null
 ), rows as (
  select upper(replace(x->>'market_name','/','_')) market_symbol,
   upper(x->'base_coin'->>'symbol') base_symbol,
   upper(x->'quote_coin'->>'symbol') quote_symbol,
   x->'base_coin'->>'name' asset_name,x
  from resp r cross join lateral jsonb_array_elements(r.j->'data'->'results') x
  where x->'base_coin'->>'symbol' is not null and x->>'market_name' is not null
 )
 insert into public.exchange_asset_observations(exchange,market_symbol,base_symbol,quote_symbol,asset_name,source_url,source_payload,is_active,last_seen_at)
 select 'bit24',market_symbol,base_symbol,quote_symbol,asset_name,'https://pro.bit24.cash/api/v3/markets',x,true,now()
 from rows
 on conflict(exchange,market_symbol) do update set base_symbol=excluded.base_symbol,quote_symbol=excluded.quote_symbol,
 asset_name=coalesce(excluded.asset_name,public.exchange_asset_observations.asset_name),
 source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now();
 get diagnostics n=row_count;
 update public.bit24_exchange_sync_requests q set processed_at=now(),http_status=r.status_code,error_message=left(r.error_msg,500)
 from net._http_response r where r.id=q.request_id and q.processed_at is null;
 get diagnostics p=row_count;
 with candidates as (
  select o.id,ca.coingecko_id,count(ca.coingecko_id) over(partition by o.id) candidate_count
  from public.exchange_asset_observations o join public.crypto_assets ca on upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true
  where o.exchange='bit24' and o.is_active is true and o.asset_name is not null and (
   regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
   or (length(regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g'))>=5 and length(regexp_replace(lower(ca.name),'[^a-z0-9]','','g'))>=5
   and (regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(ca.name),'[^a-z0-9]','','g')||'%'
   or regexp_replace(lower(ca.name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')||'%'))
  )
 ), chosen as (select id,min(coingecko_id) filter(where candidate_count=1) coingecko_id,max(candidate_count) candidate_count from candidates group by id)
 update public.exchange_asset_observations o set coingecko_id=c.coingecko_id,
 match_status=case when c.candidate_count=1 then 'matched' when c.candidate_count>1 then 'ambiguous' else 'pending' end
 from chosen c where o.id=c.id;
 update public.exchange_asset_observations o set coingecko_id=null,match_status='unmatched'
 where o.exchange='bit24' and o.is_active is true and o.asset_name is not null
 and not exists(select 1 from public.crypto_assets ca where upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true);
 return jsonb_build_object('processed_requests',p,'upserted_rows',n);
end; $$;
revoke all on function public.process_bit24_exchange_sync() from public,anon,authenticated;
select cron.schedule('digiarz-bit24-request','*/30 * * * *','select public.request_bit24_exchange_sync();');
select cron.schedule('digiarz-bit24-process','*/2 * * * *','select public.process_bit24_exchange_sync();');
