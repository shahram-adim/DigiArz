-- Dedicated disposable PostgreSQL fixture for overlapping parent and child cancellation.
-- Loaded only by GitHub Actions CI; never run against Production.
INSERT INTO public.profiles(id,is_active)
VALUES ('79000000-0000-0000-0000-000000000009',true);
INSERT INTO public.wallets(user_id,balance_usdt)
VALUES ('79000000-0000-0000-0000-000000000009',100);
INSERT INTO public.asset_balances(user_id,asset,balance)
VALUES ('79000000-0000-0000-0000-000000000009','BTC',0);

INSERT INTO public.orders(
 id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status
) VALUES
 ('79000000-0000-0000-0000-000000000019',
  '79000000-0000-0000-0000-000000000009',
  'BTCUSDT','buy','conditional',1,10,0,1,'triggered'),
 ('79000000-0000-0000-0000-000000000029',
  '79000000-0000-0000-0000-000000000009',
  'BTCUSDT','buy','limit',1,10,0,1,'pending');

INSERT INTO public.conditional_orders(
 id,order_id,user_id,symbol,side,order_kind,trigger_price,limit_price,amount,status,execution_order_id
) VALUES (
 '79000000-0000-0000-0000-000000000119',
 '79000000-0000-0000-0000-000000000019',
 '79000000-0000-0000-0000-000000000009',
 'BTCUSDT','buy','stop_limit',9.5,10,1,'triggered',
 '79000000-0000-0000-0000-000000000029'
);

INSERT INTO public.order_reservations(
 id,order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status
) VALUES
 ('79000000-0000-0000-0000-000000000219',
  '79000000-0000-0000-0000-000000000019',
  '79000000-0000-0000-0000-000000000009',
  'USDT',10.01,0,10.01,'released'),
 ('79000000-0000-0000-0000-000000000229',
  '79000000-0000-0000-0000-000000000029',
  '79000000-0000-0000-0000-000000000009',
  'USDT',10.01,0,0,'reserved');

CREATE OR REPLACE FUNCTION public.digiarz_delay_parent_child_cancel()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS $delay$
BEGIN
 IF NEW.user_id='79000000-0000-0000-0000-000000000009'::uuid
    AND NEW.order_id='79000000-0000-0000-0000-000000000029'::uuid THEN
  PERFORM pg_catalog.pg_sleep(3);
 END IF;
 RETURN NEW;
END
$delay$;
CREATE TRIGGER digiarz_delay_parent_child_cancel
BEFORE UPDATE ON public.order_reservations
FOR EACH ROW EXECUTE FUNCTION public.digiarz_delay_parent_child_cancel();
