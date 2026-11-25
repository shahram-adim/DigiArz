-- Disposable PostgreSQL 17 test only. Never run against Supabase Production.
-- Ten separate autocommit calls are intentional: the worker's advisory xact lock
-- must be released between retries.
CREATE OR REPLACE FUNCTION public.place_limit_order(
  p_symbol text, p_side text, p_amount numeric, p_limit_price numeric
)
RETURNS jsonb
LANGUAGE plpgsql
AS $sentinel$
BEGIN
  RAISE EXCEPTION 'unexpected place_limit_order call in invalid-reservation regression';
END
$sentinel$;

INSERT INTO public.profiles(id,is_active)
VALUES ('60000000-0000-0000-0000-000000000006',true);

INSERT INTO public.market_prices(symbol,price,updated_at)
VALUES ('BTCUSDT',11.000000000000000001,now());

INSERT INTO public.orders(
  id,user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount
) VALUES (
  '50000000-0000-0000-0000-000000000005',
  '60000000-0000-0000-0000-000000000006',
  'BTCUSDT','buy','conditional',
  1.000000000000000001,10.500000000000000000,
  'pending',0,1.000000000000000001
);

INSERT INTO public.conditional_orders(
  id,order_id,user_id,symbol,side,order_kind,trigger_price,limit_price,amount,status,attempt_count
) VALUES (
  '70000000-0000-0000-0000-000000000007',
  '50000000-0000-0000-0000-000000000005',
  '60000000-0000-0000-0000-000000000006',
  'BTCUSDT','buy','stop_limit',
  10.000000000000000000,10.500000000000000000,
  1.000000000000000001,'pending',0
);

-- Deliberately invalid reservation fixture: released status with unchanged amounts.
-- The worker must fail closed and must not "repair" or release this row.
INSERT INTO public.order_reservations(
  id,order_id,user_id,asset,reserved_amount,released_amount,consumed_amount,status
) VALUES (
  '80000000-0000-0000-0000-000000000008',
  '50000000-0000-0000-0000-000000000005',
  '60000000-0000-0000-0000-000000000006',
  'USDT',10.510000000000000000,0,0,'released'
);

SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();
SELECT public.process_stop_limit_orders();

DO $assert$
BEGIN
  IF (SELECT attempt_count FROM public.conditional_orders
      WHERE id='70000000-0000-0000-0000-000000000007') <> 10 THEN
    RAISE EXCEPTION 'expected exactly ten invalid-reservation attempts';
  END IF;

  IF (SELECT status FROM public.conditional_orders
      WHERE id='70000000-0000-0000-0000-000000000007') <> 'rejected' THEN
    RAISE EXCEPTION 'conditional order did not fail closed after ten attempts';
  END IF;

  IF (SELECT last_error FROM public.conditional_orders
      WHERE id='70000000-0000-0000-0000-000000000007')
      <> 'Reservation validation failed; manual review required' THEN
    RAISE EXCEPTION 'operator-review reason was not retained';
  END IF;

  IF (SELECT status FROM public.orders
      WHERE id='50000000-0000-0000-0000-000000000005') <> 'rejected' THEN
    RAISE EXCEPTION 'parent order did not reach rejected state';
  END IF;

  IF (SELECT execution_order_id FROM public.conditional_orders
      WHERE id='70000000-0000-0000-0000-000000000007') IS NOT NULL THEN
    RAISE EXCEPTION 'invalid reservation unexpectedly created a child order';
  END IF;

  IF (SELECT count(*) FROM public.orders) <> 1 THEN
    RAISE EXCEPTION 'unexpected child or extra order was created';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.order_reservations
    WHERE id='80000000-0000-0000-0000-000000000008'
      AND status='released'
      AND reserved_amount=10.510000000000000000
      AND released_amount=0
      AND consumed_amount=0
  ) THEN
    RAISE EXCEPTION 'invalid reservation was modified during fail-closed handling';
  END IF;
END
$assert$;

SELECT 'Captured Production Stop-Limit invalid-reservation retry: PASS' AS result;
