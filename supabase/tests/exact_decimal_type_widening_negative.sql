-- Negative preflight fixture: the widening migration must reject an out-of-contract order.
INSERT INTO public.orders(order_type,amount,price,filled_amount,remaining_amount)
VALUES ('limit',1000001,10,0,1000001);
