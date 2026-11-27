-- RECOVERED HISTORICAL PRODUCTION MIGRATION SOURCE
-- Migration version: 20261121045531
-- Name: snapshot_pg_net_unlogged_queue_before_recovery
-- Source: Production supabase_migrations.schema_migrations.statements (read-only retrieval, 2026-11-25).
-- STATUS: REVIEW-ONLY / HISTORICAL REFERENCE. NOT AN EXECUTABLE MIGRATION.
-- This file is intentionally under supabase/drafts/, not supabase/migrations/.
-- Do NOT run, replay, or copy into a migration directory without separate review
-- and explicit owner approval. This migration is already recorded as applied in Production.


CREATE TABLE private.digiarz_pg_net_queue_backup_20261121 AS
SELECT clock_timestamp() AS captured_at, q.*
FROM net.http_request_queue q;

CREATE TABLE private.digiarz_pg_net_response_backup_20261121 AS
SELECT clock_timestamp() AS captured_at, r.*
FROM net._http_response r;
