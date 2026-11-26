create or replace function public.process_iran_exchange_asset_sync()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_ingested integer := 0;
  v_processed integer := 0;
begin
  with resp as (
    select q.exchange, q.request_id, r.content::jsonb j, r.status_code, r.error_msg
    from public.exchange_asset_sync_requests q
    join net._http_response r on r.id = q.request_id
    where q.processed_at is null and r.status_code = 200 and r.content is not null
  ),
  rows as (
    select 'nobitex'::text exchange, upper(x->>'coin') market_symbol, upper(x->>'coin') base_symbol, null::text quote_symbol, x->>'name' asset_name, 'https://apiv2.nobitex.ir/v2/options'::text source_url, x source_payload, true is_active
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
    where r.exchange='kifpool' and r.j->'errors' is null and coalesce(x->>'symbol','') ~ '^[A-Za-z][A-Za-z0-9]{0,19}$'
  )
  insert into public.exchange_asset_observations(exchange,market_symbol,base_symbol,quote_symbol,asset_name,source_url,source_payload,is_active,last_seen_at)
  select exchange,market_symbol,base_symbol,quote_symbol,asset_name,source_url,source_payload,is_active,now()
  from rows where market_symbol is not null and base_symbol is not null
  on conflict(exchange,market_symbol) do update
    set base_symbol=excluded.base_symbol,quote_symbol=excluded.quote_symbol,
        asset_name=coalesce(excluded.asset_name,public.exchange_asset_observations.asset_name),
        source_payload=excluded.source_payload,is_active=excluded.is_active,last_seen_at=now();
  get diagnostics v_ingested=row_count;

  update public.exchange_asset_sync_requests q
  set processed_at=now(),http_status=r.status_code,error_message=left(r.error_msg,500)
  from net._http_response r where r.id=q.request_id and q.processed_at is null;
  get diagnostics v_processed=row_count;

  with kifpool_exact as (
    select o.id,ca.coingecko_id
    from public.exchange_asset_observations o
    join public.crypto_assets ca
      on ca.coingecko_id=o.source_payload->>'nameId'
     and ca.is_active is true
     and regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
    where o.exchange='kifpool' and o.is_active is true and o.asset_name is not null
      and nullif(o.source_payload->>'nameId','') is not null
  ),
  ordinary_candidates as (
    select o.id,ca.coingecko_id,count(ca.coingecko_id) over(partition by o.id) candidate_count
    from public.exchange_asset_observations o
    join public.crypto_assets ca on upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true
    where o.is_active is true and o.asset_name is not null
      and (o.exchange<>'kifpool' or not exists(select 1 from kifpool_exact k where k.id=o.id))
      and (
        regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
        or (length(regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g'))>=5
          and length(regexp_replace(lower(ca.name),'[^a-z0-9]','','g'))>=5
          and (regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(ca.name),'[^a-z0-9]','','g')||'%'
            or regexp_replace(lower(ca.name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')||'%'))
      )
  ),
  all_candidates as (
    select id,coingecko_id,1::bigint candidate_count from kifpool_exact
    union all
    select id,coingecko_id,candidate_count from ordinary_candidates
  ),
  chosen as (
    select id,min(coingecko_id) filter(where candidate_count=1) coingecko_id,max(candidate_count) candidate_count
    from all_candidates group by id
  )
  update public.exchange_asset_observations o
  set coingecko_id=c.coingecko_id,
      match_status=case when c.candidate_count=1 then 'matched' when c.candidate_count>1 then 'ambiguous' else 'pending' end
  from chosen c where o.id=c.id;

  update public.exchange_asset_observations o
  set coingecko_id=null,match_status='unmatched'
  where o.is_active is true and o.asset_name is not null
    and not exists(select 1 from public.crypto_assets ca where upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true);

  return jsonb_build_object('processed_requests',v_processed,'upserted_rows',v_ingested);
end;
$function$;
