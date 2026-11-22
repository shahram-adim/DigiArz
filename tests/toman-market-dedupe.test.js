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


test("normalizes decimal strings without binary floating-point conversion", async () => {
  const { normalizeDecimal, shiftDecimal } = await import("../supabase/functions/refresh-toman-market-prices/decimal.mjs");
  assert.equal(normalizeDecimal("0001.2300"), "1.23");
  assert.equal(normalizeDecimal("17746.325100000002"), "17746.3251000000".replace(/0+$/, ""));
  assert.equal(shiftDecimal("17746.325100000002", -1), "1774.63251");
  assert.equal(shiftDecimal("1.25e+3", -1), "125");
});

test("rounds to the declared PostgreSQL NUMERIC scale using half-away-from-zero", async () => {
  const { normalizeDecimal } = await import("../supabase/functions/refresh-toman-market-prices/decimal.mjs");
  assert.equal(normalizeDecimal("1.12345678905"), "1.1234567891");
  assert.equal(normalizeDecimal("-1.12345678905"), "-1.1234567891");
  assert.equal(normalizeDecimal("1.12345678904"), "1.123456789");
  assert.equal(normalizeDecimal("123456789012345678901"), null);
});

test("deduplicates numerically equal decimal representations", async () => {
  const { dedupeMarketRows } = await import("../supabase/functions/refresh-toman-market-prices/dedupe-market-rows.mjs");
  const base = {
    exchange: "nobitex",
    asset_symbol: "USDT",
    quote_currency: "TOMAN",
    price_toman: "1.0",
    bid_toman: "0.99",
    ask_toman: "1.00",
  };
  const result = dedupeMarketRows([base, {
    ...base,
    price_toman: "1.00",
    bid_toman: "0.9900",
    ask_toman: "1.0",
  }]);
  assert.equal(result.rows.length, 1);
  assert.equal(result.duplicateRowsRemoved, 1);
  assert.equal(result.conflictingSymbolsSkipped, 0);
});
