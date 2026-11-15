alter table public.exchange_asset_sync_requests
  drop constraint exchange_asset_sync_requests_exchange_check;
alter table public.exchange_asset_sync_requests
  add constraint exchange_asset_sync_requests_exchange_check
  check (exchange = any (array['nobitex','wallex','tabdeal','ompfinex','exir','abantether','kifpool']));

create or replace function public.request_iran_exchange_asset_sync()
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
declare n integer := 0; rid bigint;
begin
  select net.http_get('https://apiv2.nobitex.ir/v2/options') into rid;
  insert into public.exchange_asset_sync_requests(request_id,exchange) values(rid,'nobitex') on conflict do nothing; n:=n+1;
  select net.http_get('https://api.wallex.ir/v1/markets') into rid;
  insert into public.exchange_asset_sync_requests(request_id,exchange) values(rid,'wallex') on conflict do nothing; n:=n+1;
  select net.http_get('https://api-web.tabdeal.org/r/plots/currencies/dynamic-info/') into rid;
  insert into public.exchange_asset_sync_requests(request_id,exchange) values(rid,'tabdeal') on conflict do nothing; n:=n+1;
  select net.http_get('https://api.ompfinex.com/v2/market') into rid;
  insert into public.exchange_asset_sync_requests(request_id,exchange) values(rid,'ompfinex') on conflict do nothing; n:=n+1;
  select net.http_get('https://api.exir.io/v2/ticker/all') into rid;
  insert into public.exchange_asset_sync_requests(request_id,exchange) values(rid,'exir') on conflict do nothing; n:=n+1;
  select net.http_get('https://api.abantether.ir/api/v2/manager/coins') into rid;
  insert into public.exchange_asset_sync_requests(request_id,exchange) values(rid,'abantether') on conflict do nothing; n:=n+1;
  select net.http_post(
    'https://kifpool.me/api/graphql',
    '{"operationName":"headerCoins","variables":{"search":"","offset":0,"limit":2000},"extensions":{"persistedQuery":{"version":1,"sha256Hash":"bb149e99c1d2da2ca162085286128da78a9bd3936198e47e28028e20961f6f3c"}}}'::jsonb,
    '{}'::jsonb,
    '{"Content-Type":"application/json","Accept":"application/json","Origin":"https://kifpool.me","Referer":"https://kifpool.me/markets"}'::jsonb,
    15000
  ) into rid;
  insert into public.exchange_asset_sync_requests(request_id,exchange) values(rid,'kifpool') on conflict do nothing; n:=n+1;
  return n;
end;
$function$;

create or replace function public.process_iran_exchange_asset_sync()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare v_ingested integer:=0; v_processed integer:=0;
begin
 with resp as (
  select q.exchange,q.request_id,r.content::jsonb j,r.status_code,r.error_msg
  from public.exchange_asset_sync_requests q join net._http_response r on r.id=q.request_id
  where q.processed_at is null and r.status_code=200 and r.content is not null
 ), rows as (
  select 'nobitex'::text exchange,upper(x->>'coin') market_symbol,upper(x->>'coin') base_symbol,null::text quote_symbol,x->>'name' asset_name,'https://apiv2.nobitex.ir/v2/options'::text source_url,x source_payload,true is_active
  from resp r cross join lateral jsonb_array_elements(r.j->'coins') x where r.exchange='nobitex' and x->>'coin' is not null
  union all
  select 'wallex',e.key,upper(e.value->>'baseAsset'),upper(e.value->>'quoteAsset'),coalesce(e.value->>'enBaseAsset',e.value->>'faBaseAsset'),'https://api.wallex.ir/v1/markets',e.value,true
  from resp r cross join lateral jsonb_each(r.j->'result'->'symbols') e where r.exchange='wallex'
  union all
  select 'tabdeal',upper(e.key||'_'||q.key),upper(e.key),upper(q.key),e.key,'https://api-web.tabdeal.org/r/plots/currencies/dynamic-info/',q.value,true
  from resp r cross join lateral jsonb_each(r.j->'currencies') e cross join lateral jsonb_each(e.value) q where r.exchange='tabdeal'
  union all
  select 'ompfinex',upper(x->>'symbol'),upper(x->>'baseCurrencyId'),upper(x->>'quoteCurrencyId'),null::text,'https://api.ompfinex.com/v2/market',x,coalesce(x->>'status'='LISTED',true)
  from resp r cross join lateral jsonb_array_elements(r.j->'data') x where r.exchange='ompfinex' and x->>'baseCurrencyId' is not null
  union all
  select 'exir',upper(e.key),upper(split_part(e.key,'-',1)),upper(split_part(e.key,'-',2)),split_part(e.key,'-',1),'https://api.exir.io/v2/ticker/all',e.value,true
  from resp r cross join lateral jsonb_each(r.j) e where r.exchange='exir' and position('-' in e.key)>0
  union all
  select 'abantether',upper(x->>'symbol'),upper(x->>'symbol'),null::text,x->>'name','https://api.abantether.ir/api/v2/manager/coins',x,coalesce((x->>'is_active')::boolean,true)
  from resp r cross join lateral jsonb_array_elements(r.j->'data') x where r.exchange='abantether' and x->>'coin_type'='COIN'
  union all
  select 'kifpool',upper(x->>'symbol'),upper(x->>'symbol'),'IRT'::text,coalesce(x->>'name',x->>'title'),'https://kifpool.me/api/graphql',x,true
  from resp r cross join lateral jsonb_array_elements(r.j->'data'->'coinList'->'coins') x
  where r.exchange='kifpool' and r.j->'errors' is null
    and coalesce(x->>'symbol','') ~ '^[A-Za-z][A-Za-z0-9]{0,19}$'
 )
 insert into public.exchange_asset_observations(exchange,market_symbol,base_symbol,quote_symbol,asset_name,source_url,source_payload,is_active,last_seen_at)
 select exchange,market_symbol,base_symbol,quote_symbol,asset_name,source_url,source_payload,is_active,now()
 from rows where market_symbol is not null and base_symbol is not null
 on conflict(exchange,market_symbol) do update set base_symbol=excluded.base_symbol,quote_symbol=excluded.quote_symbol,
 asset_name=coalesce(excluded.asset_name,public.exchange_asset_observations.asset_name),source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now();
 get diagnostics v_ingested=row_count;
 update public.exchange_asset_sync_requests q set processed_at=now(),http_status=r.status_code,error_message=left(r.error_msg,500)
 from net._http_response r where r.id=q.request_id and q.processed_at is null;
 get diagnostics v_processed=row_count;
 with candidates as (
  select o.id,ca.coingecko_id,count(ca.coingecko_id) over(partition by o.id) candidate_count
  from public.exchange_asset_observations o join public.crypto_assets ca on upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true
  where o.is_active is true and o.asset_name is not null and (
   regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
   or (length(regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g'))>=5 and length(regexp_replace(lower(ca.name),'[^a-z0-9]','','g'))>=5
    and (regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(ca.name),'[^a-z0-9]','','g')||'%'
     or regexp_replace(lower(ca.name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')||'%'))
  )
 ), chosen as (select id,min(coingecko_id) filter(where candidate_count=1) coingecko_id,max(candidate_count) candidate_count from candidates group by id)
 update public.exchange_asset_observations o set coingecko_id=c.coingecko_id,
 match_status=case when c.candidate_count=1 then 'matched' when c.candidate_count>1 then 'ambiguous' else 'pending' end
 from chosen c where c.id=o.id and (o.coingecko_id is distinct from c.coingecko_id or o.match_status is distinct from case when c.candidate_count=1 then 'matched' when c.candidate_count>1 then 'ambiguous' else 'pending' end);
 update public.exchange_asset_observations o set coingecko_id=null,match_status='unmatched'
 where o.is_active is true and o.asset_name is not null and o.match_status is distinct from 'unmatched'
 and not exists(select 1 from public.crypto_assets ca where upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true);
 return jsonb_build_object('processed_requests',v_processed,'upserted_rows',v_ingested);
end;
$function$;