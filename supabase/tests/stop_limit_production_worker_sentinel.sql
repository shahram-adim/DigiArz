-- Disposable test sentinel only. It must fail if the invalid-reservation path
-- ever attempts to create a child Limit order.
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
