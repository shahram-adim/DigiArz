\set ON_ERROR_STOP on
CREATE TEMP TABLE crypto_assets_fixture (
 coingecko_id text PRIMARY KEY, symbol text, name text, image_url text, market_cap_rank integer,
 current_price_usd numeric, price_toman numeric, price_change_percentage_24h numeric,
 market_cap_usd numeric, total_volume_usd numeric, last_updated timestamptz,
 is_active boolean, updated_at timestamptz
);
CREATE TEMP TABLE crypto_assets_update_audit (coingecko_id text);
CREATE FUNCTION pg_temp.audit_crypto_asset_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN INSERT INTO pg_temp.crypto_assets_update_audit VALUES (NEW.coingecko_id); RETURN NEW; END $$;
CREATE TRIGGER crypto_assets_audit AFTER UPDATE ON crypto_assets_fixture
FOR EACH ROW EXECUTE FUNCTION pg_temp.audit_crypto_asset_update();
INSERT INTO crypto_assets_fixture VALUES
('bitcoin','BTC','Bitcoin','img',1,50000,5000000000,1.5,1000000000000,1000000000,
 '2026-11-20 00:00:00+00',true,'2026-11-20 00:00:00+00');

-- Identical row: zero physical updates.
INSERT INTO crypto_assets_fixture AS c VALUES
('bitcoin','BTC','Bitcoin','img',1,50000,5000000000,1.5,1000000000000,1000000000,
 '2026-11-20 00:00:00+00',true,clock_timestamp())
ON CONFLICT (coingecko_id) DO UPDATE SET
 symbol=EXCLUDED.symbol,name=EXCLUDED.name,image_url=EXCLUDED.image_url,
 market_cap_rank=EXCLUDED.market_cap_rank,current_price_usd=EXCLUDED.current_price_usd,
 price_toman=COALESCE(EXCLUDED.price_toman,c.price_toman),
 price_change_percentage_24h=EXCLUDED.price_change_percentage_24h,
 market_cap_usd=EXCLUDED.market_cap_usd,total_volume_usd=EXCLUDED.total_volume_usd,
 last_updated=EXCLUDED.last_updated,is_active=true,updated_at=clock_timestamp()
WHERE (c.symbol,c.name,c.image_url,c.market_cap_rank,c.current_price_usd,c.price_toman,
 c.price_change_percentage_24h,c.market_cap_usd,c.total_volume_usd,c.last_updated,c.is_active)
IS DISTINCT FROM
(EXCLUDED.symbol,EXCLUDED.name,EXCLUDED.image_url,EXCLUDED.market_cap_rank,EXCLUDED.current_price_usd,
 COALESCE(EXCLUDED.price_toman,c.price_toman),EXCLUDED.price_change_percentage_24h,
 EXCLUDED.market_cap_usd,EXCLUDED.total_volume_usd,EXCLUDED.last_updated,true);
DO $$ BEGIN
 IF (SELECT count(*) FROM crypto_assets_update_audit)<>0 THEN RAISE EXCEPTION 'identical row updated'; END IF;
END $$;

-- NULL incoming Toman must preserve the current Toman value and remain a no-op.
INSERT INTO crypto_assets_fixture AS c VALUES
('bitcoin','BTC','Bitcoin','img',1,50000,NULL,1.5,1000000000000,1000000000,
 '2026-11-20 00:00:00+00',true,clock_timestamp())
ON CONFLICT (coingecko_id) DO UPDATE SET
 symbol=EXCLUDED.symbol,name=EXCLUDED.name,image_url=EXCLUDED.image_url,
 market_cap_rank=EXCLUDED.market_cap_rank,current_price_usd=EXCLUDED.current_price_usd,
 price_toman=COALESCE(EXCLUDED.price_toman,c.price_toman),
 price_change_percentage_24h=EXCLUDED.price_change_percentage_24h,
 market_cap_usd=EXCLUDED.market_cap_usd,total_volume_usd=EXCLUDED.total_volume_usd,
 last_updated=EXCLUDED.last_updated,is_active=true,updated_at=clock_timestamp()
WHERE (c.symbol,c.name,c.image_url,c.market_cap_rank,c.current_price_usd,c.price_toman,
 c.price_change_percentage_24h,c.market_cap_usd,c.total_volume_usd,c.last_updated,c.is_active)
IS DISTINCT FROM
(EXCLUDED.symbol,EXCLUDED.name,EXCLUDED.image_url,EXCLUDED.market_cap_rank,EXCLUDED.current_price_usd,
 COALESCE(EXCLUDED.price_toman,c.price_toman),EXCLUDED.price_change_percentage_24h,
 EXCLUDED.market_cap_usd,EXCLUDED.total_volume_usd,EXCLUDED.last_updated,true);
DO $$ BEGIN
 IF (SELECT count(*) FROM crypto_assets_update_audit)<>0 THEN RAISE EXCEPTION 'NULL Toman changed row'; END IF;
 IF (SELECT price_toman FROM crypto_assets_fixture WHERE coingecko_id='bitcoin')<>5000000000 THEN
 RAISE EXCEPTION 'existing Toman value not preserved'; END IF;
END $$;

-- Real price change must still update exactly once.
INSERT INTO crypto_assets_fixture AS c VALUES
('bitcoin','BTC','Bitcoin','img',1,51000,5100000000,1.8,1010000000000,1100000000,
 '2026-11-20 00:10:00+00',true,clock_timestamp())
ON CONFLICT (coingecko_id) DO UPDATE SET
 symbol=EXCLUDED.symbol,name=EXCLUDED.name,image_url=EXCLUDED.image_url,
 market_cap_rank=EXCLUDED.market_cap_rank,current_price_usd=EXCLUDED.current_price_usd,
 price_toman=COALESCE(EXCLUDED.price_toman,c.price_toman),
 price_change_percentage_24h=EXCLUDED.price_change_percentage_24h,
 market_cap_usd=EXCLUDED.market_cap_usd,total_volume_usd=EXCLUDED.total_volume_usd,
 last_updated=EXCLUDED.last_updated,is_active=true,updated_at=clock_timestamp()
WHERE (c.symbol,c.name,c.image_url,c.market_cap_rank,c.current_price_usd,c.price_toman,
 c.price_change_percentage_24h,c.market_cap_usd,c.total_volume_usd,c.last_updated,c.is_active)
IS DISTINCT FROM
(EXCLUDED.symbol,EXCLUDED.name,EXCLUDED.image_url,EXCLUDED.market_cap_rank,EXCLUDED.current_price_usd,
 COALESCE(EXCLUDED.price_toman,c.price_toman),EXCLUDED.price_change_percentage_24h,
 EXCLUDED.market_cap_usd,EXCLUDED.total_volume_usd,EXCLUDED.last_updated,true);
DO $$ BEGIN
 IF (SELECT count(*) FROM crypto_assets_update_audit)<>1 THEN RAISE EXCEPTION 'real update not applied'; END IF;
 IF (SELECT current_price_usd FROM crypto_assets_fixture WHERE coingecko_id='bitcoin')<>51000 THEN
 RAISE EXCEPTION 'new USD price not applied'; END IF;
END $$;
SELECT 'crypto_assets no-op upsert fixture passed' AS result;
