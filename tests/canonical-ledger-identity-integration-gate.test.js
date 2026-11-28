import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const ledgerMappingCandidate = readFileSync(
  new URL('../supabase/tests/canonical_asset_ledger_key_mapping_candidate.sql', import.meta.url),
  'utf8'
);

const migration = readFileSync(
  new URL('../supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql', import.meta.url),
  'utf8'
);

function functionBody(name) {
  const marker = `FUNCTION public.${name}`;
  const start = migration.indexOf(marker);
  assert.notEqual(start, -1, `authoritative migration is missing ${name}`);
  const next = migration.indexOf('CREATE OR REPLACE FUNCTION', start + marker.length);
  return migration.slice(start, next === -1 ? undefined : next);
}

test('canonical ledger integration remains an explicit release blocker until every writer and worker resolves canonical keys', () => {
  const market = functionBody('execute_demo_trade');
  const limitPlacement = functionBody('place_limit_order');
  const limitWorker = functionBody('process_limit_orders');

  // These assertions deliberately capture the current legacy behavior. When
  // canonical integration is implemented, replace this blocker test with
  // end-to-end tests proving the canonical UUID -> unique ledger-key mapping.
  assert.match(market, /v_base\s*:=\s*left\(v_symbol,\s*length\(v_symbol\)\s*-\s*4\)/i);
  assert.match(limitPlacement, /v_base_asset\s*:=\s*left\(v_symbol,\s*length\(v_symbol\)\s*-\s*4\)/i);
  assert.match(limitWorker, /v_base_asset\s*:=\s*left\(v_order\.symbol,\s*length\(v_order\.symbol\)\s*-\s*4\)/i);

  for (const [name, body] of [
    ['Market', market],
    ['Limit placement', limitPlacement],
    ['Limit worker', limitWorker]
  ]) {
    assert.doesNotMatch(
      body,
      /resolve_canonical_ledger_asset_key\s*\(/i,
      `${name} still does not resolve the canonical asset ledger key`
    );
  }
});


test('legacy Market and Limit RPC contracts cannot distinguish canonical pairs sharing one display ticker', () => {
  const marketSignature = migration.match(/CREATE OR REPLACE FUNCTION public\.execute_demo_trade\s*\(([^)]*)\)/i)?.[1] || '';
  const limitSignature = migration.match(/CREATE OR REPLACE FUNCTION public\.place_limit_order\s*\(([^)]*)\)/i)?.[1] || '';
  assert.match(marketSignature, /^\s*p_symbol\s+text\s*,/i);
  assert.match(limitSignature, /^\s*p_symbol\s+text\s*,/i);
  assert.doesNotMatch(marketSignature, /pair_id|asset_id/i);
  assert.doesNotMatch(limitSignature, /pair_id|asset_id/i);

  const worker = functionBody('process_limit_orders');
  assert.match(worker, /market_prices[\s\S]*?mp\.symbol\s*=\s*v_order\.symbol/i);
  assert.doesNotMatch(worker, /mp\.pair_id\s*=|canonical_pair_id/i);
});


test('canonical ledger mapping freezes identity and verification evidence after financial use', () => {
  assert.match(ledgerMappingCandidate, /BEFORE UPDATE OF canonical_asset_id, ledger_asset_key, mapping_status, evidence_ref, reviewed_at/);
  assert.match(ledgerMappingCandidate, /NEW\.canonical_asset_id IS DISTINCT FROM OLD\.canonical_asset_id/);
  assert.match(ledgerMappingCandidate, /NEW\.mapping_status IS DISTINCT FROM OLD\.mapping_status/);
  assert.match(ledgerMappingCandidate, /NEW\.evidence_ref IS DISTINCT FROM OLD\.evidence_ref/);
  assert.match(ledgerMappingCandidate, /NEW\.reviewed_at IS DISTINCT FROM OLD\.reviewed_at/);
  assert.match(ledgerMappingCandidate, /Canonical ledger mapping identity and verification are immutable after financial use/);
  assert.match(ledgerMappingCandidate, /referenced canonical identity reassignment unexpectedly accepted/);
  assert.match(ledgerMappingCandidate, /referenced mapping status change unexpectedly accepted/);
  assert.match(ledgerMappingCandidate, /referenced mapping evidence change unexpectedly accepted/);
});
