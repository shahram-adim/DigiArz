-- DRAFT ONLY — DO NOT APPLY TO PRODUCTION.
-- Exact-decimal type widening proposal for DigiArz.
-- Preconditions:
--   1) Isolated rehearsal with the complete candidate RPC chain has passed.
--   2) Current row values have been re-scanned immediately before rollout.
--   3) Explicit release approval has been obtained.
-- This file is intentionally under supabase/drafts, not supabase/migrations.
-- It is transactional and uses a short lock timeout; rehearse table rewrite/lock
-- behavior on PostgreSQL 17 before moving into the migration directory.

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

DO $preflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.orders
    WHERE amount IS NULL OR amount <= 0 OR amount > 1000000
       OR scale(amount) > 18 OR abs(price) >= 10000000000000000::numeric
       OR scale(price) > 18 OR abs(filled_amount) >= 10000000000000000::numeric
       OR scale(filled_amount) > 18
       OR abs(remaining_amount) >= 10000000000000000::numeric
       OR scale(remaining_amount) > 18
  ) THEN
    RAISE EXCEPTION 'orders contains values outside numeric(34,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.trades
    WHERE amount IS NULL OR amount <= 0 OR scale(amount) > 18
       OR abs(amount) >= 10000000000000000::numeric
       OR price IS NULL OR price <= 0 OR scale(price) > 18
       OR price >= 10000000000000000::numeric
  ) THEN
    RAISE EXCEPTION 'trades contains values outside numeric(34,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.asset_balances
    WHERE balance IS NULL OR balance < 0 OR scale(balance) > 18
       OR abs(balance) >= 100000000000000000000::numeric
  ) THEN
    RAISE EXCEPTION 'asset_balances contains values outside numeric(38,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.order_reservations
    WHERE reserved_amount IS NULL OR reserved_amount < 0 OR scale(reserved_amount) > 18
       OR abs(reserved_amount) >= 100000000000000000000::numeric
       OR released_amount IS NULL OR released_amount < 0 OR scale(released_amount) > 18
       OR abs(released_amount) >= 100000000000000000000::numeric
       OR consumed_amount IS NULL OR consumed_amount < 0 OR scale(consumed_amount) > 18
       OR abs(consumed_amount) >= 100000000000000000000::numeric
  ) THEN
    RAISE EXCEPTION 'order_reservations contains values outside numeric(38,18) contract';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.conditional_orders
    WHERE amount IS NULL OR amount <= 0 OR amount > 1000000 OR scale(amount) > 18
       OR trigger_price IS NULL OR trigger_price <= 0
       OR trigger_price >= 10000000000000000::numeric OR scale(trigger_price) > 18
       OR (limit_price IS NOT NULL AND
           (limit_price <= 0 OR limit_price >= 10000000000000000::numeric OR scale(limit_price) > 18))
       OR (executed_price IS NOT NULL AND
           (executed_price <= 0 OR executed_price >= 10000000000000000::numeric OR scale(executed_price) > 18))
  ) THEN
    RAISE EXCEPTION 'conditional_orders contains values outside numeric(34,18) contract';
  END IF;
END
$preflight$;

ALTER TABLE public.orders
  ALTER COLUMN amount TYPE numeric(34,18) USING amount::numeric(34,18),
  ALTER COLUMN price TYPE numeric(34,18) USING price::numeric(34,18),
  ALTER COLUMN filled_amount TYPE numeric(34,18) USING filled_amount::numeric(34,18),
  ALTER COLUMN remaining_amount TYPE numeric(34,18) USING remaining_amount::numeric(34,18);

ALTER TABLE public.trades
  ALTER COLUMN amount TYPE numeric(34,18) USING amount::numeric(34,18),
  ALTER COLUMN price TYPE numeric(34,18) USING price::numeric(34,18);

ALTER TABLE public.asset_balances
  ALTER COLUMN balance TYPE numeric(38,18) USING balance::numeric(38,18);

ALTER TABLE public.order_reservations
  ALTER COLUMN reserved_amount TYPE numeric(38,18) USING reserved_amount::numeric(38,18),
  ALTER COLUMN released_amount TYPE numeric(38,18) USING released_amount::numeric(38,18),
  ALTER COLUMN consumed_amount TYPE numeric(38,18) USING consumed_amount::numeric(38,18);

ALTER TABLE public.conditional_orders
  ALTER COLUMN amount TYPE numeric(34,18) USING amount::numeric(34,18),
  ALTER COLUMN trigger_price TYPE numeric(34,18) USING trigger_price::numeric(34,18),
  ALTER COLUMN limit_price TYPE numeric(34,18) USING limit_price::numeric(34,18),
  ALTER COLUMN executed_price TYPE numeric(34,18) USING executed_price::numeric(34,18);

COMMIT;
