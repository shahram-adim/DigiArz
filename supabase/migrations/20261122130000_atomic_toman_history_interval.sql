-- Atomically enforce the six-hour history interval per exchange/asset pair.
-- The transaction-scoped advisory lock serializes concurrent refreshes for the same pair.
create or replace function public.insert_market_toman_history_if_due(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  item record;
  inserted_count integer := 0;
begin
  if jsonb_typeof(p_rows) <> 'array' then
    raise exception 'p_rows must be a JSON array';
  end if;

  for item in
    select *
    from jsonb_to_recordset(p_rows) as x(
      exchange text,
      asset_symbol text,
      price_toman numeric,
      bid_toman numeric,
      ask_toman numeric,
      change_24h_pct numeric,
      volume_24h_toman numeric,
      asset_name_fa text,
      asset_name_en text,
      recorded_at timestamptz
    )
    order by exchange, asset_symbol
  loop
    if item.exchange is null or item.asset_symbol is null
       or item.price_toman is null or item.recorded_at is null then
      raise exception 'History row is missing a required field';
    end if;

    perform pg_advisory_xact_lock(
      hashtextextended(item.exchange || ':' || item.asset_symbol, 0)
    );

    if not exists (
      select 1
      from public.market_toman_price_history h
      where h.exchange = item.exchange
        and h.asset_symbol = item.asset_symbol
        and h.recorded_at >= item.recorded_at - interval '6 hours'
    ) then
      insert into public.market_toman_price_history (
        exchange, asset_symbol, price_toman, bid_toman, ask_toman,
        change_24h_pct, volume_24h_toman, asset_name_fa, asset_name_en, recorded_at
      ) values (
        item.exchange, item.asset_symbol, item.price_toman, item.bid_toman, item.ask_toman,
        item.change_24h_pct, item.volume_24h_toman, item.asset_name_fa, item.asset_name_en,
        item.recorded_at
      );
      inserted_count := inserted_count + 1;
    end if;
  end loop;

  return inserted_count;
end;
$$;

revoke all on function public.insert_market_toman_history_if_due(jsonb) from public, anon, authenticated;
grant execute on function public.insert_market_toman_history_if_due(jsonb) to service_role;
