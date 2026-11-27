-- Disposable bootstrap only for syntax-checking the read-only canonical schema fingerprint.
-- Contains roles and pg_cron-shaped metadata only; no application or user rows.
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
END
$roles$;
CREATE SCHEMA cron;
CREATE TABLE cron.job (
  jobid bigint PRIMARY KEY,
  jobname text NOT NULL,
  schedule text NOT NULL,
  command text NOT NULL
);
