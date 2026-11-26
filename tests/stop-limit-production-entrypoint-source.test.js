'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const read = (relativePath) => fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8');

function extractDefinition(source, functionName) {
  const escapedName = functionName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const pattern = new RegExp(
    'CREATE OR REPLACE FUNCTION\\s+public\\.' + escapedName +
    '\\s*\\([\\s\\S]*?\\)\\s*RETURNS\\s+jsonb[\\s\\S]*?AS\\s+\\$function\\$[\\s\\S]*?\\$function\\$',
    'i'
  );
  const match = source.match(pattern);
  assert.ok(match, functionName + ': captured Production definition not found');
  // pg_get_functiondef() returns one trailing newline after the function delimiter.
  return match[0] + '\n';
}

const placeSnapshot = read('supabase/tests/stop_limit_production_place_limit_order_snapshot.sql');
const cancelSnapshot = read('supabase/tests/stop_limit_production_cancel_limit_order_snapshot.sql');
const placeDefinition = extractDefinition(placeSnapshot, 'place_limit_order');
const cancelDefinition = extractDefinition(cancelSnapshot, 'cancel_limit_order');

test('captured Production place_limit_order matches the read-only database fingerprint', () => {
  assert.equal(createHash('md5').update(placeDefinition).digest('hex'), '3eab167c47bf8ff2e1705b9f243380ec');
  assert.match(placeDefinition, /SECURITY DEFINER/i);
  assert.match(placeDefinition, /SET search_path TO ''/i);
});

test('captured Production cancel_limit_order matches the read-only database fingerprint', () => {
  assert.equal(createHash('md5').update(cancelDefinition).digest('hex'), '69360684173b6aabebc5ff4e4de2eed9');
  assert.match(cancelDefinition, /SECURITY DEFINER/i);
  assert.match(cancelDefinition, /SET search_path TO ''/i);
});

test('Production Limit placement derives identity and validates trading eligibility before writes', () => {
  assert.match(placeDefinition, /v_uid\s*:=\s*auth\.uid\(\)/i);
  assert.match(placeDefinition, /current_account_is_active\(\)/i);
  assert.match(placeDefinition, /pair_symbol\s*=\s*v_symbol[\s\S]*?is_enabled\s+IS\s+TRUE/i);
  assert.match(placeDefinition, /p_amount\s+IS\s+NULL\s+OR\s+p_amount\s*<=\s*0/i);
  assert.match(placeDefinition, /p_limit_price\s+IS\s+NULL\s+OR\s+p_limit_price\s*<=\s*0/i);
});

test('Production Limit placement serializes balance checks and creates order plus reservation atomically', () => {
  assert.match(placeDefinition, /FROM\s+public\.wallets\s+AS\s+w[\s\S]*?FOR UPDATE/i);
  assert.match(placeDefinition, /FROM\s+public\.asset_balances\s+AS\s+ab[\s\S]*?FOR UPDATE/i);
  assert.match(placeDefinition, /SUM\(GREATEST\([\s\S]*?reserved_amount\s*-\s*r\.consumed_amount\s*-\s*r\.released_amount/i);
  assert.match(placeDefinition, /INSERT INTO public\.orders/i);
  assert.match(placeDefinition, /INSERT INTO public\.order_reservations/i);
});

test('Production Limit cancellation is owner-scoped and releases only a validated remainder', () => {
  assert.match(cancelDefinition, /v_uid\s*uuid\s*:=\s*auth\.uid\(\)/i);
  assert.match(cancelDefinition, /WHERE id = p_order_id\s+AND user_id = v_uid\s+FOR UPDATE/i);
  assert.match(cancelDefinition, /order_type\s*<>\s*'limit'/i);
  assert.match(cancelDefinition, /status NOT IN \('pending', 'partially_filled'\)/i);
  assert.match(cancelDefinition, /released_amount\s*=\s*reserved_amount\s*-\s*consumed_amount/i);
  assert.match(cancelDefinition, /consumed_amount \+ released_amount <= reserved_amount/i);
  assert.match(cancelDefinition, /IF v_rows <> 1 THEN/i);
  assert.match(cancelDefinition, /SET status = 'cancelled',[\s\S]*?remaining_amount = amount - filled_amount/i);
});
