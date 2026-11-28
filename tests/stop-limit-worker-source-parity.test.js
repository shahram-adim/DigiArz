'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const read = (relativePath) => fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8');

function extractFullWorker(source, label) {
  const match = source.match(/CREATE OR REPLACE FUNCTION\s+public\.process_stop_limit_orders\s*\(\s*\)\s*RETURNS\s+jsonb[\s\S]*?AS\s+\$function\$[\s\S]*?\$function\$/i);
  assert.ok(match, label + ': process_stop_limit_orders() definition not found');
  // pg_get_functiondef() includes one trailing newline; the executable SQL snapshot adds a semicolon after the delimiter.
  return match[0] + '\n';
}

function extractWorkerBody(source, label) {
  const match = source.match(/CREATE OR REPLACE FUNCTION\s+public\.process_stop_limit_orders\s*\(\s*\)\s*RETURNS\s+jsonb[\s\S]*?AS\s+\$function\$([\s\S]*?)\$function\$/i);
  assert.ok(match, label + ': process_stop_limit_orders() body not found');
  return match[1].replace(/--[^\n]*/g, '').replace(/\s+/g, ' ').trim();
}

const productionSnapshot = read('supabase/tests/stop_limit_production_worker_snapshot.sql');
const productionBody = extractWorkerBody(productionSnapshot, 'Production snapshot');
const candidate = read('supabase/drafts/2026-11-16_exact_decimal_process_stop_limit_orders.sql');
const fixture = read('supabase/tests/exact_decimal_stop_limit_worker.sql');
const migration = read('supabase/migrations/20261113181827_add_stop_limit_order_engine.sql');
const retryMigration = read('supabase/migrations/20261115143827_bound_stop_limit_invalid_reservation_retries.sql');

test('captured Production Stop-Limit worker matches the read-only database fingerprint', () => {
  const definition = extractFullWorker(productionSnapshot, 'Production snapshot');
  assert.equal(
    createHash('md5').update(definition).digest('hex'),
    '66357ab4a2247019f22a8b6ab6eac6fe'
  );
  assert.match(definition, /SECURITY DEFINER/i);
  assert.match(definition, /SET search_path TO ''/i);
});

test('the current CI Stop-Limit worker fixture is identical to its reviewed draft candidate', () => {
  assert.equal(
    extractWorkerBody(candidate, 'Draft candidate'),
    extractWorkerBody(fixture, 'CI fixture')
  );
});

test('candidate child-row lock is explicitly distinguished from the captured Production worker', () => {
  const candidateBody = extractWorkerBody(candidate, 'Draft candidate');
  const migrationBody = extractWorkerBody(migration, 'Applied migration source');
  assert.match(productionBody, /FOR UPDATE OF c,parent SKIP LOCKED/);
  assert.match(migrationBody, /FOR UPDATE OF c,parent SKIP LOCKED/);
  assert.doesNotMatch(productionBody, /FOR UPDATE OF c,parent,child SKIP LOCKED/);
  assert.match(candidateBody, /FOR UPDATE OF c,parent,child SKIP LOCKED/);
});

test('the Production retry patch and snapshot preserve bounded fail-closed reservation handling', () => {
  assert.match(retryMigration, /Reservation validation failed; manual review required/);
  assert.match(retryMigration, /v_attempt\s*>=\s*10/);
  assert.match(productionSnapshot, /Reservation validation failed; manual review required/);
  assert.match(productionSnapshot, /IF v_attempt>=10 THEN/);
  assert.match(productionSnapshot, /never release an invalid reservation/i);
});

test('the Production snapshot integration exercises ten separate retries and a fail-fast child RPC sentinel', () => {
  const sql = read('supabase/tests/stop_limit_production_worker_retry_exhaustion.sql');
  assert.equal((sql.match(/SELECT public\.process_stop_limit_orders\(\);/g) || []).length, 10);
  assert.match(sql, /unexpected place_limit_order call in invalid-reservation regression/);
  assert.match(sql, /invalid reservation was modified during fail-closed handling/);
});


function extractRawWorkerBody(source, label) {
  const match = source.match(/CREATE OR REPLACE FUNCTION\\s+public\\.process_stop_limit_orders\\s*\\(\\s*\\)\\s*RETURNS\\s+jsonb[\\s\\S]*?AS\\s+\\$function\\$([\\s\\S]*?)\\$function\\$/i);
  assert.ok(match, label + ': raw process_stop_limit_orders() body not found');
  return match[1];
}

function normalizeWorkerBody(source) {
  return source
    .replace(/--[^\\n]*/g, '')
    .replace(/\\s+/g, ' ')
    .trim();
}

function extractRetryPatch(source, variableName, tag) {
  const pattern = new RegExp(
    '\\b' + variableName + '\\s+text\\s*:=\\s*\\$' + tag + '\\$([\\s\\S]*?)\\$' + tag + '\\$;',
    'i'
  );
  const match = source.match(pattern);
  assert.ok(match, 'retry migration ' + variableName + ' patch block is missing');
  return match[1];
}

test('applied base migration plus bounded-retry patch reconstructs the captured Production Stop-Limit worker', () => {
  const baseBody = extractRawWorkerBody(migration, 'Applied base migration');
  const productionBody = extractRawWorkerBody(productionSnapshot, 'Captured Production snapshot');
  const oldValidationBranch = extractRetryPatch(retryMigration, 'v_old', 'old');
  const newValidationBranch = extractRetryPatch(retryMigration, 'v_new', 'new');

  assert.ok(
    baseBody.includes(oldValidationBranch),
    'the bounded-retry patch must target the exact branch present in the applied base migration'
  );

  const reconstructedProductionBody = baseBody.replace(oldValidationBranch, newValidationBranch);
  assert.equal(
    normalizeWorkerBody(reconstructedProductionBody),
    normalizeWorkerBody(productionBody),
    'the checked-in base migration plus its applied retry patch must match the captured Production worker body'
  );
});
