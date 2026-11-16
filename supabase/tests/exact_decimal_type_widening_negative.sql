-- Negative preflight fixture: the widening migration must reject an out-of-contract order.
-- Supply all required fields so the row reaches the migration's numeric preflight check.
INSERT INTO public.orders(user_id,symbol,side,order_type,amount,price,filled_amount,remaining_amount)
VALUES (
  '20000000-0000-4000-8000-000000000001',
  'BTCUSDT',
  'buy',
  'limit',
  1000001,
  10,
  0,
  1000001
);
