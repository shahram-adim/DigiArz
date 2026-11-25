'use strict';

const fs = require('node:fs');

const manifest = JSON.parse(fs.readFileSync('supabase/audit/production_security_definer_manifest_2026-11-25.json', 'utf8'));
const matrix = JSON.parse(fs.readFileSync('supabase/audit/production_rpc_role_matrix_2026-11-25.json', 'utf8'));
const roles = ['anon', 'authenticated', 'service_role'];

if (manifest.functions.length !== 46 || matrix.functions.length !== 46) {
  throw new Error('Expected exactly 46 Production function snapshots.');
}

const sourceByIdentity = new Map(manifest.functions.map(fn => [
  fn.schema_name + '.' + fn.function_name + '(' + fn.identity_arguments + ')', fn
]));
if (sourceByIdentity.size !== 46) throw new Error('Production manifest identities are not unique.');

const statements = [
  '-- Disposable ACL semantics fixture generated from the captured Production snapshot.',
  '-- This does NOT connect to or mutate Production and does NOT execute captured function bodies.',
  "DO $$ BEGIN",
  "  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN EXECUTE 'CREATE ROLE anon NOLOGIN'; END IF;",
  "  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN EXECUTE 'CREATE ROLE authenticated NOLOGIN'; END IF;",
  "  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN EXECUTE 'CREATE ROLE service_role NOLOGIN'; END IF;",
  'END $$;',
  'CREATE SCHEMA IF NOT EXISTS private;',
  "ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;",
  "ALTER DEFAULT PRIVILEGES IN SCHEMA private REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;"
];

function quoteIdentity(row) {
  const match = /^([a-z_][a-z0-9_]*)\.([a-z_][a-z0-9_]*)\((.*)\)$/.exec(row.identity);
  if (!match) throw new Error('Unsafe function identity: ' + row.identity);
  const [, schema, name, args] = match;
  const types = args ? args.split(',').map(part => {
    const trimmed = part.trim();
    const type = trimmed.replace(/^[a-z_][a-z0-9_]*\s+/, '');
    if (!/^[a-z_][a-z0-9_]*(\[\])?$/.test(type)) throw new Error('Unsupported argument type in ' + row.identity + ': ' + type);
    return type;
  }) : [];
  return {schema, name, types, signature: schema + '.' + name + '(' + types.join(', ') + ')'};
}

for (const row of matrix.functions) {
  const source = sourceByIdentity.get(row.identity);
  if (!source) throw new Error('Missing manifest identity: ' + row.identity);
  if (source.raw_acl !== row.acl_snapshot || source.definition_md5 !== row.definition_md5) {
    throw new Error('Stale role matrix for ' + row.identity);
  }
  const {schema, name, types, signature} = quoteIdentity(row);
  const args = types.map((type, i) => 'p' + (i + 1) + ' ' + type).join(', ');
  statements.push(
    'CREATE FUNCTION ' + schema + '.' + name + '(' + args + ') RETURNS void LANGUAGE SQL SECURITY DEFINER SET search_path = \'\' AS \'SELECT\';'
  );
  statements.push('REVOKE ALL ON FUNCTION ' + signature + ' FROM PUBLIC, anon, authenticated, service_role;');
  if (row.public_execute) statements.push('GRANT EXECUTE ON FUNCTION ' + signature + ' TO PUBLIC;');
  for (const role of roles) {
    if (row.expected_execute[role]) statements.push('GRANT EXECUTE ON FUNCTION ' + signature + ' TO ' + role + ';');
  }
}

statements.push('DO $$ BEGIN');
for (const row of matrix.functions) {
  const {signature} = quoteIdentity(row);
  for (const role of roles) {
    const expected = row.expected_execute[role] || row.public_execute;
    statements.push(
      "  IF has_function_privilege('" + role + "', '" + signature + "'::regprocedure, 'EXECUTE') IS DISTINCT FROM " + (expected ? 'true' : 'false') +
      " THEN RAISE EXCEPTION 'ACL mismatch for " + role + " on " + signature + "'; END IF;"
    );
  }
  statements.push(
    "  IF has_function_privilege('postgres', '" + signature + "'::regprocedure, 'EXECUTE') IS DISTINCT FROM true THEN RAISE EXCEPTION 'owner privilege missing on " + signature + "'; END IF;"
  );
}
statements.push('END $$;');
statements.push("SELECT 'PASS: PostgreSQL evaluated effective EXECUTE privileges for all 46 captured function signatures and four roles' AS result;");

fs.writeFileSync('/tmp/digiarz-production-rpc-acl-fixture.sql', statements.join('\n') + '\n');
console.log('Generated disposable ACL fixture for 46 functions.');
