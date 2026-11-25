-- DigiArz exchange_asset_observations catalog parity contract
-- Read-only: this file inspects catalogs only and raises on schema/ACL drift.
-- Baseline captured from Production on 2026-11-25.
-- This records current Production state; it does NOT endorse broad sequence grants.
-- Run only against an isolated database cloned from an approved Production snapshot.

DO $observations_catalog$
DECLARE
  table_oid oid;
  sequence_oid oid;
  actual_columns text[];
  expected_columns text[] := ARRAY[
    '1|id|bigint|t|<NULL>|a',
    '2|exchange|text|t|<NULL>|',
    '3|market_symbol|text|t|<NULL>|',
    '4|base_symbol|text|f|<NULL>|',
    '5|quote_symbol|text|f|<NULL>|',
    '6|asset_name|text|f|<NULL>|',
    '7|coingecko_id|text|f|<NULL>|',
    '8|match_status|text|t|''pending''::text|',
    '9|source_url|text|t|<NULL>|',
    '10|source_payload|jsonb|f|<NULL>|',
    '11|is_active|boolean|t|true|',
    '12|first_seen_at|timestamp with time zone|t|now()|',
    '13|last_seen_at|timestamp with time zone|t|now()|'
  ];
  actual_constraints text[];
  expected_constraints text[] := ARRAY[
    'exchange_asset_observations_coingecko_id_fkey|FOREIGN KEY (coingecko_id) REFERENCES crypto_assets(coingecko_id) ON UPDATE CASCADE ON DELETE SET NULL',
    'exchange_asset_observations_exchange_check|CHECK ((exchange = ANY (ARRAY[''nobitex''::text, ''wallex''::text, ''bitpin''::text, ''ramzinex''::text, ''tabdeal''::text, ''ompfinex''::text, ''exir''::text, ''bit24''::text, ''balinex''::text, ''abantether''::text, ''okex''::text, ''tetherland''::text, ''kifpool''::text])))',
    'exchange_asset_observations_exchange_market_symbol_key|UNIQUE (exchange, market_symbol)',
    'exchange_asset_observations_match_status_check|CHECK ((match_status = ANY (ARRAY[''pending''::text, ''matched''::text, ''ambiguous''::text, ''unmatched''::text])))',
    'exchange_asset_observations_pkey|PRIMARY KEY (id)'
  ];
  actual_indexes text[];
  expected_indexes text[] := ARRAY[
    'exchange_asset_observations_exchange_market_symbol_key|CREATE UNIQUE INDEX exchange_asset_observations_exchange_market_symbol_key ON public.exchange_asset_observations USING btree (exchange, market_symbol)',
    'exchange_asset_observations_match_idx|CREATE INDEX exchange_asset_observations_match_idx ON public.exchange_asset_observations USING btree (match_status, last_seen_at DESC)',
    'exchange_asset_observations_pkey|CREATE UNIQUE INDEX exchange_asset_observations_pkey ON public.exchange_asset_observations USING btree (id)',
    'exchange_asset_observations_symbol_idx|CREATE INDEX exchange_asset_observations_symbol_idx ON public.exchange_asset_observations USING btree (upper(base_symbol))'
  ];
  actual_table_acl text[];
  expected_table_acl text[] := ARRAY[
    'postgres|DELETE','postgres|INSERT','postgres|MAINTAIN','postgres|REFERENCES',
    'postgres|SELECT','postgres|TRIGGER','postgres|TRUNCATE','postgres|UPDATE',
    'service_role|DELETE','service_role|INSERT','service_role|MAINTAIN','service_role|REFERENCES',
    'service_role|SELECT','service_role|TRIGGER','service_role|TRUNCATE','service_role|UPDATE'
  ];
  actual_sequence_acl text[];
  expected_sequence_acl text[] := ARRAY[
    'anon|SELECT','anon|UPDATE','anon|USAGE',
    'authenticated|SELECT','authenticated|UPDATE','authenticated|USAGE',
    'postgres|SELECT','postgres|UPDATE','postgres|USAGE',
    'service_role|SELECT','service_role|UPDATE','service_role|USAGE'
  ];
  actual_triggers text[];
  expected_triggers text[] := ARRAY[
    'trg_auto_list_verified_exchange_asset|O|CREATE TRIGGER trg_auto_list_verified_exchange_asset AFTER INSERT OR UPDATE OF match_status, coingecko_id, is_active ON exchange_asset_observations FOR EACH ROW EXECUTE FUNCTION private.auto_list_verified_exchange_asset()'
  ];
  mismatch text;
BEGIN
  SELECT c.oid INTO table_oid
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relname = 'exchange_asset_observations'
    AND c.relkind = 'r';

  IF table_oid IS NULL THEN
    RAISE EXCEPTION 'Missing required table public.exchange_asset_observations';
  END IF;

  IF NOT (SELECT relrowsecurity AND NOT relforcerowsecurity
          FROM pg_class WHERE oid = table_oid) THEN
    RAISE EXCEPTION 'exchange_asset_observations RLS contract drift';
  END IF;

  SELECT array_agg(
    format('%s|%s|%s|%s|%s|%s',
      a.attnum, a.attname, format_type(a.atttypid,a.atttypmod),
      a.attnotnull, COALESCE(pg_get_expr(d.adbin,d.adrelid),'<NULL>'),
      a.attidentity
    ) ORDER BY a.attnum
  ) INTO actual_columns
  FROM pg_attribute a
  LEFT JOIN pg_attrdef d ON d.adrelid=a.attrelid AND d.adnum=a.attnum
  WHERE a.attrelid=table_oid AND a.attnum>0 AND NOT a.attisdropped;

  IF actual_columns IS DISTINCT FROM expected_columns THEN
    RAISE EXCEPTION 'exchange_asset_observations column contract drift; actual=%', actual_columns;
  END IF;

  SELECT array_agg(c.conname || '|' || pg_get_constraintdef(c.oid) ORDER BY c.conname)
    INTO actual_constraints
  FROM pg_constraint c WHERE c.conrelid=table_oid;

  IF actual_constraints IS DISTINCT FROM expected_constraints THEN
    RAISE EXCEPTION 'exchange_asset_observations constraint contract drift; actual=%', actual_constraints;
  END IF;

  SELECT array_agg(i.relname || '|' || pg_get_indexdef(x.indexrelid) ORDER BY i.relname)
    INTO actual_indexes
  FROM pg_index x
  JOIN pg_class i ON i.oid=x.indexrelid
  WHERE x.indrelid=table_oid AND x.indisvalid AND x.indisready;

  IF actual_indexes IS DISTINCT FROM expected_indexes THEN
    RAISE EXCEPTION 'exchange_asset_observations index contract drift; actual=%', actual_indexes;
  END IF;

  IF (SELECT count(*) FROM pg_policy WHERE polrelid=table_oid) <> 0 THEN
    RAISE EXCEPTION 'Unexpected RLS policy found on exchange_asset_observations';
  END IF;

  SELECT array_agg(
    CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE a.grantee::regrole::text END
      || '|' || a.privilege_type
    ORDER BY CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE a.grantee::regrole::text END,
             a.privilege_type
  ) INTO actual_table_acl
  FROM pg_class c,
       LATERAL aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) a
  WHERE c.oid=table_oid;

  IF actual_table_acl IS DISTINCT FROM expected_table_acl THEN
    RAISE EXCEPTION 'exchange_asset_observations table ACL drift; actual=%', actual_table_acl;
  END IF;

  IF has_table_privilege('anon',table_oid,'SELECT')
     OR has_table_privilege('anon',table_oid,'INSERT')
     OR has_table_privilege('anon',table_oid,'UPDATE')
     OR has_table_privilege('anon',table_oid,'DELETE')
     OR has_table_privilege('authenticated',table_oid,'SELECT')
     OR has_table_privilege('authenticated',table_oid,'INSERT')
     OR has_table_privilege('authenticated',table_oid,'UPDATE')
     OR has_table_privilege('authenticated',table_oid,'DELETE') THEN
    RAISE EXCEPTION 'anon/authenticated unexpectedly have direct table privileges';
  END IF;

  IF NOT (has_table_privilege('service_role',table_oid,'SELECT')
      AND has_table_privilege('service_role',table_oid,'INSERT')
      AND has_table_privilege('service_role',table_oid,'UPDATE')
      AND has_table_privilege('service_role',table_oid,'DELETE')) THEN
    RAISE EXCEPTION 'service_role table privileges are incomplete';
  END IF;

  sequence_oid := pg_get_serial_sequence('public.exchange_asset_observations','id')::regclass;
  IF sequence_oid IS NULL THEN
    RAISE EXCEPTION 'Missing identity sequence for exchange_asset_observations.id';
  END IF;

  SELECT array_agg(
    CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE a.grantee::regrole::text END
      || '|' || a.privilege_type
    ORDER BY CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE a.grantee::regrole::text END,
             a.privilege_type
  ) INTO actual_sequence_acl
  FROM pg_class c,
       LATERAL aclexplode(COALESCE(c.relacl,acldefault('S',c.relowner))) a
  WHERE c.oid=sequence_oid;

  IF actual_sequence_acl IS DISTINCT FROM expected_sequence_acl THEN
    RAISE EXCEPTION 'exchange_asset_observations sequence ACL drift; actual=%', actual_sequence_acl;
  END IF;

  SELECT array_agg(t.tgname || '|' || t.tgenabled || '|' || pg_get_triggerdef(t.oid,true)
                   ORDER BY t.tgname)
    INTO actual_triggers
  FROM pg_trigger t
  WHERE t.tgrelid=table_oid AND NOT t.tgisinternal;

  IF actual_triggers IS DISTINCT FROM expected_triggers THEN
    RAISE EXCEPTION 'exchange_asset_observations trigger contract drift; actual=%', actual_triggers;
  END IF;

  RAISE NOTICE 'PASS: exchange_asset_observations columns, constraints, indexes, RLS, ACLs, identity sequence and trigger match reviewed Production baseline';
END
$observations_catalog$;
