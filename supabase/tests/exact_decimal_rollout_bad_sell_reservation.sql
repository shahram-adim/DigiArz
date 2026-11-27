-- Negative fixture: active sell Limit order has less reserved base asset than remaining.
INSERT INTO public.orders(
  id,user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount
) VALUES (
  '10000000-0000-4000-8000-000000000003',
  '20000000-0000-4000-8000-000000000001',
  'BTCUSDT','sell','limit',1,10,'pending',0,1
);
INSERT INTO public.order_reservations(
  order_id,user_id,asset,reserved_amount,released_amount,consumed_amount
) VALUES (
  '10000000-0000-4000-8000-000000000003',
  '20000000-0000-4000-8000-000000000001',
  'BTC',0.5,0,0
);
