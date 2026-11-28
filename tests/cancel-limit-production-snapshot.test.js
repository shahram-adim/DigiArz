import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const snapshot = readFileSync(
  new URL('../supabase/tests/stop_limit_production_cancel_limit_order_snapshot.sql', import.meta.url),
  'utf8'
);
const workerSnapshot = readFileSync(
  new URL('../supabase/tests/stop_limit_production_process_limit_orders_snapshot.sql', import.meta.url),
  'utf8'
);
const setup = readFileSync(
  new URL('../supabase/tests/exact_decimal_cancel_setup.sql', import.meta.url),
  'utf8'
);
const workflow = readFileSync(
  new URL('../.github/workflows/exact-decimal-tests.yml', import.meta.url),
  'utf8'
);

test('Limit cancellation CI loads the captured Production function, not a synthetic replacement', () => {
  assert.match(snapshot, /md5\(pg_get_functiondef\(\.\.\.\)\): 69360684173b6aabebc5ff4e4de2eed9/);
  assert.match(snapshot, /CREATE OR REPLACE FUNCTION public\.cancel_limit_order\(p_order_id uuid\)/);
  assert.match(snapshot, /SECURITY DEFINER[\s\S]*?SET search_path TO ''/);
  assert.match(snapshot, /FOR UPDATE/);
  assert.match(snapshot, /exactly one valid active reservation is required/);
  assert.match(snapshot, /SET status = 'cancelled'/);

  assert.match(setup, /CREATE OR REPLACE FUNCTION auth\.uid\(\)/);
  assert.doesNotMatch(setup, /CREATE OR REPLACE FUNCTION public\.cancel_limit_order/);

  const integration = workflow.match(
    /- name: Compile and run isolated Limit cancellation lifecycle integration([\s\S]*?)(?=\n      - name:|$)/
  )?.[1] || '';
  const race = workflow.match(
    /- name: Run real two-session Limit worker and cancellation race tests([\s\S]*?)(?=\n      - name:|$)/
  )?.[1] || '';
  assert.match(integration, /exact_decimal_cancel_setup\.sql[\s\S]*stop_limit_production_cancel_limit_order_snapshot\.sql[\s\S]*exact_decimal_cancel_integration\.sql/);
  assert.match(race, /exact_decimal_cancel_setup\.sql[\s\S]*stop_limit_production_cancel_limit_order_snapshot\.sql[\s\S]*stop_limit_production_process_limit_orders_snapshot\.sql[\s\S]*exact_decimal_cancel_race_setup\.sql/);
  assert.doesNotMatch(race, /2026-11-15_exact_decimal_process_limit_orders\.sql/);
  assert.match(workerSnapshot, /md5\(pg_get_functiondef\(\.\.\.\)\): 00ab429596fb99392666632967cde9c0/);
  assert.match(workerSnapshot, /CREATE OR REPLACE FUNCTION public\.process_limit_orders\(\)/);
});
