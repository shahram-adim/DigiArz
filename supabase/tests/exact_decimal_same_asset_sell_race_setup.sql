-- Disposable two-session race: two same-user sell placements compete for one BTC balance.
-- Runs only in the dedicated GitHub Actions PostgreSQL database.
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $uid$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid
$uid$;

INSERT INTO auth.users(id) VALUES ('83000000-0000-0000-0000-000000000001');
INSERT INTO public.profiles(id,is_active) VALUES ('83000000-0000-0000-0000-000000000001',true);
INSERT INTO public.crypto_assets(coingecko_id) VALUES ('bitcoin');
INSERT INTO public.demo_trading_pairs(pair_symbol,base_coingecko_id,quote_asset,is_enabled)
VALUES ('BTCUSDT','bitcoin','USDT',true);
INSERT INTO public.wallets(user_id,balance_usdt)
VALUES ('83000000-0000-0000-0000-000000000001',100);
INSERT INTO public.asset_balances(user_id,asset,balance)
VALUES ('83000000-0000-0000-0000-000000000001','BTC',1);

-- Hold the first placement after it has acquired the wallet lock and reached order insertion.
CREATE OR REPLACE FUNCTION public.digiarz_delay_same_asset_sell_race()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $race$
BEGIN
  IF NEW.user_id='83000000-0000-0000-0000-000000000001'::uuid
     AND NEW.order_type='limit' AND NEW.side='sell' THEN
    PERFORM pg_catalog.pg_sleep(3);
  END IF;
  RETURN NEW;
END
$race$;

CREATE TRIGGER zz_digiarz_delay_same_asset_sell_race
BEFORE INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.digiarz_delay_same_asset_sell_race();
