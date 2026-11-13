-- Dynamic CoinGecko pricing for curated assets and safe admin-controlled
-- activation/deactivation of demo trading pairs.

CREATE TABLE IF NOT EXISTS private.market_pair_admin_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pair_symbol text NOT NULL,
  coingecko_id text NOT NULL,
  action text NOT NULL CHECK (action IN ('enabled','disabled')),
  admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reason text,
  validation_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.market_pair_admin_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.market_pair_admin_audit FROM PUBLIC, anon, authenticated, service_role;
CREATE INDEX IF NOT EXISTS market_pair_admin_audit_pair_created_idx
  ON private.market_pair_admin_audit(pair_symbol, created_at DESC);

CREATE OR REPLACE FUNCTION public.refresh_market_prices()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $function$
DECLARE
  r record;
  v_map record;
  v_request_id bigint;
  v_ids text;
  v_price_text text;
  v_price numeric;
BEGIN
  IF NOT pg_catalog.pg_try_advisory_xact_lock(742019, 13) THEN
    RETURN;
  END IF;

  -- Process completed CoinGecko requests against the current enabled-pair
  -- set plus admin-curated listings. This replaces the former hard-coded
  -- twelve-asset mapping.
  FOR r IN
    SELECT q.request_id, h.status_code, h.content, h.timed_out, h.error_msg
    FROM private.market_price_sync_requests AS q
    JOIN net._http_response AS h ON h.id = q.request_id
  LOOP
    IF r.status_code = 200
       AND COALESCE(r.timed_out, false) = false
       AND r.content IS NOT NULL THEN
      BEGIN
        FOR v_map IN
          SELECT dp.pair_symbol AS symbol, dp.base_coingecko_id AS coingecko_id
          FROM public.demo_trading_pairs AS dp
          WHERE dp.is_enabled IS TRUE
          UNION
          SELECT pg_catalog.upper(ca.symbol) || 'USDT', ca.coingecko_id
          FROM public.admin_market_listings AS l
          JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
          WHERE ca.is_active IS TRUE
        LOOP
          v_price_text := r.content::jsonb -> v_map.coingecko_id ->> 'usd';
          IF v_price_text ~ '^[0-9]+(\\.[0-9]+)?$' THEN
            v_price := v_price_text::numeric;
            IF v_price > 0 THEN
              INSERT INTO public.market_prices(symbol, price, source, updated_at)
              VALUES (v_map.symbol, v_price, 'CoinGecko', now())
              ON CONFLICT (symbol) DO UPDATE
              SET price = EXCLUDED.price,
                  source = EXCLUDED.source,
                  updated_at = EXCLUDED.updated_at;
            END IF;
          END IF;
        END LOOP;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'CoinGecko market-price response processing failed: %', SQLERRM;
      END;
    ELSE
      RAISE WARNING 'CoinGecko market-price request failed. Status: %, Error: %',
        r.status_code, r.error_msg;
    END IF;

    DELETE FROM private.market_price_sync_requests
    WHERE request_id = r.request_id;
  END LOOP;

  DELETE FROM private.market_price_sync_requests
  WHERE queued_at < now() - interval '10 minutes';

  SELECT pg_catalog.string_agg(x.coingecko_id, ',' ORDER BY x.coingecko_id)
  INTO v_ids
  FROM (
    SELECT DISTINCT ids.coingecko_id
    FROM (
      SELECT dp.base_coingecko_id AS coingecko_id
      FROM public.demo_trading_pairs AS dp
      WHERE dp.is_enabled IS TRUE
      UNION
      SELECT ca.coingecko_id
      FROM public.admin_market_listings AS l
      JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
      WHERE ca.is_active IS TRUE
    ) AS ids
    WHERE ids.coingecko_id ~ '^[a-z0-9-]+$'
  ) AS x;

  IF v_ids IS NULL OR v_ids = '' THEN
    RETURN;
  END IF;

  v_request_id := net.http_get(
    url := 'https://api.coingecko.com/api/v3/simple/price?ids='
      || v_ids || '&vs_currencies=usd',
    timeout_milliseconds := 20000
  );

  INSERT INTO private.market_price_sync_requests(request_id)
  VALUES (v_request_id)
  ON CONFLICT DO NOTHING;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_review_market_listings()
RETURNS TABLE (
  coingecko_id text,
  symbol text,
  name text,
  pair_symbol text,
  current_price_usd numeric,
  total_volume_usd numeric,
  market_cap_rank integer,
  metadata_updated_at timestamptz,
  market_price numeric,
  price_source text,
  price_updated_at timestamptz,
  price_age_seconds numeric,
  is_enabled boolean,
  is_eligible boolean,
  eligibility_reason text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH rows AS (
    SELECT
      ca.coingecko_id,
      ca.symbol,
      ca.name,
      pg_catalog.upper(ca.symbol) || 'USDT' AS pair_symbol,
      ca.current_price_usd,
      ca.total_volume_usd,
      ca.market_cap_rank,
      ca.last_updated AS metadata_updated_at,
      mp.price AS market_price,
      mp.source AS price_source,
      mp.updated_at AS price_updated_at,
      CASE WHEN mp.updated_at IS NULL THEN NULL
           ELSE pg_catalog.extract(epoch FROM (pg_catalog.now() - mp.updated_at)) END AS price_age_seconds,
      COALESCE(dp.is_enabled, false) AS is_enabled,
      ca.is_active,
      EXISTS (
        SELECT 1 FROM public.demo_trading_pairs AS other
        WHERE other.pair_symbol = pg_catalog.upper(ca.symbol) || 'USDT'
          AND other.base_coingecko_id <> ca.coingecko_id
      ) AS symbol_conflict
    FROM public.admin_market_listings AS l
    JOIN public.crypto_assets AS ca ON ca.coingecko_id = l.coingecko_id
    LEFT JOIN public.market_prices AS mp
      ON mp.symbol = pg_catalog.upper(ca.symbol) || 'USDT'
    LEFT JOIN public.demo_trading_pairs AS dp
      ON dp.base_coingecko_id = ca.coingecko_id
  )
  SELECT
    x.coingecko_id, x.symbol, x.name, x.pair_symbol,
    x.current_price_usd, x.total_volume_usd, x.market_cap_rank,
    x.metadata_updated_at, x.market_price, x.price_source,
    x.price_updated_at, x.price_age_seconds, x.is_enabled,
    (
      x.is_active IS TRUE
      AND x.symbol ~ '^[A-Za-z0-9]{2,15}$'
      AND pg_catalog.upper(x.symbol) <> 'USDT'
      AND x.current_price_usd > 0
      AND x.metadata_updated_at >= pg_catalog.now() - interval '24 hours'
      AND x.total_volume_usd >= 1000000
      AND (x.market_cap_rank IS NULL OR x.market_cap_rank <= 2000)
      AND x.market_price > 0
      AND x.price_source = 'CoinGecko'
      AND x.price_updated_at >= pg_catalog.now() - interval '2 minutes'
      AND NOT x.symbol_conflict
    ) AS is_eligible,
    CASE
      WHEN x.is_active IS NOT TRUE THEN 'ارز در کاتالوگ غیرفعال است'
      WHEN x.symbol !~ '^[A-Za-z0-9]{2,15}$' OR pg_catalog.upper(x.symbol) = 'USDT' THEN 'نماد ارز برای جفت USDT معتبر نیست'
      WHEN x.current_price_usd IS NULL OR x.current_price_usd <= 0 THEN 'قیمت مرجع معتبر نیست'
      WHEN x.metadata_updated_at IS NULL OR x.metadata_updated_at < pg_catalog.now() - interval '24 hours' THEN 'اطلاعات بازار ارز قدیمی‌تر از ۲۴ ساعت است'
      WHEN x.total_volume_usd IS NULL OR x.total_volume_usd < 1000000 THEN 'حجم معاملات ۲۴ساعته کمتر از یک میلیون دلار است'
      WHEN x.market_cap_rank IS NOT NULL AND x.market_cap_rank > 2000 THEN 'رتبه ارزش بازار خارج از محدوده مجاز است'
      WHEN x.market_price IS NULL OR x.market_price <= 0 THEN 'هنوز قیمت زنده برای این جفت‌ارز دریافت نشده است'
      WHEN x.price_source <> 'CoinGecko' THEN 'منبع قیمت تأیید نشده است'
      WHEN x.price_updated_at IS NULL OR x.price_updated_at < pg_catalog.now() - interval '2 minutes' THEN 'قیمت زنده قدیمی‌تر از دو دقیقه است'
      WHEN x.symbol_conflict THEN 'نماد این جفت‌ارز با دارایی دیگری تداخل دارد'
      ELSE 'آماده فعال‌سازی'
    END AS eligibility_reason
  FROM rows AS x
  WHERE auth.uid() IS NOT NULL
    AND private.is_super_admin()
  ORDER BY x.metadata_updated_at DESC NULLS LAST, x.symbol;
$function$;

CREATE OR REPLACE FUNCTION public.admin_enable_market_pair(p_coingecko_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_disable_market_pair(
  p_coingecko_id text,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin uuid := auth.uid();
  v_pair public.demo_trading_pairs%ROWTYPE;
  v_cancelled integer := 0;
  v_released integer := 0;
BEGIN
  IF v_admin IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode = '42501';
  END IF;
  IF p_coingecko_id IS NULL THEN
    RAISE EXCEPTION 'CoinGecko asset id is required';
  END IF;

  SELECT * INTO v_pair
  FROM public.demo_trading_pairs
  WHERE base_coingecko_id = pg_catalog.btrim(p_coingecko_id)
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trading pair not found';
  END IF;

  -- Cancel all outstanding conditional exits first so the worker cannot
  -- execute a trigger after the pair has been disabled.
  UPDATE public.conditional_orders AS co
  SET status = 'cancelled',
      last_error = 'Pair disabled by administrator',
      updated_at = now()
  FROM public.orders AS o
  WHERE co.order_id = o.id
    AND o.symbol = v_pair.pair_symbol
    AND o.order_type = 'conditional'
    AND o.status IN ('pending','partially_filled')
    AND co.status = 'pending';

  UPDATE public.order_reservations AS r
  SET released_amount = r.reserved_amount - r.consumed_amount,
      status = CASE WHEN r.consumed_amount >= r.reserved_amount THEN 'consumed' ELSE 'released' END,
      updated_at = now()
  FROM public.orders AS o
  WHERE r.order_id = o.id
    AND o.symbol = v_pair.pair_symbol
    AND o.order_type IN ('limit','conditional')
    AND o.status IN ('pending','partially_filled')
    AND r.status = 'reserved';

  GET DIAGNOSTICS v_released = ROW_COUNT;

  UPDATE public.orders
  SET status = 'cancelled',
      remaining_amount = amount - filled_amount
  WHERE symbol = v_pair.pair_symbol
    AND order_type IN ('limit','conditional')
    AND status IN ('pending','partially_filled');

  GET DIAGNOSTICS v_cancelled = ROW_COUNT;

  UPDATE public.demo_trading_pairs
  SET is_enabled = false, updated_at = now()
  WHERE pair_symbol = v_pair.pair_symbol;

  INSERT INTO private.market_pair_admin_audit(
    pair_symbol, coingecko_id, action, admin_user_id, reason, validation_snapshot
  )
  VALUES(v_pair.pair_symbol, v_pair.base_coingecko_id, 'disabled', v_admin,
         pg_catalog.left(pg_catalog.coalesce(p_reason, 'Disabled by super administrator'), 500),
         pg_catalog.jsonb_build_object(
           'cancelled_open_orders', v_cancelled,
           'reservations_released', v_released
         ));

  RETURN pg_catalog.jsonb_build_object(
    'success', true,
    'pair_symbol', v_pair.pair_symbol,
    'status', 'disabled',
    'cancelled_open_orders', v_cancelled,
    'reservations_released', v_released
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_review_market_listings() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_enable_market_pair(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_disable_market_pair(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_review_market_listings() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_enable_market_pair(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_disable_market_pair(text, text) TO authenticated;
