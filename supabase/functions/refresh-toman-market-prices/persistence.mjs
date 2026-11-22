export function dedupeTomanPriceRows(inputRows) {
  if (!Array.isArray(inputRows)) throw new TypeError("Toman price rows must be an array");
  const unique = new Map();
  for (const row of inputRows) {
    if (!row || typeof row !== "object") throw new TypeError("Toman price row must be an object");
    const exchange = String(row.exchange ?? "").trim().toLowerCase();
    const asset = String(row.asset_symbol ?? "").trim().toUpperCase();
    const quote = String(row.quote_currency ?? "").trim().toUpperCase();
    if (!exchange || !asset || !quote) throw new TypeError("Toman price row is missing its unique key");
    const key = JSON.stringify([exchange, asset, quote]);
    if (!unique.has(key)) unique.set(key, row);
  }
  return { rows: [...unique.values()], duplicateCount: inputRows.length - unique.size };
}

export function buildTomanPriceUpsertRequest(supabaseUrl, rows) {
  if (!Array.isArray(rows) || rows.length === 0) throw new TypeError("At least one Toman price row is required for upsert");
  const url = new URL("/rest/v1/market_toman_prices", supabaseUrl);
  url.searchParams.set("on_conflict", "exchange,asset_symbol,quote_currency");
  return {
    url: url.toString(),
    headers: {
      "Content-Type": "application/json",
      Prefer: "resolution=merge-duplicates,return=minimal",
    },
    body: JSON.stringify(rows),
  };
}

export function classifyProviderError(error) {
  const name = error instanceof Error ? error.name : "";
  const message = error instanceof Error ? error.message : String(error ?? "");
  const text = `${name} ${message}`;
  const httpStatus = /\\bHTTP\\s+(\\d{3})\\b/i.exec(text);
  if (httpStatus) return `http_${httpStatus[1]}`;
  if (/timeout|timed out|aborted/i.test(text)) return "timeout";
  if (/invalid|no .* (?:markets|rows|ticker)|recognized format/i.test(message)) return "invalid_or_empty_response";
  return "provider_error";
}

export function summarizeProviderResults(results, providerNames) {
  return providerNames.map((provider, index) => {
    const result = results[index];
    if (!result) return { provider, ok: false, count: 0, error_code: "missing_result" };
    if (result.status === "fulfilled") return { provider, ok: true, count: Array.isArray(result.value) ? result.value.length : 0 };
    return { provider, ok: false, count: 0, error_code: classifyProviderError(result.reason) };
  });
}
