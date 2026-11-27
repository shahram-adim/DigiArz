-- Negative fixture: pending TP/SL worker would consume more reservation than it sells.
UPDATE public.order_reservations
SET reserved_amount=0.4
WHERE order_id='10000000-0000-4000-8000-000000000002'
  AND user_id='20000000-0000-4000-8000-000000000001';
