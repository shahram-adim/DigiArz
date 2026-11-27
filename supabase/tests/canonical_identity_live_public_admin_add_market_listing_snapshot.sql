-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: admin_add_market_listing(text)
-- PostgreSQL md5(pg_get_functiondef(...)): 8b3d0c18e54b08f01c27bc24491e3448
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
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

  -- An existing pair for this same CoinGecko asset is valid and must not
  -- prevent adding the asset to the admin-curated list. Pair creation or
  -- reactivation remains the responsibility of admin_enable_market_pair().
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
$function$
;
