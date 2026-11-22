import { equalDecimals } from "./decimal.mjs";

const PRICE_FIELDS = [
  "price_toman",
  "bid_toman",
  "ask_toman",
  "high_24h_toman",
  "low_24h_toman",
  "change_24h_pct",
  "volume_24h_toman",
];

function samePrice(left, right) {
  return PRICE_FIELDS.every((field) => equalDecimals(left[field], right[field]));
}

/**
 * Collapse repeated provider rows by the database's natural unique key.
 * If one provider supplies conflicting prices for the same key, omit that key
 * rather than selecting an arbitrary market/quote representation.
 */
export function dedupeMarketRows(rows) {
  const byKey = new Map();
  const conflicts = new Set();

  for (const row of rows) {
    const key = [row.exchange, row.asset_symbol, row.quote_currency].join(":");
    if (conflicts.has(key)) continue;

    const existing = byKey.get(key);
    if (!existing) {
      byKey.set(key, row);
      continue;
    }

    if (samePrice(existing, row)) {
      continue;
    }

    byKey.delete(key);
    conflicts.add(key);
  }

  const uniqueKeyCount = byKey.size + conflicts.size;
  return {
    rows: [...byKey.values()],
    duplicateRowsRemoved: rows.length - uniqueKeyCount,
    conflictingSymbolsSkipped: conflicts.size,
  };
}
