-- Applies and exercises the exact checked-in migration function bodies in disposable PostgreSQL.
-- The only substitutions are the explicitly declared downstream Market/Limit engine adapters in setup.
DO $$
DECLARE
  v_user uuid := '10000000-0000-0000-0000-000000000001';
  v_tp jsonb;
  v_sl jsonb;
  v_cond_id uuid;
  v_order_id uuid;
  v_result jsonb;
  v_child_id uuid;
  v_parent_status text;
  v_cond_status text;
BEGIN
  INSERT INTO auth.users(id) VALUES(v_user);
  INSERT INTO public.profiles(id,is_active) VALUES(v_user,true);
  INSERT INTO public.wallets(user_id,balance_usdt) VALUES(v_user,10000);
  INSERT INTO public.asset_balances(user_id,asset,balance) VALUES(v_user,'DOT',10);
  INSERT INTO public.demo_trading_pairs(pair_symbol,quote_asset,is_enabled) VALUES('DOTUSDT','USDT',true);
  INSERT INTO public.market_prices(symbol,price,updated_at) VALUES('DOTUSDT',13,clock_timestamp());
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);

  v_tp:=public.place_conditional_exit_order('DOTUSDT','take_profit',1,12);
  v_order_id:=(v_tp->>'order_id')::uuid;
  v_cond_id:=(v_tp->>'conditional_order_id')::uuid;
  IF (SELECT asset FROM public.order_reservations WHERE order_id=v_order_id)<>'DOT' THEN
    RAISE EXCEPTION 'TP/SL placement did not reserve the expected base ticker';
  END IF;
  v_result:=public.process_conditional_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>1 THEN
    RAISE EXCEPTION 'authoritative TP/SL worker did not trigger: %',v_result;
  END IF;
  IF (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'filled'
     OR (SELECT status FROM public.orders WHERE id=v_order_id)<>'filled' THEN
    RAISE EXCEPTION 'authoritative TP/SL lifecycle did not reach filled';
  END IF;

  -- Stop-loss branch: current price 13 is below trigger 14, so the real
  -- migration worker must execute this exit (the opposite inequality to TP).
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  v_sl:=public.place_conditional_exit_order('DOTUSDT','stop_loss',1,14);
  v_order_id:=(v_sl->>'order_id')::uuid;
  v_cond_id:=(v_sl->>'conditional_order_id')::uuid;
  v_result:=public.process_conditional_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>1 THEN
    RAISE EXCEPTION 'authoritative Stop-Loss worker did not trigger: %',v_result;
  END IF;
  IF (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'filled'
     OR (SELECT status FROM public.orders WHERE id=v_order_id)<>'filled' THEN
    RAISE EXCEPTION 'authoritative Stop-Loss lifecycle did not reach filled';
  END IF;

  -- Each real conditional worker clears its temporary JWT claims.
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);

  -- Stale TP/SL market observation must fail closed and keep its reservation.
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  v_tp:=public.place_conditional_exit_order('DOTUSDT','take_profit',0.5,12);
  v_order_id:=(v_tp->>'order_id')::uuid;
  v_cond_id:=(v_tp->>'conditional_order_id')::uuid;
  UPDATE public.market_prices SET updated_at=clock_timestamp()-interval '3 minutes'
  WHERE symbol='DOTUSDT';
  v_result:=public.process_conditional_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>0
     OR (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'pending'
     OR (SELECT status FROM public.order_reservations WHERE order_id=v_order_id)<>'reserved' THEN
    RAISE EXCEPTION 'stale TP/SL price did not fail closed with reservation preserved: %',v_result;
  END IF;
  UPDATE public.market_prices SET updated_at=clock_timestamp() WHERE symbol='DOTUSDT';
  v_result:=public.process_conditional_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>1
     OR (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'filled' THEN
    RAISE EXCEPTION 'fresh TP/SL price did not resume pending conditional order: %',v_result;
  END IF;

  -- A malformed Stop-Limit reservation must not create a child order. After
  -- repair in this disposable fixture, the same pending parent can be retried.
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  -- Stop-Limit buy: the exact migration places a parent, triggers it, and
  -- links the child returned by the isolated Limit-engine adapter.
  INSERT INTO public.market_prices(symbol,price,updated_at)
  VALUES('DOTUSDT',10,clock_timestamp())
  ON CONFLICT(symbol) DO UPDATE SET price=EXCLUDED.price,updated_at=EXCLUDED.updated_at;
  v_result:=public.place_stop_limit_order('DOTUSDT','buy',1,10,11);
  v_order_id:=(v_result->>'order_id')::uuid;
  v_cond_id:=(v_result->>'conditional_order_id')::uuid;
  v_result:=public.process_stop_limit_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>1 THEN
    RAISE EXCEPTION 'authoritative Stop-Limit worker did not trigger: %',v_result;
  END IF;
  SELECT execution_order_id,status INTO v_child_id,v_cond_status
  FROM public.conditional_orders WHERE id=v_cond_id;
  SELECT status INTO v_parent_status FROM public.orders WHERE id=v_order_id;
  IF v_cond_status<>'triggered' OR v_parent_status<>'triggered' OR v_child_id IS NULL THEN
    RAISE EXCEPTION 'Stop-Limit parent/child linkage failed: conditional %, parent %, child %',
      v_cond_status,v_parent_status,v_child_id;
  END IF;

  -- Stop-Limit stale quote: do not trigger and do not release the reserved quote.
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  INSERT INTO public.market_prices(symbol,price,updated_at)
  VALUES('DOTUSDT',10,clock_timestamp()-interval '3 minutes')
  ON CONFLICT(symbol) DO UPDATE SET price=EXCLUDED.price,updated_at=EXCLUDED.updated_at;
  v_result:=public.place_stop_limit_order('DOTUSDT','buy',0.25,10,11);
  v_order_id:=(v_result->>'order_id')::uuid;
  v_cond_id:=(v_result->>'conditional_order_id')::uuid;
  v_result:=public.process_stop_limit_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>0
     OR (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'pending'
     OR (SELECT status FROM public.order_reservations WHERE order_id=v_order_id)<>'reserved' THEN
    RAISE EXCEPTION 'stale Stop-Limit quote did not fail closed: %',v_result;
  END IF;
  UPDATE public.market_prices SET price=10,updated_at=clock_timestamp() WHERE symbol='DOTUSDT';
  v_result:=public.process_stop_limit_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>1
     OR (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'triggered' THEN
    RAISE EXCEPTION 'fresh Stop-Limit quote did not trigger pending order: %',v_result;
  END IF;

  -- Invalid reservation asset must be rejected before the Limit adapter is called.
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  v_result:=public.place_stop_limit_order('DOTUSDT','buy',0.2,10,11);
  v_order_id:=(v_result->>'order_id')::uuid;
  v_cond_id:=(v_result->>'conditional_order_id')::uuid;
  UPDATE public.order_reservations SET asset='DOT' WHERE order_id=v_order_id;
  v_result:=public.process_stop_limit_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>0
     OR (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'pending'
     OR (SELECT attempt_count FROM public.conditional_orders WHERE id=v_cond_id)<>1
     OR EXISTS (SELECT 1 FROM public.orders WHERE user_id=v_user AND order_type='limit'
                AND id=(SELECT execution_order_id FROM public.conditional_orders WHERE id=v_cond_id)) THEN
    RAISE EXCEPTION 'malformed Stop-Limit reservation was not rejected safely: %',v_result;
  END IF;
  UPDATE public.order_reservations SET asset='USDT' WHERE order_id=v_order_id;
  v_result:=public.process_stop_limit_orders();
  IF COALESCE((v_result->>'triggered')::integer,0)<>1
     OR (SELECT status FROM public.conditional_orders WHERE id=v_cond_id)<>'triggered' THEN
    RAISE EXCEPTION 'repaired Stop-Limit reservation did not retry safely: %',v_result;
  END IF;

  -- The actual migration ACLs must keep worker entrypoints service_role-only.
  IF has_function_privilege('authenticated','public.process_conditional_orders()','EXECUTE')
     OR NOT has_function_privilege('service_role','public.process_conditional_orders()','EXECUTE')
     OR has_function_privilege('authenticated','public.process_stop_limit_orders()','EXECUTE')
     OR NOT has_function_privilege('service_role','public.process_stop_limit_orders()','EXECUTE') THEN
    RAISE EXCEPTION 'worker execute ACL is not service_role-only';
  END IF;
  IF NOT has_table_privilege('authenticated','public.conditional_orders','SELECT')
     OR has_table_privilege('authenticated','public.conditional_orders','INSERT')
     OR NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.conditional_orders'::regclass) THEN
    RAISE EXCEPTION 'conditional_orders RLS/read-only client boundary failed';
  END IF;

  RAISE NOTICE 'Authoritative TP/SL + Stop-Limit migration source-parity harness: PASS';
END $$;
