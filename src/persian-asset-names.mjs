const PERSIAN_LETTERS = /[\u0600-\u06FF]/;
const PERSIAN_MARKS = /[\u064B-\u065F\u0670\u0640]/g;

function cleanCandidate(value) {
  if (typeof value !== "string") return null;
  const name = value.replace(/[\u200B\u200C\u200D\uFEFF]/g, " ").replace(/\s+/g, " ").trim();
  if (!name || name.length > 80 || !PERSIAN_LETTERS.test(name)) return null;
  if (/^[\d\s.,+\-_/]+$/.test(name)) return null;
  return name;
}

export function normalizePersianName(value) {
  const name = cleanCandidate(value);
  if (!name) return null;
  return name
    .replace(/[يى]/g, "ی")
    .replace(/ك/g, "ک")
    .replace(PERSIAN_MARKS, "")
    .replace(/[\u200B\u200C\u200D\uFEFF\s]+/g, "")
    .trim();
}

function getPath(object, path) {
  return path.split(".").reduce((value, key) => value && typeof value === "object" ? value[key] : undefined, object);
}

function isStandaloneWallexFallback(value) {
  const name = cleanCandidate(value);
  if (!name || /[\/_-]/.test(name)) return false;
  // faName can describe a trading pair; do not promote obvious quote-asset labels.
  if (/(تتر|تومان|ریال|دلار)\s*$/u.test(name)) return false;
  return true;
}

/**
 * Extracts a source-attributed Persian-name candidate only.
 * This function never decides asset identity or canonical approval.
 */
export function extractPersianNameCandidate(exchange, payload) {
  if (!payload || typeof payload !== "object") return null;
  const sources = {
    bit24: [["base_coin.fa_name", getPath(payload, "base_coin.fa_name")]],
    kifpool: [["faName", payload.faName]],
    abantether: [["persian_name", payload.persian_name]],
    wallex: [
      ["faBaseAsset", payload.faBaseAsset],
      ["faName", isStandaloneWallexFallback(payload.faName) ? payload.faName : null],
    ],
  };
  const candidates = sources[String(exchange || "").toLowerCase()] || [];
  for (const [sourceKey, raw] of candidates) {
    const name = cleanCandidate(raw);
    const normalizedName = normalizePersianName(name);
    if (name && normalizedName) {
      return { name, normalized_name: normalizedName, source_exchange: String(exchange).toLowerCase(), source_key: sourceKey };
    }
  }
  return null;
}
