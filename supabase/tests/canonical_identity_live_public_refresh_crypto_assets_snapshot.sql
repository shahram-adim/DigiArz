-- Read-only live Production source snapshot captured 2026-11-27.
-- Function: refresh_crypto_assets()
-- PostgreSQL md5(pg_get_functiondef(...)): f14765ffd1166380f58e391b34163259
-- Verified metadata: owner=postgres; SECURITY DEFINER=true; config=search_path=""; EXECUTE anon=false, authenticated=false, service_role=true.
-- Source was read from pg_catalog only; no business/user rows were queried.
-- TEST FIXTURE ONLY. Never apply this file to Production or treat it as a migration.
CREATE OR REPLACE FUNCTION public.refresh_crypto_assets()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    r RECORD;
    v_page INTEGER;
    v_request_id BIGINT;
    v_payload JSONB;
    v_usd_irt NUMERIC;
    v_array_count INTEGER;
    v_pending BOOLEAN := FALSE;
    v_retry_page INTEGER := NULL;
    v_next_page INTEGER;
    v_scan_complete BOOLEAN;
    v_last_sync TIMESTAMPTZ;
BEGIN
    PERFORM pg_catalog.pg_advisory_xact_lock(20261108, 500);

    SELECT price_toman
    INTO v_usd_irt
    FROM public.market_fx_rates
    WHERE symbol = 'USD_IRT'
      AND is_stale = FALSE
      AND updated_at >= NOW() - INTERVAL '30 minutes'
    LIMIT 1;

    FOR r IN
        SELECT
            q.request_id,
            q.page_number,
            h.status_code,
            h.content,
            h.timed_out,
            h.error_msg
        FROM private.crypto_assets_sync_requests q
        LEFT JOIN net._http_response h
            ON h.id = q.request_id
        ORDER BY q.page_number
    LOOP
        IF r.status_code IS NULL THEN
            v_pending := TRUE;
            CONTINUE;
        END IF;

        IF r.status_code = 200
           AND COALESCE(r.timed_out, FALSE) = FALSE
           AND r.content IS NOT NULL THEN

            BEGIN
                v_payload := r.content::JSONB;

                IF pg_catalog.jsonb_typeof(v_payload) <> 'array' THEN
                    RAISE EXCEPTION 'Invalid CoinGecko response';
                END IF;

                v_array_count :=
                    pg_catalog.jsonb_array_length(v_payload);

                INSERT INTO public.crypto_assets (
                    coingecko_id,
                    symbol,
                    name,
                    image_url,
                    market_cap_rank,
                    current_price_usd,
                    price_toman,
                    price_change_percentage_24h,
                    market_cap_usd,
                    total_volume_usd,
                    last_updated,
                    is_active,
                    updated_at
                )
                SELECT
                    x.item ->> 'id',
                    UPPER(x.item ->> 'symbol'),
                    x.item ->> 'name',
                    x.item ->> 'image',

                    CASE
                        WHEN x.item ->> 'market_cap_rank'
                             ~ '^[0-9]+$'
                        THEN (x.item ->> 'market_cap_rank')::INTEGER
                    END,

                    CASE
                        WHEN x.item ->> 'current_price'
                             ~ '^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
                        THEN (x.item ->> 'current_price')::NUMERIC
                    END,

                    CASE
                        WHEN v_usd_irt IS NOT NULL
                         AND x.item ->> 'current_price'
                             ~ '^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
                        THEN ROUND(
                            (x.item ->> 'current_price')::NUMERIC
                            * v_usd_irt,
                            2
                        )
                    END,

                    CASE
                        WHEN x.item ->> 'price_change_percentage_24h'
                             ~ '^-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
                        THEN (x.item ->> 'price_change_percentage_24h')::NUMERIC
                    END,

                    CASE
                        WHEN x.item ->> 'market_cap'
                             ~ '^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
                        THEN (x.item ->> 'market_cap')::NUMERIC
                    END,

                    CASE
                        WHEN x.item ->> 'total_volume'
                             ~ '^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
                        THEN (x.item ->> 'total_volume')::NUMERIC
                    END,

                    NULLIF(x.item ->> 'last_updated', '')::TIMESTAMPTZ,
                    TRUE,
                    NOW()

                FROM pg_catalog.jsonb_array_elements(v_payload)
                    AS x(item)

                WHERE NULLIF(x.item ->> 'id', '') IS NOT NULL
                  AND NULLIF(x.item ->> 'symbol', '') IS NOT NULL
                  AND NULLIF(x.item ->> 'name', '') IS NOT NULL
                  AND x.item ->> 'current_price'
                      ~ '^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
                  AND (x.item ->> 'current_price')::NUMERIC > 0

                ON CONFLICT (coingecko_id)
                DO UPDATE SET
                    symbol = EXCLUDED.symbol,
                    name = EXCLUDED.name,
                    image_url = EXCLUDED.image_url,
                    market_cap_rank = EXCLUDED.market_cap_rank,
                    current_price_usd = EXCLUDED.current_price_usd,
                    price_toman = COALESCE(
                        EXCLUDED.price_toman,
                        public.crypto_assets.price_toman
                    ),
                    price_change_percentage_24h =
                        EXCLUDED.price_change_percentage_24h,
                    market_cap_usd = EXCLUDED.market_cap_usd,
                    total_volume_usd = EXCLUDED.total_volume_usd,
                    last_updated = EXCLUDED.last_updated,
                    is_active = TRUE,
                    updated_at = NOW();

                IF v_array_count < 250 THEN
                    UPDATE private.crypto_assets_sync_state
                    SET
                        scan_complete = TRUE,
                        last_full_sync_at = NOW(),
                        updated_at = NOW()
                    WHERE singleton = TRUE;
                ELSE
                    UPDATE private.crypto_assets_sync_state
                    SET
                        next_page = GREATEST(
                            next_page,
                            r.page_number + 1
                        ),
                        scan_complete = FALSE,
                        updated_at = NOW()
                    WHERE singleton = TRUE;
                END IF;

            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING
                    'Page % processing failed: %',
                    r.page_number,
                    SQLERRM;

                v_retry_page := LEAST(
                    COALESCE(v_retry_page, r.page_number),
                    r.page_number
                );
            END;

        ELSE
            RAISE WARNING
                'Page % HTTP error: %, %',
                r.page_number,
                r.status_code,
                r.error_msg;

            v_retry_page := LEAST(
                COALESCE(v_retry_page, r.page_number),
                r.page_number
            );
        END IF;

        DELETE FROM private.crypto_assets_sync_requests
        WHERE request_id = r.request_id;
    END LOOP;

    IF v_retry_page IS NOT NULL THEN
        UPDATE private.crypto_assets_sync_state
        SET
            next_page = v_retry_page,
            scan_complete = FALSE,
            updated_at = NOW()
        WHERE singleton = TRUE;
    END IF;

    IF NOT v_pending
       AND NOT EXISTS (
           SELECT 1
           FROM private.crypto_assets_sync_requests
       ) THEN

        SELECT
            next_page,
            scan_complete,
            last_full_sync_at
        INTO
            v_next_page,
            v_scan_complete,
            v_last_sync
        FROM private.crypto_assets_sync_state
        WHERE singleton = TRUE;

        IF v_scan_complete
           AND (
               v_last_sync IS NULL
               OR v_last_sync < NOW() - INTERVAL '1 day'
           ) THEN

            UPDATE private.crypto_assets_sync_state
            SET
                next_page = 1,
                scan_complete = FALSE,
                updated_at = NOW()
            WHERE singleton = TRUE;

            v_next_page := 1;
            v_scan_complete := FALSE;
        END IF;

        IF NOT v_scan_complete THEN
            v_request_id := net.http_get(
                url :=
                    'https://api.coingecko.com/api/v3/coins/markets'
                    || '?vs_currency=usd'
                    || '&order=market_cap_desc'
                    || '&per_page=250'
                    || '&page=' || v_next_page::TEXT
                    || '&sparkline=false'
                    || '&price_change_percentage=24h',
                timeout_milliseconds := 20000
            );

            INSERT INTO private.crypto_assets_sync_requests (
                request_id,
                page_number
            )
            VALUES (
                v_request_id,
                v_next_page
            )
            ON CONFLICT (request_id) DO NOTHING;
        END IF;
    END IF;
END;
$function$
;
