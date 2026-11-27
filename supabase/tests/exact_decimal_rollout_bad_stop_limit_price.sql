-- Negative fixture: Stop-Limit parent price must match conditional limit_price.
UPDATE public.orders
SET price=11.76
WHERE id='10000000-0000-4000-8000-000000000002'
  AND user_id='20000000-0000-4000-8000-000000000001';
UPDATE public.conditional_orders
SET order_kind='stop_limit', limit_price=11.75
WHERE order_id='10000000-0000-4000-8000-000000000002'
  AND user_id='20000000-0000-4000-8000-000000000001';
