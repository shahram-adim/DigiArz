-- Disposable PostgreSQL-only fixtures for real two-session worker/cancel races.
UPDATE public.orders SET status='cancelled' WHERE status IN ('pending','partially_filled')
  AND id NOT IN ('71000000-0000-0000-0000-000000000011','72000000-0000-0000-0000-000000000022');

UPDATE public.market_prices
SET price = 10.000000000000000001, updated_at = now()
WHERE symbol = 'BTCUSDT';

INSERT INTO public.profiles (id,is_active) VALUES
('71000000-0000-0000-0000-000000000001',true),
('72000000-0000-0000-0000-000000000002',false);
INSERT INTO public.wallets (user_id,balance_usdt) VALUES
('71000000-0000-0000-0000-000000000001',100),
('72000000-0000-0000-0000-000000000002',100);
INSERT INTO public.asset_balances (user_id,asset,balance) VALUES
('71000000-0000-0000-0000-000000000001','BTC',0),
('72000000-0000-0000-0000-000000000002','BTC',0);
INSERT INTO public.orders (
 id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status
) VALUES
('71000000-0000-0000-0000-000000000011','71000000-0000-0000-0000-000000000001',
 'BTCUSDT','buy','limit',1,10.000000000000000001,0,1,'pending'),
('72000000-0000-0000-0000-000000000022','72000000-0000-0000-0000-000000000002',
 'BTCUSDT','buy','limit',1,10.000000000000000001,0,1,'pending');
INSERT INTO public.order_reservations (
 id,order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
) VALUES
('71000000-0000-0000-0000-000000000111','71000000-0000-0000-0000-000000000011',
 '71000000-0000-0000-0000-000000000001','USDT',10.01,0,0,'reserved'),
('72000000-0000-0000-0000-000000000222','72000000-0000-0000-0000-000000000022',
 '72000000-0000-0000-0000-000000000002','USDT',10.01,0,0,'reserved');

CREATE OR REPLACE FUNCTION public.digiarz_delay_race_trade()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS $race$
BEGIN
  IF NEW.order_id = '71000000-0000-0000-0000-000000000011'::uuid THEN
    PERFORM pg_catalog.pg_sleep(2);
  END IF;
  RETURN NEW;
END
$race$;

CREATE TRIGGER digiarz_delay_race_trade
BEFORE INSERT ON public.trades
FOR EACH ROW EXECUTE FUNCTION public.digiarz_delay_race_trade();
