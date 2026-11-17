-- Disposable PostgreSQL fixture for process_iran_exchange_asset_sync().
CREATE SCHEMA IF NOT EXISTS private;
CREATE SCHEMA IF NOT EXISTS net;

CREATE TABLE public.exchange_asset_sync_requests (
  exchange text NOT NULL,
  request_id bigint NOT NULL,
  requested_at timestamptz NOT NULL,
  processed_at timestamptz,
  http_status integer,
  error_message text
);

CREATE TABLE net._http_response (
  id bigint PRIMARY KEY,
  created timestamptz NOT NULL,
  status_code integer,
  content text,
  error_msg text
);

CREATE TABLE public.exchange_asset_observations (
  id bigserial PRIMARY KEY,
  exchange text NOT NULL,
  market_symbol text NOT NULL,
  base_symbol text NOT NULL,
  quote_symbol text,
  asset_name text,
  source_url text,
  source_payload jsonb,
  is_active boolean,
  last_seen_at timestamptz,
  coingecko_id text,
  match_status text,
  UNIQUE(exchange, market_symbol)
);

CREATE TABLE public.crypto_assets (
  coingecko_id text PRIMARY KEY,
  symbol text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  name text
);

CREATE OR REPLACE FUNCTION private.try_parse_jsonb(p_text text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO ''
AS $$
BEGIN
  RETURN p_text::jsonb;
EXCEPTION WHEN others THEN
  RETURN NULL;
END;
$$;
