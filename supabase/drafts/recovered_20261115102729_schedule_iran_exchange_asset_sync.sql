-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261115102729
-- Name: schedule_iran_exchange_asset_sync
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.


create table if not exists public.exchange_asset_sync_requests (
  request_id bigint primary key,
  exchange text not null check (exchange in ('nobitex','wallex','tabdeal','ompfinex','exir','abantether')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  http_status integer,
  error_message text
);
alter table public.exchange_asset_sync_requests enable row level security;
revoke all on public.exchange_asset_sync_requests from anon, authenticated;
grant all on public.exchange_asset_sync_requests to service_role;

create or replace function public.request_iran_exchange_asset_sync()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  n integer := 0;
  rid bigint;
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
  return n;
end;
$$;
revoke all on function public.request_iran_exchange_asset_sync() from public, anon, authenticated;

create or replace function public.process_iran_exchange_asset_sync()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ingested integer := 0;
  v_processed integer := 0;
begin
  with resp as (
    select q.exchange, q.request_id, r.content j
    from public.exchange_asset_sync_requests q
    join net._http_response r on r.id=q.request_id
    where q.processed_at is null and r.status_code=200 and r.content is not null
  ), rows as (
    select 'nobitex'::text exchange, upper(x->>'coin') market_symbol, upper(x->>'coin') base_symbol, null::text quote_symbol, x->>'name' asset_name, 'https://apiv2.nobitex.ir/v2/options'::text source_url, x source_payload, true is_active
    from resp r cross join lateral jsonb_array_elements(r.j->'coins') x where r.exchange='nobitex' and x->>'coin' is not null
    union all
    select 'wallex', e.key, upper(e.value->>'baseAsset'), upper(e.value->>'quoteAsset'), coalesce(e.value->>'enBaseAsset',e.value->>'faBaseAsset'), 'https://api.wallex.ir/v1/markets', e.value, true
    from resp r cross join lateral jsonb_each(r.j->'result'->'symbols') e where r.exchange='wallex'
    union all
    select 'tabdeal', upper(e.key||'_'||q.key), upper(e.key), upper(q.key), e.key, 'https://api-web.tabdeal.org/r/plots/currencies/dynamic-info/', q.value, true
    from resp r cross join lateral jsonb_each(r.j->'currencies') e cross join lateral jsonb_each(e.value) q where r.exchange='tabdeal'
    union all
    select 'ompfinex', upper(x->>'symbol'), upper(x->>'baseCurrencyId'), upper(x->>'quoteCurrencyId'), null::text, 'https://api.ompfinex.com/v2/market', x, coalesce(x->>'status'='LISTED',true)
    from resp r cross join lateral jsonb_array_elements(r.j->'data') x where r.exchange='ompfinex' and x->>'baseCurrencyId' is not null
    union all
    select 'exir', upper(e.key), upper(split_part(e.key,'-',1)), upper(split_part(e.key,'-',2)), split_part(e.key,'-',1), 'https://api.exir.io/v2/ticker/all', e.value, true
    from resp r cross join lateral jsonb_each(r.j) e where r.exchange='exir' and position('-' in e.key)>0
    union all
    select 'abantether', upper(x->>'symbol'), upper(x->>'symbol'), null::text, x->>'name', 'https://api.abantether.ir/api/v2/manager/coins', x, coalesce((x->>'is_active')::boolean,true)
    from resp r cross join lateral jsonb_array_elements(r.j->'data') x where r.exchange='abantether' and x->>'coin_type'='COIN'
  )
  insert into public.exchange_asset_observations(exchange,market_symbol,base_symbol,quote_symbol,asset_name,source_url,source_payload,is_active,last_seen_at)
  select exchange,market_symbol,base_symbol,quote_symbol,asset_name,source_url,source_payload,is_active,now()
  from rows where market_symbol is not null and base_symbol is not null
  on conflict(exchange,market_symbol) do update
    set base_symbol=excluded.base_symbol, quote_symbol=excluded.quote_symbol,
        asset_name=coalesce(excluded.asset_name,public.exchange_asset_observations.asset_name),
        source_payload=excluded.source_payload, is_active=excluded.is_active,last_seen_at=now();
  get diagnostics v_ingested = row_count;

  update public.exchange_asset_sync_requests q
  set processed_at=now(),
      http_status=r.status_code,
      error_message=left(r.error_msg,500)
  from net._http_response r
  where r.id=q.request_id and q.processed_at is null;
  get diagnostics v_processed = row_count;

  with candidates as (
    select o.id, ca.coingecko_id,
      count(ca.coingecko_id) over(partition by o.id) candidate_count
    from public.exchange_asset_observations o
    join public.crypto_assets ca on upper(ca.symbol)=upper(o.base_symbol) and ca.is_active is true
    where o.is_active is true and o.asset_name is not null
      and (
        regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g') = regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
        or (length(regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g'))>=5
          and length(regexp_replace(lower(ca.name),'[^a-z0-9]','','g'))>=5
          and (regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(ca.name),'[^a-z0-9]','','g')||'%'
            or regexp_replace(lower(ca.name),'[^a-z0-9]','','g') like '%'||regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')||'%'))
      )
  ), chosen as (
    select id,min(coingecko_id) filter(where candidate_count=1) coingecko_id,max(candidate_count) candidate_count
    from candidates group by id
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
$$;
revoke all on function public.process_iran_exchange_asset_sync() from public, anon, authenticated;

select cron.schedule('digiarz-iran-exchange-request','*/30 * * * *','select public.request_iran_exchange_asset_sync();');
select cron.schedule('digiarz-iran-exchange-process','*/2 * * * *','select public.process_iran_exchange_asset_sync();');
