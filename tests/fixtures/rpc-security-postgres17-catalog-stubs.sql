-- TEST-ONLY metadata fixture for tests/rpc-security-catalog.sql.
-- Reproduces the 46 exact Production signatures and current API-role ACL
-- booleans from the reviewed 2026-11-25 catalog snapshot.
-- Five real bodies are installed by the bootstrap; this file adds one exact
-- migration-backed trigger body. The remaining 40 functions are inert NO-OP stubs
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

CREATE OR REPLACE FUNCTION private.auto_list_verified_exchange_asset()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION private.auto_list_verified_exchange_asset() FROM PUBLIC, anon, authenticated, service_role;

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
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.admin_add_market_listing(p_coingecko_id text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_add_market_listing(p_coingecko_id text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_add_market_listing(p_coingecko_id text) TO service_role;

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

CREATE OR REPLACE FUNCTION public.admin_search_market_assets(p_search text, p_limit integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.admin_search_market_assets(p_search text, p_limit integer) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_search_market_assets(p_search text, p_limit integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_search_market_assets(p_search text, p_limit integer) TO service_role;

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

CREATE OR REPLACE FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text) TO service_role;

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

CREATE OR REPLACE FUNCTION public.get_my_order_reservations(p_order_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $stub$
BEGIN
  RETURN;
END;
$stub$;

REVOKE ALL ON FUNCTION public.get_my_order_reservations(p_order_ids uuid[]) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_my_order_reservations(p_order_ids uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_order_reservations(p_order_ids uuid[]) TO service_role;

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

