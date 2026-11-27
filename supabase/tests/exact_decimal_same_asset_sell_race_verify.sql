-- Exactly one of two concurrent sells may reserve the same BTC inventory.
DO $verify$
DECLARE
  v_wallet numeric;
  v_inventory numeric;
  v_reserved numeric;
  v_orders integer;
  v_pending integer;
  v_reservations integer;
BEGIN
  SELECT balance_usdt INTO v_wallet
  FROM public.wallets
  WHERE user_id='83000000-0000-0000-0000-000000000001';

  SELECT balance INTO v_inventory
  FROM public.asset_balances
  WHERE user_id='83000000-0000-0000-0000-000000000001' AND asset='BTC';

  SELECT COALESCE(sum(reserved_amount-consumed_amount-released_amount),0)
  INTO v_reserved
  FROM public.order_reservations
  WHERE user_id='83000000-0000-0000-0000-000000000001'
    AND asset='BTC' AND status='reserved';

  SELECT count(*),count(*) FILTER (WHERE status='pending')
  INTO v_orders,v_pending
  FROM public.orders
  WHERE user_id='83000000-0000-0000-0000-000000000001';

  SELECT count(*) INTO v_reservations
  FROM public.order_reservations
  WHERE user_id='83000000-0000-0000-0000-000000000001';

  IF v_wallet<>100::numeric THEN
    RAISE EXCEPTION 'Sell placement race changed wallet balance: %',v_wallet;
  END IF;
  IF v_inventory<>1::numeric THEN
    RAISE EXCEPTION 'Sell placement race changed inventory balance: %',v_inventory;
  END IF;
  IF v_reserved<>0.6::numeric THEN
    RAISE EXCEPTION 'Expected exactly 0.6 BTC reserved, got %',v_reserved;
  END IF;
  IF v_orders<>1 OR v_pending<>1 OR v_reservations<>1 THEN
    RAISE EXCEPTION 'Duplicate/partial placement state: orders %, pending %, reservations %',
      v_orders,v_pending,v_reservations;
  END IF;
  IF v_inventory-v_reserved<>0.4::numeric THEN
    RAISE EXCEPTION 'Available BTC after race is inconsistent: %',v_inventory-v_reserved;
  END IF;
END
$verify$;
