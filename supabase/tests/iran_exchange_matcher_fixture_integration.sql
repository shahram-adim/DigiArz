\set ON_ERROR_STOP on
INSERT INTO public.crypto_assets(coingecko_id,symbol,name,is_active) VALUES
 ('bitcoin','BTC','Bitcoin',true),
 ('wrapped-bitcoin','BTC','Wrapped Bitcoin',true),
 ('ethereum','ETH','Ethereum',true),
 ('dogecoin','DOGE','Dogecoin',true),
 ('kishu-inu','KISHU','Kishu Inu',true);
INSERT INTO public.exchange_asset_observations(exchange,market_symbol,base_symbol,asset_name,source_payload,is_active) VALUES
 ('nobitex','BTC','BTC','Bitcoin','{}',true),
 ('wallex','ETHUSDT','ETH','Ethereum','{}',true),
 ('nobitex','DOGE','DOGE','Doge','{}',true),
 ('nobitex','NOPE','NOPE','Unknown Asset','{}',true),
 ('kifpool','KISHU','KISHU','Kishu','{"nameId":"kishu-inu"}',true),
 ('nobitex','INACTIVE','BTC','Bitcoin','{}',false);

-- Full-scan baseline snapshot.
SELECT private.match_iran_exchange_observations(NULL);
CREATE TEMP TABLE expected_initial AS
SELECT id,coingecko_id,match_status FROM public.exchange_asset_observations;
-- Rewind only matcher outputs, then prove the queued incremental pass matches baseline.
UPDATE public.exchange_asset_observations SET coingecko_id=NULL,match_status='pending';
SELECT private.process_iran_match_dirty_batch(1000);
DO $$
BEGIN
 IF EXISTS (
   SELECT 1 FROM expected_initial e JOIN public.exchange_asset_observations o USING(id)
   WHERE e.coingecko_id IS DISTINCT FROM o.coingecko_id
      OR e.match_status IS DISTINCT FROM o.match_status
 ) THEN RAISE EXCEPTION 'Initial incremental result differs from full-scan baseline'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='BTC') <> 'ambiguous'
 THEN RAISE EXCEPTION 'Ambiguous BTC candidates were not preserved'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='ETHUSDT') <> 'matched'
 THEN RAISE EXCEPTION 'Exact ETH match failed'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='DOGE') <> 'pending'
 THEN RAISE EXCEPTION 'Short non-exact Doge name should remain pending'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='NOPE') <> 'unmatched'
 THEN RAISE EXCEPTION 'No-symbol observation should be unmatched'; END IF;
 IF (SELECT coingecko_id FROM public.exchange_asset_observations WHERE exchange='kifpool') <> 'kishu-inu'
 THEN RAISE EXCEPTION 'Verified Kifpool legacy alias was not preserved'; END IF;
 IF (SELECT match_status FROM public.exchange_asset_observations WHERE market_symbol='INACTIVE') <> 'pending'
 THEN RAISE EXCEPTION 'Inactive observation should not be rewritten'; END IF;
END $$;

-- Heartbeat-only changes must not enqueue work.
TRUNCATE private.iran_exchange_match_dirty;
UPDATE public.exchange_asset_observations SET last_seen_at=now()+interval '1 second'
WHERE market_symbol='ETHUSDT';
DO $$ BEGIN
 IF (SELECT count(*) FROM private.iran_exchange_match_dirty)<>0
 THEN RAISE EXCEPTION 'last_seen_at-only update incorrectly dirtied a row'; END IF;
END $$;

-- A match-input change must enqueue only the affected observation.
UPDATE public.exchange_asset_observations SET asset_name='Ether'
WHERE market_symbol='ETHUSDT';
DO $$ BEGIN
 IF (SELECT count(*) FROM private.iran_exchange_match_dirty)<>1
 THEN RAISE EXCEPTION 'Expected exactly one dirty observation after asset_name change'; END IF;
END $$;

-- Capture the full-scan answer for the changed row, rewind that row, then compare incremental.
SELECT private.match_iran_exchange_observations(NULL);
CREATE TEMP TABLE expected_changed AS
SELECT id,coingecko_id,match_status FROM public.exchange_asset_observations
WHERE market_symbol='ETHUSDT';
UPDATE public.exchange_asset_observations SET coingecko_id=NULL,match_status='pending'
WHERE market_symbol='ETHUSDT';
SELECT private.process_iran_match_dirty_batch(100);
DO $$
BEGIN
 IF EXISTS (
   SELECT 1 FROM expected_changed e JOIN public.exchange_asset_observations o USING(id)
   WHERE e.coingecko_id IS DISTINCT FROM o.coingecko_id
      OR e.match_status IS DISTINCT FROM o.match_status
 ) THEN RAISE EXCEPTION 'Changed-row incremental result differs from full-scan baseline'; END IF;
 IF (SELECT count(*) FROM private.iran_exchange_match_dirty)<>0
 THEN RAISE EXCEPTION 'Dirty queue was not drained'; END IF;
END $$;

SELECT 'Iran exchange matcher fixture tests passed' AS result;
