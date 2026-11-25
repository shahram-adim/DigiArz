-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261115105721
-- Name: admin_exchange_asset_sync_monitoring
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.


create or replace function public.admin_exchange_asset_sync_report()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare result jsonb;
begin
  if not private.is_current_user_super_admin() then
    raise exception 'دسترسی مدیر ارشد لازم است' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'summary', jsonb_build_object(
      'observations', (select count(*) from public.exchange_asset_observations),
      'exchanges', (select count(distinct exchange) from public.exchange_asset_observations where is_active),
      'symbols', (select count(distinct base_symbol) from public.exchange_asset_observations where is_active),
      'matched', (select count(*) from public.exchange_asset_observations where is_active and match_status='matched'),
      'ambiguous', (select count(*) from public.exchange_asset_observations where is_active and match_status='ambiguous'),
      'pending', (select count(*) from public.exchange_asset_observations where is_active and match_status='pending'),
      'unmatched', (select count(*) from public.exchange_asset_observations where is_active and match_status='unmatched'),
      'listed', (select count(*) from public.admin_market_listings)
    ),
    'sources', (
      select coalesce(jsonb_agg(to_jsonb(s) order by s.exchange), '[]'::jsonb)
      from (
        select e.exchange,
          coalesce(o.active_markets,0) as active_markets,
          o.last_seen_at,
          r.last_requested_at,
          r.last_processed_at,
          r.http_status,
          r.error_message
        from (values ('nobitex'),('wallex'),('tabdeal'),('ompfinex'),('exir'),('abantether'),('bit24')) e(exchange)
        left join lateral (
          select count(*) filter(where is_active) as active_markets, max(last_seen_at) as last_seen_at
          from public.exchange_asset_observations x where x.exchange=e.exchange
        ) o on true
        left join lateral (
          select max(requested_at) as last_requested_at, max(processed_at) as last_processed_at,
            (array_agg(http_status order by requested_at desc))[1] as http_status,
            (array_agg(error_message order by requested_at desc))[1] as error_message
          from (
            select requested_at, processed_at, http_status, error_message
            from public.exchange_asset_sync_requests where exchange=e.exchange
            union all
            select requested_at, processed_at, http_status, error_message
            from public.bit24_exchange_sync_requests where e.exchange='bit24'
          ) z
        ) r on true
      ) s
    ),
    'issues', (
      select coalesce(jsonb_agg(to_jsonb(i) order by i.exchange, i.base_symbol), '[]'::jsonb)
      from (
        select exchange, base_symbol, asset_name, market_symbol, match_status, coingecko_id, last_seen_at
        from public.exchange_asset_observations
        where is_active and match_status in ('ambiguous','pending','unmatched')
        order by case match_status when 'ambiguous' then 1 when 'pending' then 2 else 3 end, last_seen_at desc
        limit 100
      ) i
    )
  ) into result;
  return result;
end;
$$;

create or replace function public.admin_request_exchange_asset_sync()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare n_main integer; n_bit24 integer;
begin
  if not private.is_current_user_super_admin() then
    raise exception 'دسترسی مدیر ارشد لازم است' using errcode = '42501';
  end if;
  n_main := public.request_iran_exchange_asset_sync();
  n_bit24 := public.request_bit24_exchange_sync();
  return jsonb_build_object('requested_main', n_main, 'requested_bit24', n_bit24, 'requested_at', now());
end;
$$;

revoke all on function public.admin_exchange_asset_sync_report() from public, anon;
revoke all on function public.admin_request_exchange_asset_sync() from public, anon;
grant execute on function public.admin_exchange_asset_sync_report() to authenticated;
grant execute on function public.admin_request_exchange_asset_sync() to authenticated;
