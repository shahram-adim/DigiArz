-- Disposable PostgreSQL CI fixtures only; never run against Supabase Production.
INSERT INTO public.profiles(id,is_active) VALUES
 ('73000000-0000-0000-0000-000000000003',true),
 ('74000000-0000-0000-0000-000000000004',false);
INSERT INTO public.demo_trading_pairs VALUES ('BTCUSDT','USDT',true);
INSERT INTO public.market_prices VALUES ('BTCUSDT',10.000000000000000001,now());
INSERT INTO public.wallets VALUES
 ('73000000-0000-0000-0000-000000000003',100),
 ('74000000-0000-0000-0000-000000000004',100);
INSERT INTO public.asset_balances(user_id,asset,balance) VALUES
 ('73000000-0000-0000-0000-000000000003','BTC',0),
 ('74000000-0000-0000-0000-000000000004','BTC',0);

INSERT INTO public.orders(id,user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount,status) VALUES
 ('73000000-0000-0000-0000-000000000013','73000000-0000-0000-0000-000000000003','BTCUSDT','buy','conditional',1,10.000000000000000001,0,1,'triggered'),
 ('73000000-0000-0000-0000-000000000014','73000000-0000-0000-0000-000000000003','BTCUSDT','buy','limit',1,10.000000000000000001,0,1,'pending'),
 ('74000000-0000-0000-0000-000000000024','74000000-0000-0000-0000-000000000004','BTCUSDT','buy','conditional',1,10.000000000000000001,0,1,'triggered'),
 ('74000000-0000-0000-0000-000000000025','74000000-0000-0000-0000-000000000004','BTCUSDT','buy','limit',1,10.000000000000000001,0,1,'pending');

INSERT INTO public.conditional_orders(id,order_id,user_id,symbol,side,order_kind,trigger_price,limit_price,amount,status,execution_order_id) VALUES
 ('73000000-0000-0000-0000-000000000113','73000000-0000-0000-0000-000000000013','73000000-0000-0000-0000-000000000003','BTCUSDT','buy','stop_limit',9.5,10.000000000000000001,1,'triggered','73000000-0000-0000-0000-000000000014'),
 ('74000000-0000-0000-0000-000000000124','74000000-0000-0000-0000-000000000024','74000000-0000-0000-0000-000000000004','BTCUSDT','buy','stop_limit',9.5,10.000000000000000001,1,'triggered','74000000-0000-0000-0000-000000000025');

INSERT INTO public.order_reservations(id,order_id,user_id,asset,reserved_amount,consumed_amount,released_amount,status) VALUES
 ('73000000-0000-0000-0000-000000000213','73000000-0000-0000-0000-000000000013','73000000-0000-0000-0000-000000000003','USDT',10.01,0,10.01,'released'),
 ('73000000-0000-0000-0000-000000000214','73000000-0000-0000-0000-000000000014','73000000-0000-0000-0000-000000000003','USDT',10.01,0,0,'reserved'),
 ('74000000-0000-0000-0000-000000000224','74000000-0000-0000-0000-000000000024','74000000-0000-0000-0000-000000000004','USDT',10.01,0,10.01,'released'),
 ('74000000-0000-0000-0000-000000000225','74000000-0000-0000-0000-000000000025','74000000-0000-0000-0000-000000000004','USDT',10.01,0,0,'reserved');

CREATE OR REPLACE FUNCTION public.cancel_limit_order(p_order_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $cancel_limit$
DECLARE v_uid uuid:=auth.uid(); v_order public.orders%ROWTYPE; v_rows integer;
BEGIN
 IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
 SELECT * INTO v_order FROM public.orders WHERE id=p_order_id AND user_id=v_uid FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Order not found'; END IF;
 IF v_order.order_type<>'limit' THEN RAISE EXCEPTION 'Only limit orders can be cancelled here'; END IF;
 IF v_order.status NOT IN ('pending','partially_filled') THEN RAISE EXCEPTION 'Order cannot be cancelled'; END IF;
 UPDATE public.order_reservations
 SET released_amount=reserved_amount-consumed_amount,
     status=CASE WHEN consumed_amount>=reserved_amount THEN 'consumed' ELSE 'released' END,
     updated_at=now()
 WHERE order_id=p_order_id AND user_id=v_uid AND status='reserved'
   AND consumed_amount>=0 AND released_amount>=0
   AND consumed_amount+released_amount<=reserved_amount;
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Cannot cancel order: exactly one valid active reservation is required'; END IF;
 UPDATE public.orders SET status='cancelled',remaining_amount=amount-filled_amount
 WHERE id=p_order_id AND user_id=v_uid;
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Order cancellation update failed'; END IF;
 RETURN jsonb_build_object('success',true,'order_id',p_order_id,'status','cancelled',
   'filled_amount',v_order.filled_amount,'remaining_amount',v_order.amount-v_order.filled_amount);
END
$cancel_limit$;

CREATE OR REPLACE FUNCTION public.cancel_stop_limit_order(p_order_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $cancel_stop$
DECLARE
 v_uid uuid:=auth.uid(); v_cond public.conditional_orders%ROWTYPE;
 v_parent public.orders%ROWTYPE; v_child public.orders%ROWTYPE;
 v_cancel_result jsonb; v_final_status text; v_rows integer;
BEGIN
 IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
 SELECT * INTO v_cond FROM public.conditional_orders
 WHERE order_id=p_order_id AND user_id=v_uid AND order_kind='stop_limit' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Stop-Limit order not found'; END IF;
 SELECT * INTO v_parent FROM public.orders
 WHERE id=p_order_id AND user_id=v_uid AND order_type='conditional' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Parent order not found'; END IF;
 IF v_cond.status='pending' THEN
   RAISE EXCEPTION 'Fixture expects a triggered Stop-Limit order';
 END IF;
 IF v_cond.status<>'triggered' OR v_cond.execution_order_id IS NULL THEN
   RAISE EXCEPTION 'Stop-Limit order is no longer cancellable';
 END IF;
 SELECT * INTO v_child FROM public.orders
 WHERE id=v_cond.execution_order_id AND user_id=v_uid AND order_type='limit' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Triggered limit order not found'; END IF;
 IF v_child.status IN ('pending','partially_filled') THEN
   v_cancel_result:=public.cancel_limit_order(v_child.id);
   SELECT * INTO v_child FROM public.orders WHERE id=v_child.id AND user_id=v_uid;
 END IF;
 v_final_status:=CASE WHEN v_child.status='filled' THEN 'filled'
   WHEN v_child.status='rejected' THEN 'rejected' ELSE 'cancelled' END;
 UPDATE public.orders SET status=v_final_status,filled_amount=v_child.filled_amount,
   remaining_amount=v_child.remaining_amount
 WHERE id=p_order_id AND user_id=v_uid AND status='triggered';
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit parent state update failed'; END IF;
 UPDATE public.conditional_orders SET status=v_final_status,updated_at=now()
 WHERE id=v_cond.id AND status='triggered';
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Stop-Limit state update failed'; END IF;
 RETURN jsonb_build_object('success',true,'status',v_final_status,'order_id',p_order_id,
   'execution_order_id',v_child.id,'filled_amount',v_child.filled_amount,
   'remaining_amount',v_child.remaining_amount);
END
$cancel_stop$;

CREATE OR REPLACE FUNCTION public.digiarz_delay_stop_child_trade()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS $delay$
BEGIN
 IF NEW.order_id='73000000-0000-0000-0000-000000000014'::uuid THEN
   PERFORM pg_catalog.pg_sleep(2);
 END IF;
 RETURN NEW;
END
$delay$;
CREATE TRIGGER digiarz_delay_stop_child_trade BEFORE INSERT ON public.trades
FOR EACH ROW EXECUTE FUNCTION public.digiarz_delay_stop_child_trade();
