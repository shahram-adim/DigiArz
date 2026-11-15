-- Disposable PostgreSQL test: force a DDL error after the first widening ALTER.
-- The psql connection must exit with an error, rolling back the open transaction.
BEGIN;
ALTER TABLE public.orders
  ALTER COLUMN amount TYPE numeric(34,18)
  USING amount::numeric(34,18);
ALTER TABLE public.__digiarz_intentionally_missing_table__
  ALTER COLUMN amount TYPE numeric(34,18);
COMMIT;
