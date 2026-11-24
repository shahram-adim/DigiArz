import test from "node:test";
import assert from "node:assert/strict";
import { extractPersianNameCandidate, normalizePersianName } from "../src/persian-asset-names.mjs";

test("extracts Bit24 nested base_coin.fa_name", () => {
  assert.deepEqual(extractPersianNameCandidate("bit24", { base_coin: { fa_name: "بیت‌کوین" } }), {
    name: "بیت‌کوین", normalized_name: "بیتکوین", source_exchange: "bit24", source_key: "base_coin.fa_name"
  });
});

test("extracts Kifpool faName and AbanTether persian_name", () => {
  assert.equal(extractPersianNameCandidate("kifpool", { faName: "اتریوم" }).name, "اتریوم");
  assert.equal(extractPersianNameCandidate("abantether", { persian_name: "تتر" }).source_key, "persian_name");
});

test("prefers Wallex faBaseAsset and only accepts a safe faName fallback", () => {
  const preferred = extractPersianNameCandidate("wallex", { faBaseAsset: "بایننس کوین", faName: "بایننس کوین تتر" });
  assert.equal(preferred.source_key, "faBaseAsset");
  assert.equal(extractPersianNameCandidate("wallex", { faName: "بایننس کوین تتر" }), null);
  assert.equal(extractPersianNameCandidate("wallex", { faName: "سولانا" }).source_key, "faName");
});

test("rejects missing, English-only, numeric and blank candidates", () => {
  for (const value of [undefined, null, "", "Bitcoin", "12345", "   "]) {
    assert.equal(extractPersianNameCandidate("bit24", { base_coin: { fa_name: value } }), null);
  }
});

test("normalizes Arabic Yeh/Kaf, diacritics and spacing without losing the display name", () => {
  assert.equal(normalizePersianName("يَك كوين"), "یککوین");
  assert.equal(normalizePersianName("بیت کوین"), "بیتکوین");
  assert.equal(normalizePersianName("بیت‌کوین"), "بیتکوین");
});

test("does not infer a Persian name from an unknown exchange or from a symbol", () => {
  assert.equal(extractPersianNameCandidate("unknown", { faName: "اتریوم" }), null);
  assert.equal(extractPersianNameCandidate("bit24", { symbol: "BTC" }), null);
});

test("candidate extraction does not imply a canonical asset match", () => {
  const candidate = extractPersianNameCandidate("bit24", { base_coin: { fa_name: "بیت کوین" } });
  assert.ok(candidate);
  assert.equal("coingecko_id" in candidate, false);
  assert.equal("canonical" in candidate, false);
  assert.equal("approved" in candidate, false);
});
