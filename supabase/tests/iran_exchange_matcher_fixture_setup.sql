-- Disposable PostgreSQL fixture only. This is a deliberately minimal test schema,
-- NOT a recovered copy of the missing Production table-creation migration.
CREATE SCHEMA IF NOT EXISTS private;
CREATE TABLE public.crypto_assets (
  coingecko_id text PRIMARY KEY,
  symbol text NOT NULL,
  name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.exchange_asset_observations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  exchange text NOT NULL,
  market_symbol text NOT NULL,
  base_symbol text NOT NULL,
  asset_name text,
  source_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  coingecko_id text,
  match_status text NOT NULL DEFAULT 'pending',
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(exchange, market_symbol)
);
CREATE TABLE private.iran_exchange_match_dirty (
  observation_id bigint PRIMARY KEY REFERENCES public.exchange_asset_observations(id) ON DELETE CASCADE,
  queued_at timestamptz NOT NULL DEFAULT now()
);
-- Complete verified Kifpool alias tuple list copied from the current main-branch matcher.
-- These are normalized name triples; symbol equality and active-state checks still apply.
CREATE TABLE private.test_verified_kifpool_aliases (
  coingecko_id text NOT NULL,
  legacy_name text NOT NULL,
  current_name text NOT NULL,
  PRIMARY KEY(coingecko_id, legacy_name, current_name)
);
INSERT INTO private.test_verified_kifpool_aliases VALUES
 ('adex','adex','heyaura'),
 ('crypto-com-chain','cryptocomcoin','cronos'),
 ('elrond-erd-2','elrond','multiversx'),
 ('blockstack','blockstack','stacks'),
 ('the-open-network','gram','gramprevtoncoin'),
 ('frax','frax','legacyfraxdollar'),
 ('kishu-inu','kishu','kishuinu'),
 ('centrifuge','centrifuge','centrifugeold'),
 ('jupiter','jupiter','jupiterproject'),
 ('apriori','apriori','capricorn'),
 ('avantis','avantis','veranta'),
 ('assemble-protocol','assembleprotocol','assembleai'),
 ('certik','certik','shentu'),
 ('everdome','everdome','humainweb3'),
 ('ankr','ankr','ankrnetwork'),
 ('band-protocol','bandprotocol','band'),
 ('binancecoin','binancecoin','bnb'),
 ('superfarm','superfarm','superverse'),
 ('busy-dao','busydao','busy'),
 ('dtec-token','dtec','dtectoken'),
 ('dusk-network','dusknetwork','dusk'),
 ('farcana','farcana','farlabs'),
 ('ftx-token','ftxtoken','ftx'),
 ('gme','gmeonsol','gme'),
 ('gamee','gmee','gamee'),
 ('stepn','stepn','gmt'),
 ('mx-token','mxtoken','mx'),
 ('nodecoin','nodecoin','nodepay'),
 ('near','near','nearprotocol'),
 ('apenft','apenft','ainft'),
 ('noot-noot','noot','nootnoot'),
 ('origin-protocol','originprotocol','origintoken'),
 ('ondo-finance','ondofinance','ondo'),
 ('subsquid','subsquid','sqd'),
 ('tokocrypto','tokotoken','tokocrypto'),
 ('usd-coin','usdcoin','usdc'),
 ('vapor-wallet','vaporwallet','vaporfund'),
 ('zignaly','zignaly','zigfinance'),
 ('0x','0x','0xprotocol');

-- The production matcher also has a distinct source-ID transition for ARPA.
CREATE TABLE private.test_verified_kifpool_legacy_ids (
  source_id text NOT NULL,
  coingecko_id text NOT NULL,
  legacy_name text NOT NULL,
  current_name text NOT NULL,
  PRIMARY KEY(source_id, coingecko_id)
);
INSERT INTO private.test_verified_kifpool_legacy_ids VALUES
 ('arpa-chain','arpa','arpachain','arpa');

CREATE OR REPLACE FUNCTION private.mark_iran_observation_match_dirty()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $$
DECLARE
  v_changed boolean;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_changed := true;
  ELSE
    v_changed :=
      OLD.exchange IS DISTINCT FROM NEW.exchange OR
      OLD.base_symbol IS DISTINCT FROM NEW.base_symbol OR
      OLD.asset_name IS DISTINCT FROM NEW.asset_name OR
      OLD.is_active IS DISTINCT FROM NEW.is_active OR
      (OLD.source_payload->>'nameId') IS DISTINCT FROM (NEW.source_payload->>'nameId');
  END IF;
  IF v_changed THEN
    INSERT INTO private.iran_exchange_match_dirty(observation_id, queued_at)
    VALUES (NEW.id, now())
    ON CONFLICT (observation_id) DO UPDATE SET queued_at = EXCLUDED.queued_at;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER iran_observation_match_dirty
AFTER INSERT OR UPDATE OF exchange, base_symbol, asset_name, is_active, source_payload
ON public.exchange_asset_observations
FOR EACH ROW EXECUTE FUNCTION private.mark_iran_observation_match_dirty();

CREATE OR REPLACE FUNCTION private.match_iran_exchange_observations(p_ids bigint[] DEFAULT NULL)
RETURNS integer LANGUAGE plpgsql SET search_path TO '' AS $$
DECLARE v_count integer;
BEGIN
  WITH kifpool_exact AS (
    SELECT o.id, ca.coingecko_id
    FROM public.exchange_asset_observations o
    JOIN public.crypto_assets ca
      ON ca.is_active IS TRUE
     AND upper(ca.symbol)=upper(o.base_symbol)
     AND (
       (ca.coingecko_id=o.source_payload->>'nameId'
        AND (
          regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
          OR EXISTS (
            SELECT 1 FROM private.test_verified_kifpool_aliases a
            WHERE a.coingecko_id=ca.coingecko_id
              AND a.legacy_name=regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')
              AND a.current_name=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
          )
        ))
       OR EXISTS (
         SELECT 1 FROM private.test_verified_kifpool_legacy_ids l
         WHERE l.source_id=o.source_payload->>'nameId'
           AND l.coingecko_id=ca.coingecko_id
           AND l.legacy_name=regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')
           AND l.current_name=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
       )
     )
    WHERE o.exchange='kifpool' AND o.is_active IS TRUE
      AND o.asset_name IS NOT NULL AND nullif(o.source_payload->>'nameId','') IS NOT NULL
      AND (p_ids IS NULL OR o.id=ANY(p_ids))
  ),
  ordinary_candidates AS (
    SELECT o.id, ca.coingecko_id,
      count(ca.coingecko_id) OVER (PARTITION BY o.id) candidate_count
    FROM public.exchange_asset_observations o
    JOIN public.crypto_assets ca
      ON upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL
      AND (p_ids IS NULL OR o.id=ANY(p_ids))
      AND (o.exchange<>'kifpool' OR NOT EXISTS(SELECT 1 FROM kifpool_exact k WHERE k.id=o.id))
      AND (
        (o.exchange='kifpool'
          AND EXISTS (
            SELECT 1 FROM public.crypto_assets exact_ca
            WHERE upper(exact_ca.symbol)=upper(o.base_symbol)
              AND exact_ca.is_active IS TRUE
              AND regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(exact_ca.name),'[^a-z0-9]','','g')
          )
          AND regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g'))
        OR
        (NOT (o.exchange='kifpool'
          AND EXISTS (
            SELECT 1 FROM public.crypto_assets exact_ca
            WHERE upper(exact_ca.symbol)=upper(o.base_symbol)
              AND exact_ca.is_active IS TRUE
              AND regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(exact_ca.name),'[^a-z0-9]','','g')
          ))
          AND (
            regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
            OR (length(regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g'))>=5
              AND length(regexp_replace(lower(ca.name),'[^a-z0-9]','','g'))>=5
              AND (regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g') LIKE '%'||regexp_replace(lower(ca.name),'[^a-z0-9]','','g')||'%'
                OR regexp_replace(lower(ca.name),'[^a-z0-9]','','g') LIKE '%'||regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')||'%'))
          ))
      )
  ),
  all_candidates AS (
    SELECT id, coingecko_id, 1::bigint candidate_count FROM kifpool_exact
    UNION ALL
    SELECT id, coingecko_id, candidate_count FROM ordinary_candidates
  ),
  chosen AS (
    SELECT id,
      min(coingecko_id) FILTER (WHERE candidate_count=1) coingecko_id,
      max(candidate_count) candidate_count
    FROM all_candidates GROUP BY id
  )
  UPDATE public.exchange_asset_observations o
  SET coingecko_id=c.coingecko_id,
      match_status=CASE WHEN c.candidate_count=1 THEN 'matched'
                        WHEN c.candidate_count>1 THEN 'ambiguous'
                        ELSE 'pending' END
  FROM chosen c
  WHERE o.id=c.id AND (p_ids IS NULL OR o.id=ANY(p_ids));

  UPDATE public.exchange_asset_observations o
  SET coingecko_id=NULL, match_status='unmatched'
  WHERE o.is_active IS TRUE AND o.asset_name IS NOT NULL
    AND (p_ids IS NULL OR o.id=ANY(p_ids))
    AND NOT EXISTS (
      SELECT 1 FROM public.crypto_assets ca
      WHERE upper(ca.symbol)=upper(o.base_symbol) AND ca.is_active IS TRUE
    )
    AND NOT (o.exchange='kifpool' AND EXISTS (
      SELECT 1 FROM public.crypto_assets ca
      WHERE ca.coingecko_id=o.source_payload->>'nameId' AND ca.is_active IS TRUE
        AND regexp_replace(lower(o.asset_name),'[^a-z0-9]','','g')=regexp_replace(lower(ca.name),'[^a-z0-9]','','g')
    ));

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION private.process_iran_match_dirty_batch(p_limit integer DEFAULT 100)
RETURNS integer LANGUAGE plpgsql SET search_path TO '' AS $$
DECLARE v_ids bigint[]; v_count integer;
BEGIN
  IF p_limit < 1 OR p_limit > 1000 THEN
    RAISE EXCEPTION 'p_limit must be between 1 and 1000';
  END IF;
  WITH claimed AS (
    SELECT observation_id
    FROM private.iran_exchange_match_dirty
    ORDER BY queued_at, observation_id
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  )
  SELECT array_agg(observation_id) INTO v_ids FROM claimed;

  IF coalesce(cardinality(v_ids),0)=0 THEN RETURN 0; END IF;
  v_count := private.match_iran_exchange_observations(v_ids);
  DELETE FROM private.iran_exchange_match_dirty WHERE observation_id=ANY(v_ids);
  RETURN cardinality(v_ids);
END;
$$;
