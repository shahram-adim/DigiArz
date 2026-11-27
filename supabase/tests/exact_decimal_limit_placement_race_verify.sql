-- Verify the worker committed one partial sell fill and the competing
-- placement was rejected without creating a second order or reservation.

DO $verify$
DECLARE
  v_order_status text;
  v_filled numeric;
  v_remaining numeric;
  v_inventory numeric;
  v_wallet numeric;
  v_reserved numeric;
  v_consumed numeric;
  v_released numeric;
  v_reservation_status text;
  v_trade_count integer;
  v_order_count integer;
  v_reservation_count integer;
BEGIN
  SELECT status, filled_amount, remaining_amount
  INTO v_order_status, v_filled, v_remaining
  FROM public.orders
  WHERE id='81000000-0000-0000-0000-000000000011';

  IF v_order_status <> 'partially_filled'
     OR v_filled <> 0.25::numeric
     OR v_remaining <> 0.75::numeric THEN
    RAISE EXCEPTION 'Worker partial-fill state mismatch: %, %, %',
      v_order_status, v_filled, v_remaining;
  END IF;

  SELECT balance INTO v_inventory
  FROM public.asset_balances
  WHERE user_id='81000000-0000-0000-0000-000000000001'
    AND asset='BTC';

  IF v_inventory <> 1.25::numeric THEN
    RAISE EXCEPTION 'Sell inventory after worker commit mismatch: %', v_inventory;
  END IF;

  SELECT balance_usdt INTO v_wallet
  FROM public.wallets
  WHERE user_id='81000000-0000-0000-0000-000000000001';

  IF v_wallet <> 102.4975::numeric THEN
    RAISE EXCEPTION 'Sell proceeds/fee wallet mismatch: %', v_wallet;
  END IF;

  SELECT reserved_amount, consumed_amount, released_amount, status
  INTO v_reserved, v_consumed, v_released, v_reservation_status
  FROM public.order_reservations
  WHERE order_id='81000000-0000-0000-0000-000000000011';

  IF v_reserved <> 1::numeric
     OR v_consumed <> 0.25::numeric
     OR v_released <> 0::numeric
     OR v_reservation_status <> 'reserved' THEN
    RAISE EXCEPTION 'Sell reservation after worker commit mismatch: %, %, %, %',
      v_reserved, v_consumed, v_released, v_reservation_status;
  END IF;

  SELECT count(*) INTO v_trade_count
  FROM public.trades
  WHERE order_id='81000000-0000-0000-0000-000000000011';

  SELECT count(*) INTO v_order_count
  FROM public.orders
  WHERE user_id='81000000-0000-0000-0000-000000000001';

  SELECT count(*) INTO v_reservation_count
  FROM public.order_reservations
  WHERE user_id='81000000-0000-0000-0000-000000000001';

  IF v_trade_count <> 1 OR v_order_count <> 1 OR v_reservation_count <> 1 THEN
    RAISE EXCEPTION 'Race created duplicate/extra records: trades %, orders %, reservations %',
      v_trade_count, v_order_count, v_reservation_count;
  END IF;

  IF v_inventory - (v_reserved - v_consumed - v_released) <> 0.5::numeric THEN
    RAISE EXCEPTION 'Free sell inventory after race is not the expected 0.5 BTC';
  END IF;
END
$verify$;
