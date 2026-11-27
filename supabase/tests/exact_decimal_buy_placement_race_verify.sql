-- Exactly one of two competing buys may reserve the same wallet funds.
DO $verify$
DECLARE
  v_wallet numeric;
  v_reserved numeric;
  v_orders integer;
  v_reservations integer;
  v_pending integer;
BEGIN
  SELECT balance_usdt INTO v_wallet
  FROM public.wallets
  WHERE user_id='82000000-0000-0000-0000-000000000001';

  SELECT COALESCE(sum(reserved_amount-consumed_amount-released_amount),0)
  INTO v_reserved
  FROM public.order_reservations
  WHERE user_id='82000000-0000-0000-0000-000000000001'
    AND asset='USDT' AND status='reserved';

  SELECT count(*),count(*) FILTER (WHERE status='pending')
  INTO v_orders,v_pending
  FROM public.orders
  WHERE user_id='82000000-0000-0000-0000-000000000001';

  SELECT count(*) INTO v_reservations
  FROM public.order_reservations
  WHERE user_id='82000000-0000-0000-0000-000000000001';

  IF v_wallet<>10::numeric THEN
    RAISE EXCEPTION 'Placement race changed wallet balance: %',v_wallet;
  END IF;
  IF v_reserved<>6.0060001::numeric THEN
    RAISE EXCEPTION 'Expected exactly one 6.0060001 USDT reservation including the documented rounding buffer, got %',v_reserved;
  END IF;
  IF v_orders<>1 OR v_pending<>1 OR v_reservations<>1 THEN
    RAISE EXCEPTION 'Duplicate/partial placement state: orders %, pending %, reservations %',
      v_orders,v_pending,v_reservations;
  END IF;
  IF v_wallet-v_reserved<0 OR v_wallet-v_reserved<>3.9939999::numeric THEN
    RAISE EXCEPTION 'Available USDT after race is inconsistent: %',v_wallet-v_reserved;
  END IF;
END
$verify$;
