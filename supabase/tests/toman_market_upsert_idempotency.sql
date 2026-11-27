BEGIN;

-- Mirror the live unique key on public.market_toman_prices.
-- The deployed v3 function used a plain POST, which maps to INSERT without ON CONFLICT.
CREATE TEMP TABLE toman_price_upsert_fixture (
  exchange text NOT NULL,
  asset_symbol text NOT NULL,
  quote_currency text NOT NULL,
  price_toman numeric(38,18) NOT NULL,
  fetched_at timestamptz NOT NULL,
  CONSTRAINT market_toman_prices_exchange_asset_symbol_quote_currency_key
    UNIQUE (exchange, asset_symbol, quote_currency)
);

INSERT INTO toman_price_upsert_fixture (exchange, asset_symbol, quote_currency, price_toman, fetched_at)
VALUES ('nobitex', 'BTC', 'TOMAN', 123.450000000000000001, '2026-11-23T00:00:00Z');

-- Reproduce the production-v3 failure without touching the production table.
DO $$
DECLARE
  v_sqlstate text;
  v_constraint text;
BEGIN
  BEGIN
    INSERT INTO toman_price_upsert_fixture (exchange, asset_symbol, quote_currency, price_toman, fetched_at)
    VALUES ('nobitex', 'BTC', 'TOMAN', 124.560000000000000002, '2026-11-23T00:01:00Z');
    RAISE EXCEPTION 'legacy plain insert unexpectedly succeeded';
  EXCEPTION WHEN unique_violation THEN
    GET STACKED DIAGNOSTICS
      v_sqlstate = RETURNED_SQLSTATE,
      v_constraint = CONSTRAINT_NAME;
    IF v_sqlstate <> '23505'
       OR v_constraint <> 'market_toman_prices_exchange_asset_symbol_quote_currency_key' THEN
      RAISE EXCEPTION 'unexpected duplicate-key result: SQLSTATE %, constraint %', v_sqlstate, v_constraint;
    END IF;
  END;
END $$;

-- The current main-branch PostgREST upsert strategy is idempotent for the same key.
INSERT INTO toman_price_upsert_fixture (exchange, asset_symbol, quote_currency, price_toman, fetched_at)
VALUES ('nobitex', 'BTC', 'TOMAN', 124.560000000000000002, '2026-11-23T00:01:00Z')
ON CONFLICT (exchange, asset_symbol, quote_currency)
DO UPDATE SET price_toman = EXCLUDED.price_toman, fetched_at = EXCLUDED.fetched_at;

DO $$
DECLARE
  v_count bigint;
  v_price numeric;
  v_fetched_at timestamptz;
BEGIN
  SELECT count(*), max(price_toman), max(fetched_at)
  INTO v_count, v_price, v_fetched_at
  FROM toman_price_upsert_fixture;
  IF v_count <> 1 THEN RAISE EXCEPTION 'idempotent upsert expected one row, found %', v_count; END IF;
  IF v_price <> 124.560000000000000002 THEN RAISE EXCEPTION 'upsert did not replace latest price: %', v_price; END IF;
  IF v_fetched_at <> '2026-11-23T00:01:00Z'::timestamptz THEN RAISE EXCEPTION 'upsert did not advance fetched_at: %', v_fetched_at; END IF;
END $$;

ROLLBACK;
