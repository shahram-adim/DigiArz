-- Return reservation ledger values as decimal text so browser code never
-- rounds asset quantities through IEEE-754 Number.
CREATE OR REPLACE FUNCTION public.get_my_order_reservations_exact(p_order_ids uuid[])
RETURNS TABLE (
  order_id uuid,
  asset text,
  reserved_amount_text text,
  consumed_amount_text text,
  released_amount_text text,
  status text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
  SELECT
    r.order_id,
    r.asset,
    r.reserved_amount::text,
    r.consumed_amount::text,
    r.released_amount::text,
    r.status
  FROM public.order_reservations AS r
  WHERE (SELECT auth.uid()) IS NOT NULL
    AND r.user_id = (SELECT auth.uid())
    AND p_order_ids IS NOT NULL
    AND cardinality(p_order_ids) BETWEEN 1 AND 100
    AND r.order_id = ANY(p_order_ids);
$function$;

REVOKE ALL ON FUNCTION public.get_my_order_reservations_exact(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_order_reservations_exact(uuid[]) TO authenticated, service_role;

COMMENT ON FUNCTION public.get_my_order_reservations_exact(uuid[]) IS
  'Returns only the caller-owned order reservations with exact decimal values serialized as text.';
