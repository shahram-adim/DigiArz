DO $verify$
DECLARE
  v_status text;
  v_filled numeric;
  v_remaining numeric;
  v_consumed numeric;
  v_released numeric;
  v_res_status text;
  v_balance numeric;
BEGIN
  SELECT status,filled_amount,remaining_amount
  INTO v_status,v_filled,v_remaining
  FROM public.orders WHERE id='71000000-0000-0000-0000-000000000011';
  IF v_status <> 'cancelled' OR v_filled <> 0.25 OR v_remaining <> 0.75 THEN
    RAISE EXCEPTION 'Worker-first race order mismatch: %, %, %',v_status,v_filled,v_remaining;
  END IF;
  IF (SELECT count(*) FROM public.trades
      WHERE order_id='71000000-0000-0000-0000-000000000011') <> 1 THEN
    RAISE EXCEPTION 'Worker-first race must create exactly one fill';
  END IF;
  SELECT consumed_amount,released_amount,status
  INTO v_consumed,v_released,v_res_status
  FROM public.order_reservations
  WHERE order_id='71000000-0000-0000-0000-000000000011';
  IF v_consumed <> 2.5025 OR v_released <> 7.5075 OR v_res_status <> 'released' THEN
    RAISE EXCEPTION 'Worker-first reservation mismatch: %, %, %',v_consumed,v_released,v_res_status;
  END IF;
  SELECT balance_usdt INTO v_balance FROM public.wallets
  WHERE user_id='71000000-0000-0000-0000-000000000001';
  IF v_balance <> 97.4975 THEN
    RAISE EXCEPTION 'Worker-first wallet mismatch: %',v_balance;
  END IF;

  SELECT status,filled_amount,remaining_amount
  INTO v_status,v_filled,v_remaining
  FROM public.orders WHERE id='72000000-0000-0000-0000-000000000022';
  IF v_status <> 'cancelled' OR v_filled <> 0 OR v_remaining <> 1 THEN
    RAISE EXCEPTION 'Cancel-first race order mismatch: %, %, %',v_status,v_filled,v_remaining;
  END IF;
  IF EXISTS (SELECT 1 FROM public.trades
             WHERE order_id='72000000-0000-0000-0000-000000000022') THEN
    RAISE EXCEPTION 'Cancel-first race unexpectedly created a trade';
  END IF;
  SELECT consumed_amount,released_amount,status
  INTO v_consumed,v_released,v_res_status
  FROM public.order_reservations
  WHERE order_id='72000000-0000-0000-0000-000000000022';
  IF v_consumed <> 0 OR v_released <> 10.01 OR v_res_status <> 'released' THEN
    RAISE EXCEPTION 'Cancel-first reservation mismatch: %, %, %',v_consumed,v_released,v_res_status;
  END IF;
  SELECT balance_usdt INTO v_balance FROM public.wallets
  WHERE user_id='72000000-0000-0000-0000-000000000002';
  IF v_balance <> 100 THEN
    RAISE EXCEPTION 'Cancel-first wallet should be untouched: %',v_balance;
  END IF;
END
$verify$;

DROP TRIGGER digiarz_delay_race_trade ON public.trades;
DROP FUNCTION public.digiarz_delay_race_trade();
SELECT 'two-session Limit worker/cancel race integration: PASS' AS result;
