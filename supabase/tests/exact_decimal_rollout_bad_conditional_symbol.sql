-- Negative fixture: conditional parent symbol must match its child record.
UPDATE public.orders
SET symbol='BTCUSDT'
WHERE id='10000000-0000-4000-8000-000000000002'
  AND user_id='20000000-0000-4000-8000-000000000001';
