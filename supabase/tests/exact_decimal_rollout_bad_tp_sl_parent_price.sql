-- Negative fixture: TP/SL parent order price must equal the trigger price.
UPDATE public.orders
SET price=12.24
WHERE id='10000000-0000-4000-8000-000000000002'
  AND user_id='20000000-0000-4000-8000-000000000001';
