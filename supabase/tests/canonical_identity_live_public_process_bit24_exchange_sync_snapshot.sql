-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: process_bit24_exchange_sync()
-- PostgreSQL md5(pg_get_functiondef(...)): 9f3e6d7e20586ea79b7c021eebc6ab62
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=false, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.process_bit24_exchange_sync()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now()
 WHERE public.exchange_asset_observations.base_symbol IS DISTINCT FROM EXCLUDED.base_symbol
    OR public.exchange_asset_observations.quote_symbol IS DISTINCT FROM EXCLUDED.quote_symbol
    OR public.exchange_asset_observations.asset_name IS DISTINCT FROM COALESCE(EXCLUDED.asset_name,public.exchange_asset_observations.asset_name)
    OR public.exchange_asset_observations.source_payload IS DISTINCT FROM EXCLUDED.source_payload
    OR public.exchange_asset_observations.is_active IS DISTINCT FROM EXCLUDED.is_active
    OR public.exchange_asset_observations.last_seen_at IS NULL
    OR public.exchange_asset_observations.last_seen_at < now() - interval '30 minutes';
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
 from chosen c where o.id=c.id
 and (
  o.coingecko_id IS DISTINCT FROM c.coingecko_id
  OR o.match_status IS DISTINCT FROM CASE
   WHEN c.candidate_count=1 THEN 'matched'
   WHEN c.candidate_count>1 THEN 'ambiguous'
   ELSE 'pending'
  END
 );
 update public.exchange_asset_observations o set coingecko_id=null,match_status='unmatched'
 where o.exchange='bit24' and o.is_active is true and o.asset_name is not null
 and not exists(select 1 from public.crypto_assets ca where upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true)
 and (o.coingecko_id is not null or o.match_status is distinct from 'unmatched');
 return jsonb_build_object('processed_requests',p,'upserted_rows',n);
end; $function$
;
