-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261121050216
-- Name: temporarily_throttle_exchange_asset_processors_20261121
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.

select cron.alter_job(14, schedule := '1,31 * * * *');
select cron.alter_job(16, schedule := '16,46 * * * *');