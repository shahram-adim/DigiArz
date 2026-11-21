-- Stop indexing last_seen_at on the hot observation table.
-- The value is refreshed on every successful sync window; indexing it prevents
-- HOT updates and causes repeated heap/index churn. Keep the status filter fast
-- with a partial index that does not include last_seen_at.
CREATE INDEX IF NOT EXISTS exchange_asset_observations_match_status_active_idx
  ON public.exchange_asset_observations (match_status)
  WHERE is_active IS TRUE
    AND match_status IN ('pending', 'ambiguous', 'unmatched');

DROP INDEX IF EXISTS public.exchange_asset_observations_match_idx;

-- Reserve page space for HOT updates to last_seen_at and other non-indexed fields.
ALTER TABLE public.exchange_asset_observations
  SET (fillfactor = 50);
