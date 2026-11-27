-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: admin_enable_market_pair(text)
-- PostgreSQL md5(pg_get_functiondef(...)): 848f7c1ebe114c558c1ce73e76dd13bd
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=true, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.admin_enable_market_pair(p_coingecko_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_admin uuid := auth.uid();
  v_asset public.crypto_assets%ROWTYPE;
  v_pair_symbol text;
  v_price numeric;
  v_price_source text;
  v_price_updated_at timestamptz;
  v_validation jsonb;
  v_rows integer;
BEGIN
  IF v_admin IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  IF p_coingecko_id IS NULL OR pg_catalog.length(pg_catalog.btrim(p_coingecko_id)) NOT BETWEEN 1 AND 128 THEN
    RAISE EXCEPTION 'Invalid CoinGecko asset id';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('digiarz-pair:' || p_coingecko_id));

  SELECT ca.* INTO v_asset
  FROM public.crypto_assets AS ca
  JOIN public.admin_market_listings AS l ON l.coingecko_id = ca.coingecko_id
  WHERE ca.coingecko_id = pg_catalog.btrim(p_coingecko_id)
  FOR SHARE OF ca;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Asset must first be added to the admin-curated market list';
  END IF;
  IF v_asset.is_active IS NOT TRUE
     OR v_asset.current_price_usd IS NULL OR v_asset.current_price_usd <= 0
     OR v_asset.last_updated IS NULL OR v_asset.last_updated < now() - interval '24 hours'
     OR v_asset.total_volume_usd IS NULL OR v_asset.total_volume_usd < 1000000
     OR (v_asset.market_cap_rank IS NOT NULL AND v_asset.market_cap_rank > 2000) THEN
    RAISE EXCEPTION 'Asset does not meet the current market-data and liquidity requirements';
  END IF;

  IF v_asset.symbol !~ '^[A-Za-z0-9]{2,15}$'
     OR pg_catalog.upper(v_asset.symbol) = 'USDT' THEN
    RAISE EXCEPTION 'Asset symbol is not valid for a USDT trading pair';
  END IF;
  v_pair_symbol := pg_catalog.upper(v_asset.symbol) || 'USDT';

  IF EXISTS (
    SELECT 1 FROM public.demo_trading_pairs AS dp
    WHERE dp.pair_symbol = v_pair_symbol
      AND dp.base_coingecko_id <> v_asset.coingecko_id
  ) THEN
    RAISE EXCEPTION 'Trading-pair symbol conflicts with another asset';
  END IF;

  SELECT mp.price, mp.source, mp.updated_at
  INTO v_price, v_price_source, v_price_updated_at
  FROM public.market_prices AS mp
  WHERE mp.symbol = v_pair_symbol
  FOR SHARE;

  IF NOT FOUND OR v_price IS NULL OR v_price <= 0
     OR v_price_source <> 'CoinGecko'
     OR v_price_updated_at < now() - interval '2 minutes' THEN
    RAISE EXCEPTION 'A fresh CoinGecko price is required before enabling this pair';
  END IF;

  v_validation := pg_catalog.jsonb_build_object(
    'coingecko_id', v_asset.coingecko_id,
    'symbol', v_asset.symbol,
    'pair_symbol', v_pair_symbol,
    'price_usd', v_price,
    'price_source', v_price_source,
    'price_updated_at', v_price_updated_at,
    'metadata_updated_at', v_asset.last_updated,
    'volume_24h_usd', v_asset.total_volume_usd,
    'market_cap_rank', v_asset.market_cap_rank,
    'minimum_volume_24h_usd', 1000000,
    'maximum_metadata_age_hours', 24,
    'maximum_price_age_minutes', 2
  );

  INSERT INTO public.demo_trading_pairs(
    pair_symbol, base_coingecko_id, quote_asset, is_enabled, created_at, updated_at
  )
  VALUES(v_pair_symbol, v_asset.coingecko_id, 'USDT', true, now(), now())
  ON CONFLICT (pair_symbol) DO UPDATE
    SET is_enabled = true, updated_at = now()
    WHERE public.demo_trading_pairs.base_coingecko_id = EXCLUDED.base_coingecko_id;

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'Trading pair could not be enabled because of a concurrent symbol conflict';
  END IF;

  INSERT INTO private.market_pair_admin_audit(
    pair_symbol, coingecko_id, action, admin_user_id, reason, validation_snapshot
  )
  VALUES(v_pair_symbol, v_asset.coingecko_id, 'enabled', v_admin,
         'Admin-approved activation after server-side eligibility checks', v_validation);

  RETURN pg_catalog.jsonb_build_object(
    'success', true,
    'pair_symbol', v_pair_symbol,
    'coingecko_id', v_asset.coingecko_id,
    'price_usd', v_price,
    'status', 'enabled',
    'validation', v_validation
  );
END;
$function$
;
