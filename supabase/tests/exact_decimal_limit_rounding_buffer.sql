-- Regression for per-fill 8-place USDT rounding; disposable CI database only.
INSERT INTO public.profiles(id,is_active) VALUES
 ('80000000-0000-0000-0000-000000000008',true),
 ('81000000-0000-0000-0000-000000000009',true);
INSERT INTO public.demo_trading_pairs VALUES ('BTCUSDT','USDT',true);
INSERT INTO public.market_prices VALUES ('BTCUSDT',76350246.816325574,now());
INSERT INTO public.wallets(user_id,balance_usdt) VALUES
 ('80000000-0000-0000-0000-000000000008',50000000),
 ('81000000-0000-0000-0000-000000000009',50000000);
INSERT INTO public.asset_balances(user_id,asset,balance) VALUES
 ('80000000-0000-0000-0000-000000000008','BTC',0),
 ('81000000-0000-0000-0000-000000000009','BTC',0);
DO $test$
DECLARE
 v_amount numeric:=0.476597292745693361;
 v_price numeric:=76350246.816325574;
 v_expected numeric;
 v_order uuid;
 v_result jsonb;
 v_res_status text;
 v_cycle integer;
 v_reserved numeric;
 v_consumed numeric;
 v_released numeric;
 v_wallet numeric;
 v_asset numeric;
 v_ledger numeric;
BEGIN
 v_expected:=round(v_amount*v_price,8)
   +round(round(v_amount*v_price,8)*0.001,8)+0.0000001;
 PERFORM set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000008',true);
 v_result:=public.place_limit_order('BTCUSDT','buy',v_amount,v_price);
 v_order:=(v_result->>'order_id')::uuid;
 SELECT reserved_amount INTO v_reserved FROM public.order_reservations WHERE order_id=v_order;
 IF v_reserved<>v_expected THEN
   RAISE EXCEPTION 'Limit placement rounding reserve mismatch: expected %, got %',v_expected,v_reserved;
 END IF;
 FOR v_cycle IN 1..4 LOOP
   v_result:=public.process_limit_orders();
 END LOOP;
 IF (SELECT status FROM public.orders WHERE id=v_order)<>'filled'
    OR (SELECT filled_amount FROM public.orders WHERE id=v_order)<>v_amount THEN
   RAISE EXCEPTION 'Four partial fills did not complete the high-precision Limit order';
 END IF;
 IF (SELECT count(*) FROM public.trades WHERE order_id=v_order)<>4
    OR (SELECT sum(amount) FROM public.trades WHERE order_id=v_order)<>v_amount THEN
   RAISE EXCEPTION 'High-precision Limit trade rows do not reconcile';
 END IF;
 SELECT sum(amount) INTO v_ledger FROM public.transactions
 WHERE user_id='80000000-0000-0000-0000-000000000008'
   AND currency='USDT' AND transaction_type='limit_buy';
 SELECT consumed_amount,released_amount,status INTO v_consumed,v_released,v_res_status
 FROM public.order_reservations WHERE order_id=v_order;
 IF v_consumed<>v_ledger OR v_consumed+v_released<>v_reserved OR v_res_status<>'released' THEN
   RAISE EXCEPTION 'Per-fill settlement/reservation mismatch: consumed %, ledger %, released %, reserved %, status %',
     v_consumed,v_ledger,v_released,v_reserved,v_res_status;
 END IF;
 SELECT balance_usdt INTO v_wallet FROM public.wallets
 WHERE user_id='80000000-0000-0000-0000-000000000008';
 SELECT balance INTO v_asset FROM public.asset_balances
 WHERE user_id='80000000-0000-0000-0000-000000000008' AND asset='BTC';
 IF v_wallet<>50000000-v_ledger OR v_asset<>v_amount THEN
   RAISE EXCEPTION 'High-precision Limit wallet/asset mismatch: %, %',v_wallet,v_asset;
 END IF;

 PERFORM set_config('request.jwt.claim.sub','81000000-0000-0000-0000-000000000009',true);
 v_result:=public.place_stop_limit_order('BTCUSDT','buy',v_amount,v_price-1,v_price);
 v_order:=(v_result->>'order_id')::uuid;
 SELECT reserved_amount INTO v_reserved FROM public.order_reservations WHERE order_id=v_order;
 IF v_reserved<>v_expected THEN
   RAISE EXCEPTION 'Stop-Limit placement rounding reserve mismatch: expected %, got %',v_expected,v_reserved;
 END IF;
END
$test$;
SELECT 'per-fill USDT rounding reserve regression: PASS' AS result;
