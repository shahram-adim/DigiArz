-- End-to-end regression for the Bit24 sync migration in disposable CI PostgreSQL.
-- The fixture deliberately mirrors only the columns the function consumes.
CREATE SCHEMA IF NOT EXISTS net;

CREATE TABLE public.bit24_exchange_sync_requests (
  request_id bigint PRIMARY KEY,
  requested_at timestamptz NOT NULL,
  processed_at timestamptz,
  http_status integer,
  error_message text
);

CREATE TABLE net._http_response (
  id bigint PRIMARY KEY,
  status_code integer,
  content text,
  error_msg text
);

CREATE TABLE public.exchange_asset_observations (
  id bigserial PRIMARY KEY,
  exchange text NOT NULL,
  market_symbol text NOT NULL,
  base_symbol text,
  quote_symbol text,
  asset_name text,
  coingecko_id text,
  match_status text NOT NULL DEFAULT 'pending',
  source_url text NOT NULL,
  source_payload jsonb,
  is_active boolean NOT NULL,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL,
  CONSTRAINT exchange_asset_observations_exchange_market_symbol_key
    UNIQUE (exchange, market_symbol)
);

CREATE TABLE public.crypto_assets (
  coingecko_id text PRIMARY KEY,
  symbol text NOT NULL,
  name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

-- Compile and exercise the exact migration candidate, not a copied expression.
\ir ../migrations/20261121061500_fix_bit24_duplicate_market_rows.sql

DO $$
DECLARE
  v_result jsonb;
  v_payload jsonb;
  v_conflict_message text;
BEGIN
  -- Two identical market identities in one HTTP response must produce one upsert.
  -- Their timestamps/request IDs are equal, so the JSONB tie-breaker is exercised.
  INSERT INTO public.bit24_exchange_sync_requests(request_id, requested_at)
  VALUES (100, timestamptz '2026-01-01 00:00:00+00');

  INSERT INTO net._http_response(id, status_code, content, error_msg)
  VALUES (
    100,
    200,
    jsonb_build_object(
      'data',
      jsonb_build_object(
        'results',
        jsonb_build_array(
          jsonb_build_object(
            'market_name', 'AAA/USDT',
            'base_coin', jsonb_build_object('symbol', 'AAA', 'name', 'Alpha'),
            'quote_coin', jsonb_build_object('symbol', 'USDT'),
            'z', 1, 'a', 2
          ),
          jsonb_build_object(
            'market_name', 'AAA/USDT',
            'base_coin', jsonb_build_object('symbol', 'AAA', 'name', 'Alpha'),
            'quote_coin', jsonb_build_object('symbol', 'USDT'),
            'z', 2, 'a', 1
          )
        )
      )
    )::text,
    NULL
  );

  v_result := public.process_bit24_exchange_sync();

  IF (v_result->>'processed_requests')::integer <> 1 THEN
    RAISE EXCEPTION 'Expected one processed request, got %', v_result;
  END IF;

  IF (SELECT count(*) FROM public.exchange_asset_observations
      WHERE exchange = 'bit24' AND market_symbol = 'AAA_USDT') <> 1 THEN
    RAISE EXCEPTION 'Duplicate market rows were not reduced to exactly one row';
  END IF;

  SELECT source_payload INTO v_payload
  FROM public.exchange_asset_observations
  WHERE exchange = 'bit24' AND market_symbol = 'AAA_USDT';

  IF v_payload->>'z' <> '1' OR v_payload->>'a' <> '2' THEN
    RAISE EXCEPTION 'Deterministic JSONB tie-break selected unexpected payload: %', v_payload;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.bit24_exchange_sync_requests
    WHERE request_id = 100 AND processed_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Successful response request was not marked processed';
  END IF;

  -- NULL and non-NULL quote metadata are conflicting identities. The whole batch
  -- must abort before inserting rows or marking its request as processed.
  INSERT INTO public.bit24_exchange_sync_requests(request_id, requested_at)
  VALUES (200, timestamptz '2026-01-02 00:00:00+00');

  INSERT INTO net._http_response(id, status_code, content, error_msg)
  VALUES (
    200,
    200,
    jsonb_build_object(
      'data',
      jsonb_build_object(
        'results',
        jsonb_build_array(
          jsonb_build_object(
            'market_name', 'BBB/USDT',
            'base_coin', jsonb_build_object('symbol', 'BBB', 'name', 'Beta'),
            'quote_coin', '{}'::jsonb
          ),
          jsonb_build_object(
            'market_name', 'BBB/USDT',
            'base_coin', jsonb_build_object('symbol', 'BBB', 'name', 'Beta'),
            'quote_coin', jsonb_build_object('symbol', 'USDT')
          )
        )
      )
    )::text,
    NULL
  );

  BEGIN
    PERFORM public.process_bit24_exchange_sync();
    RAISE EXCEPTION 'Expected conflicting metadata to abort the Bit24 batch';
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_conflict_message = MESSAGE_TEXT;
    IF v_conflict_message NOT LIKE 'Bit24 sync safely aborted:%' THEN
      RAISE;
    END IF;
  END;

  IF EXISTS (
    SELECT 1 FROM public.exchange_asset_observations
    WHERE exchange = 'bit24' AND market_symbol = 'BBB_USDT'
  ) THEN
    RAISE EXCEPTION 'Conflicting batch unexpectedly inserted BBB_USDT';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.bit24_exchange_sync_requests
    WHERE request_id = 200 AND processed_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Conflicting batch request was incorrectly marked processed';
  END IF;
END;
$$;
