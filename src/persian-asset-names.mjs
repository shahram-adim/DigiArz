const PERSIAN_LETTERS = /[\u0600-\u06FF]/;
const PERSIAN_MARKS = /[\u064B-\u065F\u0670\u0640]/g;

function cleanCandidate(value) {
  if (typeof value !== "string") return null;
  const name = value.replace(/[\u200B\u200D\uFEFF]/g, "").replace(/\s+/g, " ").trim();
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


function normalizedNetwork(value) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function normalizedContract(value) {
  if (typeof value !== "string") return "";
  const address = value.trim();
  if (!address) return "";
  // EVM hexadecimal addresses are case-insensitive; preserve case for other chains.
  return /^0x[0-9a-fA-F]{40}$/.test(address) ? address.toLowerCase() : address;
}

/**
 * Resolve an observation only by an explicit CoinGecko ID or an exact
 * network + contract pair. A ticker/symbol is never an identity key.
 */
export function resolveAssetIdentity(observation, assets) {
  if (!observation || typeof observation !== "object" || !Array.isArray(assets)) {
    return { status: "unmatched", reason: "invalid_input", asset: null };
  }
  const payload = observation.source_payload && typeof observation.source_payload === "object"
    ? observation.source_payload : {};
  const explicitId = [observation.coingecko_id, payload.coingecko_id, payload.coingeckoId, payload.coinGeckoId]
    .find(value => typeof value === "string" && value.trim());
  if (explicitId) {
    const matches = assets.filter(asset => asset && asset.coingecko_id === explicitId.trim());
    if (matches.length === 1) return { status: "matched", reason: "coingecko_id", asset: matches[0] };
    if (matches.length > 1) return { status: "ambiguous", reason: "duplicate_coingecko_id", asset: null };
    return { status: "unmatched", reason: "coingecko_id_not_found", asset: null };
  }

  const network = normalizedNetwork(
    observation.network || payload.network || payload.chain || payload.chain_id || payload.chainId
  );
  const contract = normalizedContract(
    observation.contract_address || payload.contract_address || payload.contractAddress ||
    payload.contract || payload.token_address || payload.tokenAddress
  );
  if (network && contract) {
    const matches = assets.filter(asset =>
      asset &&
      normalizedNetwork(asset.network || asset.platform || asset.chain) === network &&
      normalizedContract(asset.contract_address || asset.contractAddress || asset.token_address) === contract
    );
    if (matches.length === 1) return { status: "matched", reason: "network_contract", asset: matches[0] };
    if (matches.length > 1) return { status: "ambiguous", reason: "duplicate_network_contract", asset: null };
  }
  return { status: "unmatched", reason: "exact_identity_missing", asset: null };
}


/**
 * Aggregate already-extracted candidates by exact, previously matched
 * CoinGecko identity. Never uses symbol as a grouping key.
 *
 * Automatic consensus requires at least two independent exchanges and one
 * normalized spelling. Conflicts remain review-only with every source kept.
 */
export function aggregatePersianNameCandidates(observations) {
  if (!Array.isArray(observations)) return [];
  const byAsset = new Map();

  for (const observation of observations) {
    if (!observation || observation.match_status !== "matched") continue;
    const coingeckoId = typeof observation.coingecko_id === "string"
      ? observation.coingecko_id.trim() : "";
    if (!coingeckoId) continue;

    const sourceExchange = String(observation.exchange || "").toLowerCase().trim();
    if (!["bit24", "kifpool", "abantether", "wallex"].includes(sourceExchange)) continue;

    const payload = observation.source_payload && typeof observation.source_payload === "object"
      ? observation.source_payload : {};
    const candidate = observation.candidate && typeof observation.candidate === "object"
      ? observation.candidate
      : (payload._digiarz_persian_name_candidate && typeof payload._digiarz_persian_name_candidate === "object"
        ? payload._digiarz_persian_name_candidate
        : extractPersianNameCandidate(sourceExchange, payload));
    if (!candidate || !cleanCandidate(candidate.name)) continue;
    const normalizedName = normalizePersianName(candidate.name);
    if (!normalizedName) continue;

    if (!byAsset.has(coingeckoId)) byAsset.set(coingeckoId, new Map());
    const byName = byAsset.get(coingeckoId);
    if (!byName.has(normalizedName)) byName.set(normalizedName, new Map());
    const bySource = byName.get(normalizedName);
    if (!bySource.has(sourceExchange)) {
      bySource.set(sourceExchange, {
        name: candidate.name,
        source_exchange: sourceExchange,
        source_key: candidate.source_key || null,
        source_url: observation.source_url || null,
      });
    }
  }

  return [...byAsset.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([coingeckoId, byName]) => {
    const variants = [...byName.entries()].map(([normalizedName, bySource]) => ({
      normalized_name: normalizedName,
      sources: [...bySource.values()].sort((a, b) => a.source_exchange.localeCompare(b.source_exchange)),
    })).sort((a, b) => a.normalized_name.localeCompare(b.normalized_name));
    const sourceCount = new Set(variants.flatMap(variant => variant.sources.map(source => source.source_exchange))).size;

    if (variants.length > 1) {
      return { coingecko_id: coingeckoId, status: "review_required", consensus_name_candidate: null, variants, source_count: sourceCount };
    }
    if (sourceCount < 2) {
      return { coingecko_id: coingeckoId, status: "single_source", consensus_name_candidate: null, variants, source_count: sourceCount };
    }
    return {
      coingecko_id: coingeckoId,
      status: "consensus_candidate",
      consensus_name_candidate: {
        normalized_name: variants[0].normalized_name,
        source_spellings: variants[0].sources,
      },
      variants,
      source_count: sourceCount,
    };
  });
}
