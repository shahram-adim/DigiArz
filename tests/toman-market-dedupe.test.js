const test = require("node:test");
const assert = require("node:assert/strict");

test("deduplicates identical provider rows by exchange, asset and quote", async () => {
  const { dedupeMarketRows } = await import("../supabase/functions/refresh-toman-market-prices/dedupe-market-rows.mjs");
  const base = {
    exchange: "nobitex",
    asset_symbol: "BTC",
    quote_currency: "TOMAN",
    price_toman: 3200000000,
    bid_toman: 3199000000,
    ask_toman: 3201000000,
    fetched_at: "2026-11-22T12:00:00.000Z",
  };
  const result = dedupeMarketRows([base, { ...base }, { ...base, asset_symbol: "ETH" }]);

  assert.equal(result.rows.length, 2);
  assert.equal(result.duplicateRowsRemoved, 1);
  assert.equal(result.conflictingSymbolsSkipped, 0);
});

test("skips a symbol when one provider supplies conflicting prices", async () => {
  const { dedupeMarketRows } = await import("../supabase/functions/refresh-toman-market-prices/dedupe-market-rows.mjs");
  const base = {
    exchange: "wallex",
    asset_symbol: "BTC",
    quote_currency: "TOMAN",
    price_toman: 3200000000,
  };
  const result = dedupeMarketRows([
    base,
    { ...base, price_toman: 3190000000 },
    { ...base, price_toman: 3210000000 },
    { ...base, asset_symbol: "ETH", price_toman: 100000000 },
  ]);

  assert.deepEqual(result.rows.map((row) => row.asset_symbol), ["ETH"]);
  assert.equal(result.duplicateRowsRemoved, 2);
  assert.equal(result.conflictingSymbolsSkipped, 1);
});

test("keeps the same asset from different exchanges and quote keys", async () => {
  const { dedupeMarketRows } = await import("../supabase/functions/refresh-toman-market-prices/dedupe-market-rows.mjs");
  const result = dedupeMarketRows([
    { exchange: "nobitex", asset_symbol: "BTC", quote_currency: "TOMAN", price_toman: 1 },
    { exchange: "wallex", asset_symbol: "BTC", quote_currency: "TOMAN", price_toman: 2 },
    { exchange: "nobitex", asset_symbol: "BTC", quote_currency: "IRT", price_toman: 3 },
  ]);

  assert.equal(result.rows.length, 3);
  assert.equal(result.duplicateRowsRemoved, 0);
  assert.equal(result.conflictingSymbolsSkipped, 0);
});


test("history writes use the atomic six-hour RPC instead of a read-then-write race", async () => {
  const fs = require("node:fs");
  const edgeSource = fs.readFileSync("supabase/functions/refresh-toman-market-prices/index.ts", "utf8");
  const migration = fs.readFileSync("supabase/migrations/20261122130000_atomic_toman_history_interval.sql", "utf8");

  assert.match(edgeSource, /\/rest\/v1\/rpc\/insert_market_toman_history_if_due/);
  assert.doesNotMatch(edgeSource, /market_toman_price_history\?select=exchange,asset_symbol,recorded_at/);
  assert.match(migration, /pg_advisory_xact_lock/);
  assert.match(migration, /order by exchange, asset_symbol/i);
  assert.match(migration, /recorded_at >= pg_catalog\.now\(\) - interval '6 hours'/);
  assert.match(migration, /grant execute on function public\.insert_market_toman_history_if_due\(jsonb\) to service_role/i);
});
