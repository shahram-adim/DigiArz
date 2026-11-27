-- Disposable two-session race: two concurrent same-user buy placements.
-- Runs only in the dedicated GitHub Actions PostgreSQL database.

-- The shared worker fixture intentionally stubs auth.uid() to NULL.
-- Restore the session-claim implementation used by authenticated RPC tests.
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $uid$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid
$uid$;

INSERT INTO auth.users(id) VALUES ('82000000-0000-0000-0000-000000000001');
INSERT INTO public.profiles(id,is_active) VALUES ('82000000-0000-0000-0000-000000000001',true);
INSERT INTO public.crypto_assets(coingecko_id) VALUES ('bitcoin');
INSERT INTO public.demo_trading_pairs(pair_symbol,base_coingecko_id,quote_asset,is_enabled)
VALUES ('BTCUSDT','bitcoin','USDT',true);
INSERT INTO public.wallets(user_id,balance_usdt)
VALUES ('82000000-0000-0000-0000-000000000001',10);

-- Pause the first placement after it has acquired the wallet row lock.
CREATE OR REPLACE FUNCTION public.digiarz_delay_buy_placement_race()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $race$
BEGIN
  IF NEW.user_id='82000000-0000-0000-0000-000000000001'::uuid
     AND NEW.order_type='limit' AND NEW.side='buy' THEN
    PERFORM pg_catalog.pg_sleep(3);
  END IF;
  RETURN NEW;
END
$race$;

CREATE TRIGGER zz_digiarz_delay_buy_placement_race
BEFORE INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.digiarz_delay_buy_placement_race();
