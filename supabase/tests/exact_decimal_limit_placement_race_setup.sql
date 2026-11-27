-- Disposable two-session race fixture: Limit worker vs a new sell placement.
-- Executed only in the dedicated GitHub Actions PostgreSQL database.

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $uid$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid
$uid$;

INSERT INTO auth.users (id)
VALUES ('81000000-0000-0000-0000-000000000001');

INSERT INTO public.profiles (id, is_active)
VALUES ('81000000-0000-0000-0000-000000000001', true);

INSERT INTO public.crypto_assets (coingecko_id)
VALUES ('bitcoin');

INSERT INTO public.demo_trading_pairs (
  pair_symbol, base_coingecko_id, quote_asset, is_enabled
)
VALUES ('BTCUSDT', 'bitcoin', 'USDT', true);

INSERT INTO public.market_prices (symbol, price, source, updated_at)
VALUES ('BTCUSDT', 10.000000000000000001, 'placement-race-fixture', now());

INSERT INTO public.wallets (user_id, balance_usdt)
VALUES ('81000000-0000-0000-0000-000000000001', 100);

INSERT INTO public.asset_balances (user_id, asset, balance)
VALUES ('81000000-0000-0000-0000-000000000001', 'BTC', 1.5);

INSERT INTO public.orders (
  id, user_id, symbol, side, order_type, amount, price,
  filled_amount, remaining_amount, status
)
VALUES (
  '81000000-0000-0000-0000-000000000011',
  '81000000-0000-0000-0000-000000000001',
  'BTCUSDT', 'sell', 'limit', 1, 10, 0, 1, 'pending'
);

INSERT INTO public.order_reservations (
  id, order_id, user_id, asset, reserved_amount,
  consumed_amount, released_amount, status
)
VALUES (
  '81000000-0000-0000-0000-000000000111',
  '81000000-0000-0000-0000-000000000011',
  '81000000-0000-0000-0000-000000000001',
  'BTC', 1, 0, 0, 'reserved'
);

CREATE OR REPLACE FUNCTION public.digiarz_delay_placement_race_trade()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $race$
BEGIN
  IF NEW.order_id = '81000000-0000-0000-0000-000000000011'::uuid THEN
    PERFORM pg_catalog.pg_sleep(3);
  END IF;
  RETURN NEW;
END
$race$;

CREATE TRIGGER digiarz_delay_placement_race_trade
BEFORE INSERT ON public.trades
FOR EACH ROW
EXECUTE FUNCTION public.digiarz_delay_placement_race_trade();
