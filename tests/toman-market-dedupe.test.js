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
