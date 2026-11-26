-- Disposable PostgreSQL CI fixtures only; never run against Supabase Production.
INSERT INTO public.profiles(id,is_active) VALUES
 ('75000000-0000-0000-0000-000000000005',true),
 ('76000000-0000-0000-0000-000000000006',false);
INSERT INTO public.demo_trading_pairs VALUES ('BTCUSDT','USDT',true);
INSERT INTO public.market_prices VALUES ('BTCUSDT',12.000000000000000001,now());
INSERT INTO public.wallets(user_id,balance_usdt) VALUES
 ('75000000-0000-0000-0000-000000000005',0),
 ('76000000-0000-0000-0000-000000000006',0);
INSERT INTO public.asset_balances(user_id,asset,balance) VALUES
 ('75000000-0000-0000-0000-000000000005','BTC',1.000000000000000001),
 ('76000000-0000-0000-0000-000000000006','BTC',1.000000000000000001);
INSERT INTO public.orders(id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status) VALUES
 ('75000000-0000-0000-0000-000000000015','75000000-0000-0000-0000-000000000005','BTCUSDT','sell','conditional',1.000000000000000001,11,0,1.000000000000000001,'pending'),
 ('76000000-0000-0000-0000-000000000026','76000000-0000-0000-0000-000000000006','BTCUSDT','sell','conditional',1.000000000000000001,11,0,1.000000000000000001,'pending');
INSERT INTO public.conditional_orders(id,order_id,user_id,symbol,side,order_kind,trigger_price,amount,status) VALUES
 ('75000000-0000-0000-0000-000000000115','75000000-0000-0000-0000-000000000015','75000000-0000-0000-0000-000000000005','BTCUSDT','sell','take_profit',11,1.000000000000000001,'pending'),
 ('76000000-0000-0000-0000-000000000126','76000000-0000-0000-0000-000000000026','76000000-0000-0000-0000-000000000006','BTCUSDT','sell','take_profit',11,1.000000000000000001,'pending');
INSERT INTO public.order_reservations(id,order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status) VALUES
 ('75000000-0000-0000-0000-000000000215','75000000-0000-0000-0000-000000000015','75000000-0000-0000-0000-000000000005','BTC',1.000000000000000001,0,0,'reserved'),
 ('76000000-0000-0000-0000-000000000226','76000000-0000-0000-0000-000000000026','76000000-0000-0000-0000-000000000006','BTC',1.000000000000000001,0,0,'reserved');

CREATE OR REPLACE FUNCTION public.cancel_conditional_exit_order(p_order_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $cancel_cond$
DECLARE
 v_uid uuid:=auth.uid(); v_cond public.conditional_orders%ROWTYPE;
 v_res public.order_reservations%ROWTYPE; v_rows integer;
BEGIN
 IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
 IF NOT public.current_account_is_active() THEN RAISE EXCEPTION 'Account is inactive'; END IF;
 SELECT * INTO v_cond FROM public.conditional_orders
 WHERE order_id=p_order_id AND user_id=v_uid FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Conditional order not found'; END IF;
 IF v_cond.status<>'pending' THEN RAISE EXCEPTION 'Conditional order cannot be cancelled'; END IF;
 SELECT * INTO v_res FROM public.order_reservations
 WHERE order_id=p_order_id AND user_id=v_uid FOR UPDATE;
 IF NOT FOUND OR v_res.status<>'reserved' OR v_res.consumed_amount<0
   OR v_res.consumed_amount+v_res.released_amount>v_res.reserved_amount THEN
   RAISE EXCEPTION 'Valid active reservation not found';
 END IF;
 UPDATE public.order_reservations SET released_amount=reserved_amount-consumed_amount,
   status=CASE WHEN consumed_amount>=reserved_amount THEN 'consumed' ELSE 'released' END,
   updated_at=now() WHERE id=v_res.id AND status='reserved';
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Reservation release failed'; END IF;
 UPDATE public.orders SET status='cancelled',remaining_amount=amount-filled_amount
 WHERE id=p_order_id AND user_id=v_uid AND order_type='conditional'
   AND status IN ('pending','partially_filled');
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Order cancellation failed'; END IF;
 UPDATE public.conditional_orders SET status='cancelled',updated_at=now()
 WHERE id=v_cond.id AND status='pending';
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Conditional order cancellation failed'; END IF;
 RETURN jsonb_build_object('success',true,'status','cancelled','order_id',p_order_id,
   'released_amount',v_res.reserved_amount-v_res.consumed_amount);
END
$cancel_cond$;

CREATE OR REPLACE FUNCTION public.digiarz_delay_conditional_trade()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS $delay$
BEGIN
 IF NEW.user_id='75000000-0000-0000-0000-000000000005'::uuid THEN
   PERFORM pg_catalog.pg_sleep(2);
 END IF;
 RETURN NEW;
END
$delay$;
CREATE TRIGGER digiarz_delay_conditional_trade BEFORE INSERT ON public.trades
FOR EACH ROW EXECUTE FUNCTION public.digiarz_delay_conditional_trade();
