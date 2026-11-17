'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const sql = fs.readFileSync('supabase/drafts/2026-11-17_process_iran_exchange_asset_sync_race_fix.sql', 'utf8');

test('Iran exchange worker only ingests requests and responses present before its transaction cutoff', () => {
  assert.match(sql, /CREATE OR REPLACE FUNCTION public\.process_iran_exchange_asset_sync\(\)/);
  assert.match(sql, /v_response_ids bigint\[\]/);
  assert.match(sql, /array_agg\(r\.id\)/);
  assert.match(sql, /r\.id = any\(v_response_ids\).*r\.status_code=200/);
  assert.match(sql, /r\.id=q\.request_id and r\.id = any\(v_response_ids\) and q\.processed_at is null/);
  assert.match(sql, /Freeze the exact HTTP response set visible at worker start/);
  assert.equal((sql.match(/transaction_timestamp\(\)/g) || []).length, 3);
  assert.match(sql, /DRAFT ONLY — DO NOT APPLY TO PRODUCTION/);
});

test('new request or late HTTP response is deferred instead of being marked processed', () => {
  const workerStartedAt = Date.parse('2026-11-17T07:40:00.218Z');
  const eligible = (requestedAt, responseCreatedAt) =>
    Date.parse(requestedAt) < workerStartedAt && Date.parse(responseCreatedAt) < workerStartedAt;
  assert.equal(eligible('2026-11-17T07:40:00.200Z', '2026-11-17T07:40:00.210Z'), true);
  assert.equal(eligible('2026-11-17T07:40:00.223Z', '2026-11-17T07:40:00.230Z'), false);
  assert.equal(eligible('2026-11-17T07:39:59.900Z', '2026-11-17T07:40:00.230Z'), false);
});
