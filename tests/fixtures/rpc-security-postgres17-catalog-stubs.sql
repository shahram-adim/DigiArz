-- TEST-ONLY metadata fixture for tests/rpc-security-catalog.sql.
-- Reproduces the 46 exact Production signatures and current API-role ACL
-- booleans from the reviewed 2026-11-25 catalog snapshot.
-- Five real bodies are installed by the bootstrap; this file adds two exact
-- migration-backed trigger bodies and three ledger/source-backed read-only RPCs.
-- The remaining 36 functions are inert NO-OP stubs (the exchange-discovery stub
-- is replaced by its applied migration in the following workflow step).
-- (RETURNS void). They MUST NOT be
-- used to claim function-body behavior or full Production schema parity.
-- This file runs only inside the disposable PostgreSQL 17 service container.

\set ON_ERROR_STOP on

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA private TO authenticated;

CREATE OR REPLACE FUNCTION private.admin_adjust_wallet(p_user_id uuid, p_currency text, p_direction text, p_amount numeric, p_reason text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION private.admin_adjust_wallet(p_user_id uuid, p_currency text, p_direction text, p_amount numeric, p_reason text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.admin_adjust_wallet(p_user_id uuid, p_currency text, p_direction text, p_amount numeric, p_reason text) TO authenticated;

CREATE OR REPLACE FUNCTION private.admin_list_users()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION private.admin_list_users() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.admin_list_users() TO authenticated;

CREATE OR REPLACE FUNCTION private.auto_activate_verified_exchange_pairs()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION private.auto_activate_verified_exchange_pairs() FROM PUBLIC, anon, authenticated, service_role;

-- Exact current Production body from applied migration 20261115134855.
-- The repository migration filename 20261115134600 is a timestamp mismatch;
-- this fixture body was checked against the applied statements and pg_get_functiondef.
CREATE OR REPLACE FUNCTION private.auto_list_verified_exchange_asset()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
$function$;

REVOKE ALL ON FUNCTION private.auto_list_verified_exchange_asset()
  FROM PUBLIC, anon, authenticated, service_role;

-- Exact current Production body, independently matched against
-- migration 20261113184000_prevent_curated_ticker_collisions.sql.
CREATE OR REPLACE FUNCTION private.enforce_unique_admin_market_listing_symbol()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_symbol text;
BEGIN
  SELECT ca.symbol INTO v_symbol
  FROM public.crypto_assets ca
  WHERE ca.coingecko_id = NEW.coingecko_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Curated asset does not exist';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.admin_market_listings l
    JOIN public.crypto_assets other ON other.coingecko_id = l.coingecko_id
    WHERE l.coingecko_id <> NEW.coingecko_id
      AND pg_catalog.upper(other.symbol) = pg_catalog.upper(v_symbol)
  ) THEN
    RAISE EXCEPTION 'Another curated asset already uses this ticker';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.demo_trading_pairs dp
    WHERE dp.pair_symbol = pg_catalog.upper(v_symbol) || 'USDT'
      AND dp.base_coingecko_id <> NEW.coingecko_id
  ) THEN
    RAISE EXCEPTION 'Ticker conflicts with an existing demo trading pair';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_unique_admin_market_listing_symbol()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.guard_active_account_writes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION private.guard_active_account_writes() FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION private.is_current_user_super_admin() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_current_user_super_admin() TO authenticated;

REVOKE ALL ON FUNCTION private.is_super_admin() FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.request_market_price_overflow()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION private.request_market_price_overflow() FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.admin_add_market_listing(p_coingecko_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_admin uuid := auth.uid();
  v_asset public.crypto_assets%ROWTYPE;
  v_pair_symbol text;
BEGIN
  IF v_admin IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;

  IF p_coingecko_id IS NULL OR length(btrim(p_coingecko_id)) NOT BETWEEN 1 AND 128 THEN
    RAISE EXCEPTION 'Invalid CoinGecko asset id';
  END IF;

  SELECT *
  INTO v_asset
  FROM public.crypto_assets
  WHERE coingecko_id = btrim(p_coingecko_id)
    AND is_active IS TRUE
    AND current_price_usd > 0
    AND last_updated >= now() - interval '24 hours';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Asset not found, inactive, or market data is stale';
  END IF;

  IF v_asset.symbol IS NULL OR v_asset.symbol !~ '^[A-Za-z0-9]{2,15}$'
     OR upper(v_asset.symbol) = 'USDT' THEN
    RAISE EXCEPTION 'Asset symbol is not valid for a USDT trading pair';
  END IF;

  v_pair_symbol := upper(v_asset.symbol) || 'USDT';

  IF EXISTS (
    SELECT 1
    FROM public.demo_trading_pairs
    WHERE pair_symbol = v_pair_symbol
      AND base_coingecko_id <> v_asset.coingecko_id
  ) THEN
    RAISE EXCEPTION 'Trading-pair symbol conflicts with another asset';
  END IF;

  -- Existing matching pair is valid; do not create a duplicate and do not
  -- block curated-list insertion. A conflicting asset symbol is still rejected.
  INSERT INTO public.admin_market_listings(coingecko_id, added_by)
  VALUES (v_asset.coingecko_id, v_admin)
  ON CONFLICT (coingecko_id) DO NOTHING;

  RETURN jsonb_build_object(
    'success', true,
    'coingecko_id', v_asset.coingecko_id,
    'symbol', v_asset.symbol,
    'name', v_asset.name,
    'pair_symbol', v_pair_symbol,
    'pair_already_exists', EXISTS (
      SELECT 1
      FROM public.demo_trading_pairs
      WHERE pair_symbol = v_pair_symbol
        AND base_coingecko_id = v_asset.coingecko_id
    )
  );
END;
$function$;

-- Match current effective Production ACL; service_role is preserved by the
-- postgres/public default function ACL after PUBLIC/anon are revoked.
REVOKE ALL ON FUNCTION public.admin_add_market_listing(text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_add_market_listing(text)
  TO authenticated, service_role;
CREATE OR REPLACE FUNCTION public.admin_disable_market_pair(p_coingecko_id text, p_reason text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.admin_disable_market_pair(p_coingecko_id text, p_reason text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_disable_market_pair(p_coingecko_id text, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_disable_market_pair(p_coingecko_id text, p_reason text) TO service_role;

CREATE OR REPLACE FUNCTION public.admin_enable_market_pair(p_coingecko_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.admin_enable_market_pair(p_coingecko_id text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_enable_market_pair(p_coingecko_id text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_enable_market_pair(p_coingecko_id text) TO service_role;

REVOKE ALL ON FUNCTION public.admin_exchange_asset_sync_report() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_exchange_asset_sync_report() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_exchange_asset_sync_report() TO service_role;

CREATE OR REPLACE FUNCTION public.admin_remove_market_listing(p_coingecko_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.admin_remove_market_listing(p_coingecko_id text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_remove_market_listing(p_coingecko_id text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_remove_market_listing(p_coingecko_id text) TO service_role;

CREATE OR REPLACE FUNCTION public.admin_request_exchange_asset_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.admin_request_exchange_asset_sync() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_request_exchange_asset_sync() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_request_exchange_asset_sync() TO service_role;

CREATE OR REPLACE FUNCTION public.admin_review_market_listings()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.admin_review_market_listings() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_review_market_listings() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_review_market_listings() TO service_role;

-- Exact current Production definition recovered from applied migration ledger
-- version 20261113173506 (name: admin_on_demand_crypto_asset_refresh) and
-- matched byte-for-byte in behavior to live pg_get_functiondef on 2026-11-25.
-- The repo's similarly named 20261113190000 file has a timestamp mismatch;
-- the applied ledger statements, not that filename, are the provenance.
CREATE OR REPLACE FUNCTION public.admin_search_market_assets(
  p_search text,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
  coingecko_id text,
  symbol text,
  name text,
  image_url text,
  market_cap_rank integer,
  current_price_usd numeric,
  last_updated timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_search text := pg_catalog.btrim(COALESCE(p_search, ''));
BEGIN
  IF auth.uid() IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  IF pg_catalog.length(v_search) < 2 THEN
    RAISE EXCEPTION 'Search query must contain at least two characters';
  END IF;

  RETURN QUERY
  SELECT ca.coingecko_id, ca.symbol, ca.name, ca.image_url,
         ca.market_cap_rank, ca.current_price_usd, ca.last_updated
  FROM public.crypto_assets AS ca
  WHERE ca.is_active IS TRUE
    AND (
      ca.symbol ILIKE '%' || v_search || '%'
      OR ca.name ILIKE '%' || v_search || '%'
      OR ca.coingecko_id ILIKE '%' || v_search || '%'
    )
  ORDER BY ca.market_cap_rank ASC NULLS LAST
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 50);
END;
$function$;

-- Reproduce the effective Production ACL, including service_role inherited
-- from postgres' public-schema function default privileges. Test-only fixture grant.
REVOKE ALL ON FUNCTION public.admin_search_market_assets(text, integer)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_search_market_assets(text, integer)
  TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.cancel_conditional_exit_order(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.cancel_conditional_exit_order(p_order_id uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_conditional_exit_order(p_order_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_conditional_exit_order(p_order_id uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.cancel_limit_order(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.cancel_limit_order(p_order_id uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_limit_order(p_order_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_limit_order(p_order_id uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.cancel_stop_limit_order(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.cancel_stop_limit_order(p_order_id uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_stop_limit_order(p_order_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_stop_limit_order(p_order_id uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.current_account_is_active()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.current_account_is_active() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.current_account_is_active() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_account_is_active() TO service_role;

CREATE OR REPLACE FUNCTION public.deactivate_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.deactivate_my_account() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.deactivate_my_account() TO authenticated;
GRANT EXECUTE ON FUNCTION public.deactivate_my_account() TO service_role;

CREATE OR REPLACE FUNCTION public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric) TO service_role;

-- Exact current Production body recovered from applied migration 20261113153808.
-- The full migration file is absent from this branch; the function source was
-- read from supabase_migrations.schema_migrations and matched to pg_get_functiondef.
CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_rate numeric;
BEGIN
    IF p_liquidity_type NOT IN ('maker', 'taker') THEN
        RAISE EXCEPTION 'Invalid liquidity type';
    END IF;

    SELECT CASE WHEN p_liquidity_type = 'maker'
                THEN f.maker_fee_rate ELSE f.taker_fee_rate END
      INTO v_rate
      FROM public.demo_trading_fees AS f
     WHERE f.quote_asset = upper(btrim(p_quote_asset))
       AND f.is_enabled IS TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trading fee is not configured for quote asset %', p_quote_asset;
    END IF;

    RETURN v_rate;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_demo_trading_fee_rate(text,text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_demo_trading_fee_rate(text,text) TO authenticated;
-- Test-only grant models the currently observed Production service_role EXECUTE bit.
GRANT EXECUTE ON FUNCTION public.get_demo_trading_fee_rate(text,text) TO service_role;

CREATE OR REPLACE FUNCTION public.get_exchange_discovered_market_assets()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.get_exchange_discovered_market_assets() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_exchange_discovered_market_assets() TO anon;
GRANT EXECUTE ON FUNCTION public.get_exchange_discovered_market_assets() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_exchange_discovered_market_assets() TO service_role;

-- Exact source migration 20261114143035; current Production definition matches.
CREATE OR REPLACE FUNCTION public.get_my_order_reservations(p_order_ids uuid[])
RETURNS TABLE (
  order_id uuid,
  asset text,
  reserved_amount numeric,
  consumed_amount numeric,
  released_amount numeric,
  status text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT
    r.order_id,
    r.asset,
    r.reserved_amount,
    r.consumed_amount,
    r.released_amount,
    r.status
  FROM public.order_reservations AS r
  WHERE (SELECT auth.uid()) IS NOT NULL
    AND r.user_id = (SELECT auth.uid())
    AND p_order_ids IS NOT NULL
    AND cardinality(p_order_ids) BETWEEN 1 AND 100
    AND r.order_id = ANY(p_order_ids);
$function$;

REVOKE ALL ON FUNCTION public.get_my_order_reservations(uuid[])
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_my_order_reservations(uuid[]) TO authenticated;
-- Test-only grant models the observed postgres/public default-ACL service_role bit.
GRANT EXECUTE ON FUNCTION public.get_my_order_reservations(uuid[]) TO service_role;
COMMENT ON FUNCTION public.get_my_order_reservations(uuid[])
IS 'Read-only, authenticated owner-scoped reservation lookup for at most 100 supplied order IDs. Returns only reservation display fields.';

CREATE OR REPLACE FUNCTION public.new_user_setup()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.new_user_setup() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.new_user_setup() TO service_role;

CREATE OR REPLACE FUNCTION public.place_conditional_exit_order(p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.place_conditional_exit_order(p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.place_conditional_exit_order(p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.place_conditional_exit_order(p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric) TO service_role;

CREATE OR REPLACE FUNCTION public.place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric) TO service_role;

CREATE OR REPLACE FUNCTION public.place_stop_limit_order(p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.place_stop_limit_order(p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.place_stop_limit_order(p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.place_stop_limit_order(p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric) TO service_role;

CREATE OR REPLACE FUNCTION public.process_bit24_exchange_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.process_bit24_exchange_sync() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.process_bit24_exchange_sync() TO service_role;

CREATE OR REPLACE FUNCTION public.process_conditional_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.process_conditional_orders() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.process_conditional_orders() TO service_role;

CREATE OR REPLACE FUNCTION public.process_iran_exchange_asset_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.process_iran_exchange_asset_sync() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.process_iran_exchange_asset_sync() TO service_role;

CREATE OR REPLACE FUNCTION public.process_limit_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.process_limit_orders() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.process_limit_orders() TO service_role;

CREATE OR REPLACE FUNCTION public.process_stop_limit_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.process_stop_limit_orders() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.process_stop_limit_orders() TO service_role;

CREATE OR REPLACE FUNCTION public.reactivate_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.reactivate_my_account() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.reactivate_my_account() TO authenticated;
GRANT EXECUTE ON FUNCTION public.reactivate_my_account() TO service_role;

CREATE OR REPLACE FUNCTION public.recover_stale_crypto_assets_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.recover_stale_crypto_assets_sync() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.recover_stale_crypto_assets_sync() TO service_role;

CREATE OR REPLACE FUNCTION public.refresh_crypto_assets()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.refresh_crypto_assets() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.refresh_crypto_assets() TO service_role;

CREATE OR REPLACE FUNCTION public.refresh_crypto_assets_toman()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.refresh_crypto_assets_toman() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.refresh_crypto_assets_toman() TO service_role;

CREATE OR REPLACE FUNCTION public.refresh_market_fx_rate()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.refresh_market_fx_rate() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.refresh_market_fx_rate() TO service_role;

CREATE OR REPLACE FUNCTION public.refresh_market_prices()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.refresh_market_prices() FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.request_bit24_exchange_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.request_bit24_exchange_sync() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.request_bit24_exchange_sync() TO service_role;

CREATE OR REPLACE FUNCTION public.request_iran_exchange_asset_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.request_iran_exchange_asset_sync() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.request_iran_exchange_asset_sync() TO service_role;

CREATE OR REPLACE FUNCTION public.request_market_price_refresh()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.request_market_price_refresh() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.request_market_price_refresh() TO authenticated;
GRANT EXECUTE ON FUNCTION public.request_market_price_refresh() TO service_role;



-- Exact Production trigger binding for the curated-list ticker guard.
DROP TRIGGER IF EXISTS admin_market_listing_unique_ticker
  ON public.admin_market_listings;
CREATE TRIGGER admin_market_listing_unique_ticker
BEFORE INSERT OR UPDATE OF coingecko_id
ON public.admin_market_listings
FOR EACH ROW
EXECUTE FUNCTION private.enforce_unique_admin_market_listing_symbol();
