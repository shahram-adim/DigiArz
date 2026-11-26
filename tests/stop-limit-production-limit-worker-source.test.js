'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const snapshot = fs.readFileSync(
  path.join(__dirname, '..', 'supabase/tests/stop_limit_production_process_limit_orders_snapshot.sql'),
  'utf8'
);

function extractDefinition(source) {
  const start = source.indexOf('CREATE OR REPLACE FUNCTION public.process_limit_orders()');
  assert.notEqual(start, -1, 'captured Production process_limit_orders definition is missing');
  const opening = source.indexOf('AS $function$', start);
  assert.notEqual(opening, -1, 'function body opening delimiter is missing');
  const closing = source.indexOf('$function$', opening + 'AS $function$'.length);
  assert.notEqual(closing, -1, 'function body closing delimiter is missing');
  return source.slice(start, closing + '$function$'.length) + '\n';
}

const definition = extractDefinition(snapshot);

test('captured Production process_limit_orders matches the live read-only fingerprint', () => {
  assert.equal(createHash('md5').update(definition).digest('hex'), '00ab429596fb99392666632967cde9c0');
  assert.match(snapshot, /owner=postgres; SECURITY DEFINER; search_path=""; EXECUTE anon=false, authenticated=false, service_role=true/i);
  assert.match(definition, /SECURITY DEFINER/i);
  assert.match(definition, /SET search_path TO ''/i);
});

test('Production Limit worker serializes cycles and selects only eligible fresh-price orders', () => {
  assert.match(definition, /pg_try_advisory_xact_lock\(739201126\)/i);
  assert.match(definition, /o\.status IN \('pending', 'partially_filled'\)/i);
  assert.match(definition, /p\.is_active IS TRUE/i);
  assert.match(definition, /FOR UPDATE SKIP LOCKED/i);
  assert.match(definition, /mp\.updated_at >= now\(\) - interval '1 minute'/i);
  assert.match(definition, /p\.is_enabled IS TRUE/i);
});

test('Production Limit worker validates reservation ownership and locks the wallet before balance mutation', () => {
  assert.match(definition, /FROM public\.order_reservations AS r[\s\S]*?FOR UPDATE/i);
  assert.match(definition, /v_reservation\.user_id <> v_order\.user_id/i);
  assert.match(definition, /v_reservation\.status <> 'reserved'/i);
  assert.match(definition, /consumed_amount \+ v_reservation\.released_amount[\s\S]*?> v_reservation\.reserved_amount/i);
  const walletLock = definition.indexOf('FROM public.wallets AS w');
  const balanceMutation = definition.indexOf('UPDATE public.asset_balances');
  assert.ok(walletLock >= 0 && balanceMutation > walletLock, 'wallet row must be locked before asset-balance mutation');
});

test('Production Limit worker maintains partial-fill, reservation, trade, and transaction records', () => {
  assert.match(definition, /v_qty := LEAST\(v_remaining, v_order\.amount \* 0\.25\)/i);
  assert.match(definition, /UPDATE public\.orders[\s\S]*?filled_amount = v_new_filled/i);
  assert.match(definition, /UPDATE public\.order_reservations[\s\S]*?consumed_amount = v_consumed[\s\S]*?released_amount = v_released/i);
  assert.match(definition, /INSERT INTO public\.trades/i);
  assert.match(definition, /INSERT INTO public\.transactions/i);
  assert.match(definition, /GET DIAGNOSTICS v_rows = ROW_COUNT/i);
});

test('captured Production worker explicitly records the unresolved USDT settlement-quantization gap', () => {
  assert.match(definition, /v_gross := v_qty \* v_market_price/i);
  assert.match(definition, /v_fee := v_gross \* v_fee_rate/i);
  assert.doesNotMatch(definition, /v_(?:gross|fee|total|net)\s*:=\s*round\s*\(/i);
});
