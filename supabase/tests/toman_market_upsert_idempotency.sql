BEGIN;

CREATE TEMP TABLE toman_price_upsert_fixture (
  exchange text NOT NULL,
  asset_symbol text NOT NULL,
  quote_currency text NOT NULL,
  price_toman numeric(38,18) NOT NULL,
  fetched_at timestamptz NOT NULL,
  CONSTRAINT toman_price_upsert_fixture_key UNIQUE (exchange, asset_symbol, quote_currency)
);

INSERT INTO toman_price_upsert_fixture (exchange, asset_symbol, quote_currency, price_toman, fetched_at)
VALUES ('nobitex', 'BTC', 'TOMAN', 123.450000000000000001, '2026-11-23T00:00:00Z');

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
