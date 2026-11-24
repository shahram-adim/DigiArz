import test from "node:test";
import assert from "node:assert/strict";
import { extractPersianNameCandidate, normalizePersianName, resolveAssetIdentity } from "../src/persian-asset-names.mjs";

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


test("preserves source display spelling including Persian ZWNJ", () => {
  const candidate = extractPersianNameCandidate("bit24", { base_coin: { fa_name: "بیت‌کوین" } });
  assert.equal(candidate.name, "بیت‌کوین");
  assert.equal(candidate.normalized_name, "بیتکوین");
});

test("resolves only a unique explicit CoinGecko identity", () => {
  const btc = { coingecko_id: "bitcoin", symbol: "BTC" };
  assert.deepEqual(resolveAssetIdentity({ symbol: "BTC", coingecko_id: "bitcoin" }, [btc]), {
    status: "matched", reason: "coingecko_id", asset: btc
  });
});

test("duplicate CoinGecko IDs are ambiguous, not silently selected", () => {
  const assets = [{ coingecko_id: "one" }, { coingecko_id: "one" }];
  assert.equal(resolveAssetIdentity({ coingecko_id: "one" }, assets).status, "ambiguous");
});

test("resolves exact network and contract when CoinGecko ID is absent", () => {
  const token = { coingecko_id: "token-a", network: "ethereum", contract_address: "0x1234567890123456789012345678901234567890" };
  const result = resolveAssetIdentity({
    network: "Ethereum",
    contract_address: "0x1234567890123456789012345678901234567890"
  }, [token]);
  assert.equal(result.status, "matched");
  assert.equal(result.reason, "network_contract");
  assert.equal(result.asset, token);
});

test("does not match by ticker or symbol alone, even if only one asset shares it", () => {
  const assets = [{ coingecko_id: "token-a", symbol: "ONE" }];
  assert.equal(resolveAssetIdentity({ base_symbol: "ONE" }, assets).status, "unmatched");
  assert.equal(resolveAssetIdentity({ symbol: "ONE" }, assets).status, "unmatched");
});

test("does not use contract address without its network", () => {
  const assets = [{ coingecko_id: "token-a", network: "ethereum", contract_address: "0x1234567890123456789012345678901234567890" }];
  assert.equal(resolveAssetIdentity({ contract_address: "0x1234567890123456789012345678901234567890" }, assets).status, "unmatched");
});

test("preserves case-sensitive non-EVM contract identifiers", () => {
  const asset = { coingecko_id: "sol-token", network: "solana", contract_address: "AbC123" };
  assert.equal(resolveAssetIdentity({ network: "solana", contract_address: "abc123" }, [asset]).status, "unmatched");
});


test("does not fall back to a contract match when an explicit CoinGecko ID conflicts", () => {
  const asset = { coingecko_id: "correct-id", network: "ethereum", contract_address: "0x1234567890123456789012345678901234567890" };
  const result = resolveAssetIdentity({
    coingecko_id: "wrong-id",
    network: "ethereum",
    contract_address: "0x1234567890123456789012345678901234567890"
  }, [asset]);
  assert.equal(result.status, "unmatched");
  assert.equal(result.reason, "coingecko_id_not_found");
});


import { aggregatePersianNameCandidates } from "../src/persian-asset-names.mjs";

function observation(coingecko_id, exchange, name, match_status = "matched", source_url = null) {
  return {
    coingecko_id, exchange, match_status, source_url,
    candidate: { name, normalized_name: normalizePersianName(name), source_exchange: exchange, source_key: "test" }
  };
}

test("aggregates matching Persian names from independent Iranian exchanges", () => {
  const rows = aggregatePersianNameCandidates([
    observation("bitcoin", "bit24", "بیت‌کوین"),
    observation("bitcoin", "kifpool", "بیت کوین"),
  ]);
  assert.equal(rows.length, 1);
  assert.equal(rows[0].status, "consensus_candidate");
  assert.equal(rows[0].canonical_name_fa, "بیت‌کوین");
  assert.equal(rows[0].source_count, 2);
  assert.equal(rows[0].variants[0].sources.length, 2);
});

test("keeps spelling conflicts for review and does not select a canonical name", () => {
  const rows = aggregatePersianNameCandidates([
    observation("ethereum", "bit24", "اتریوم"),
    observation("ethereum", "kifpool", "اتر"),
  ]);
  assert.equal(rows[0].status, "review_required");
  assert.equal(rows[0].canonical_name_fa, null);
  assert.equal(rows[0].variants.length, 2);
  assert.deepEqual(rows[0].variants.map(v => v.sources[0].source_exchange), ["kifpool", "bit24"]);
});

test("one exchange alone is not enough for automatic consensus", () => {
  const rows = aggregatePersianNameCandidates([observation("solana", "wallex", "سولانا")]);
  assert.equal(rows[0].status, "single_source");
  assert.equal(rows[0].canonical_name_fa, null);
});

test("ignores ambiguous, pending, unmatched and missing-identity observations", () => {
  const rows = aggregatePersianNameCandidates([
    observation("bitcoin", "bit24", "بیت کوین", "ambiguous"),
    observation("ethereum", "kifpool", "اتریوم", "pending"),
    observation("solana", "wallex", "سولانا", "unmatched"),
    observation("", "bit24", "بیت کوین"),
  ]);
  assert.deepEqual(rows, []);
});

test("does not merge two different assets merely because their symbols match", () => {
  const rows = aggregatePersianNameCandidates([
    { ...observation("token-one", "bit24", "توکن یک"), symbol: "ONE" },
    { ...observation("token-two", "kifpool", "توکن دو"), symbol: "ONE" },
  ]);
  assert.equal(rows.length, 2);
  assert.deepEqual(rows.map(row => row.coingecko_id), ["token-one", "token-two"]);
});

test("deduplicates repeated observations from the same exchange without inflating consensus", () => {
  const rows = aggregatePersianNameCandidates([
    observation("bitcoin", "bit24", "بیت کوین"),
    observation("bitcoin", "bit24", "بیت‌کوین"),
  ]);
  assert.equal(rows[0].status, "single_source");
  assert.equal(rows[0].source_count, 1);
});
