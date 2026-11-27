-- Dedicated disposable PostgreSQL fixture: conditional worker vs same-user sell placement.
-- Loaded only in GitHub Actions CI. Never execute against Production.
INSERT INTO public.profiles(id,is_active)
VALUES ('78000000-0000-0000-0000-000000000008',true);

INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled)
VALUES ('BTCUSDT','USDT',true);

INSERT INTO public.market_prices(symbol,price,updated_at)
VALUES ('BTCUSDT',12.000000000000000001,now());

INSERT INTO public.wallets(user_id,balance_usdt)
VALUES ('78000000-0000-0000-0000-000000000008',0);

INSERT INTO public.asset_balances(user_id,asset,balance)
VALUES ('78000000-0000-0000-0000-000000000008','BTC',1.500000000000000001);

INSERT INTO public.orders(
 id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status
) VALUES (
 '78000000-0000-0000-0000-000000000018',
 '78000000-0000-0000-0000-000000000008',
 'BTCUSDT','sell','conditional',1.000000000000000001,11,0,1.000000000000000001,'pending'
);

INSERT INTO public.conditional_orders(
 id,order_id,user_id,symbol,side,order_kind,trigger_price,amount,status
) VALUES (
 '78000000-0000-0000-0000-000000000118',
 '78000000-0000-0000-0000-000000000018',
 '78000000-0000-0000-0000-000000000008',
 'BTCUSDT','sell','take_profit',11,1.000000000000000001,'pending'
);

INSERT INTO public.order_reservations(
 id,order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
) VALUES (
 '78000000-0000-0000-0000-000000000218',
 '78000000-0000-0000-0000-000000000018',
 '78000000-0000-0000-0000-000000000008',
 'BTC',1.000000000000000001,0,0,'reserved'
);

CREATE OR REPLACE FUNCTION public.digiarz_delay_conditional_placement_trade()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS $delay$
BEGIN
 IF NEW.user_id='78000000-0000-0000-0000-000000000008'::uuid THEN
   PERFORM pg_catalog.pg_sleep(3);
 END IF;
 RETURN NEW;
END
$delay$;

CREATE TRIGGER digiarz_delay_conditional_placement_trade
BEFORE INSERT ON public.trades
FOR EACH ROW EXECUTE FUNCTION public.digiarz_delay_conditional_placement_trade();
