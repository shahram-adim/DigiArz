import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { dedupeMarketRows } from "./dedupe-market-rows.mjs";
import { normalizeDecimal, shiftDecimal, compareDecimals } from "./decimal.mjs";
import { parse } from "npm:lossless-json@4.3.4";
import { collectProviderResults, emptyProviderOutcome } from "./provider-results.mjs";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: cors });

const faNames: Record<string, string> = {
  BTC: "بیت‌کوین", ETH: "اتریوم", USDT: "تتر", BNB: "بایننس کوین",
  SOL: "سولانا", XRP: "ریپل", DOGE: "دوج‌کوین", ADA: "کاردانو",
  TON: "تون‌کوین", TRX: "ترون", AVAX: "آوالانچ", LINK: "چین‌لینک",
  LTC: "لایت‌کوین", SHIB: "شیبا اینو", DOT: "پولکادات", BCH: "بیت‌کوین کش",
  ETC: "اتریوم کلاسیک", UNI: "یونی‌سواپ", AAVE: "آوه", XLM: "استلار",
};

const decimalOrNull = (...values: unknown[]): string | null => {
  for (const value of values) {
    const parsed = normalizeDecimal(value);
    if (parsed !== null) return parsed;
  }
  return null;
};

const validAsset = (value: string) => /^[A-Z0-9]{2,20}$/.test(value);

async function getJson(url: string, provider: string) {
  const response = await fetch(url, {
    headers: { accept: "application/json", "user-agent": "DigiArz-Toman-Market/1.0" },
    signal: AbortSignal.timeout(12000),
  });
  if (!response.ok) throw new Error(provider + " HTTP " + response.status);
  return parse(await response.text()) as any;
}

function makeRow(
  exchange: string,
  asset: string,
  values: {
    price: string | null; bid?: string | null; ask?: string | null;
    high?: string | null; low?: string | null; change?: string | null;
    volume?: string | null; nameFa?: string | null; nameEn?: string | null;
  },
  fetchedAt: string,
) {
  if (!validAsset(asset) || values.price === null || compareDecimals(values.price, "0") <= 0) return null;
  const positive = (v: string | null | undefined) => v !== null && v !== undefined && compareDecimals(v, "0") > 0 ? v : null;
  const nonNegative = (v: string | null | undefined) => v !== null && v !== undefined && compareDecimals(v, "0") >= 0 ? v : null;
  return {
    exchange,
    asset_symbol: asset,
    quote_currency: "TOMAN",
    price_toman: values.price,
    bid_toman: positive(values.bid),
    ask_toman: positive(values.ask),
    high_24h_toman: positive(values.high),
    low_24h_toman: positive(values.low),
    change_24h_pct: values.change !== null && values.change !== undefined ? values.change : null,
    volume_24h_toman: nonNegative(values.volume),
    asset_name_fa: values.nameFa || faNames[asset] || asset,
    asset_name_en: values.nameEn || asset,
    fetched_at: fetchedAt,
  };
}

async function fetchNobitex(fetchedAt: string) {
  const payload = await getJson("https://apiv2.nobitex.ir/market/stats?dstCurrency=rls", "Nobitex");
  if (payload?.status !== "ok" || !payload?.stats || typeof payload.stats !== "object") {
    throw new Error("Nobitex returned an invalid market-stats response");
  }
  const rows = [];
  for (const [market, stats] of Object.entries(payload.stats as Record<string, any>)) {
    const match = /^([A-Z0-9]{2,20})-RLS$/i.exec(market);
    if (!match) continue;
    const asset = match[1].toUpperCase();
    const rialToToman = (value: unknown) => {
      const n = shiftDecimal(value, -1);
      return n !== null && compareDecimals(n, "0") > 0 ? n : null;
    };
    const row = makeRow("nobitex", asset, {
      price: rialToToman(stats.latest),
      bid: rialToToman(stats.bestBuy),
      ask: rialToToman(stats.bestSell),
      high: rialToToman(stats.dayHigh),
      low: rialToToman(stats.dayLow),
      change: normalizeDecimal(stats.dayChange, 18, 8),
      volume: shiftDecimal(stats.volumeDst, -1, 38, 8),
    }, fetchedAt);
    if (row) rows.push(row);
  }
  if (!rows.length) throw new Error("Nobitex returned no RLS-quoted crypto markets");
  return rows;
}

async function fetchWallex(fetchedAt: string) {
  const payload = await getJson("https://api.wallex.ir/v1/markets", "Wallex");
  const markets = payload?.result?.symbols;
  if (payload?.success !== true || !markets || typeof markets !== "object") {
    throw new Error("Wallex returned an invalid markets response");
  }
  const rows = [];
  for (const [market, item] of Object.entries(markets as Record<string, any>)) {
    const symbol = String(item?.symbol || market).toUpperCase();
    const match = /^([A-Z0-9]{2,20})(?:TMN|IRT)$/.exec(symbol);
    const quote = String(item?.quoteAsset || (symbol.endsWith("TMN") ? "TMN" : symbol.endsWith("IRT") ? "IRT" : "")).toUpperCase();
    if (!match || !["TMN", "IRT"].includes(quote)) continue;
    const stats = item?.stats || {};
    const row = makeRow("wallex", match[1], {
      price: decimalOrNull(stats.lastPrice),
      bid: decimalOrNull(stats.bidPrice),
      ask: decimalOrNull(stats.askPrice),
      high: decimalOrNull(stats["24h_highPrice"]),
      low: decimalOrNull(stats["24h_lowPrice"]),
      change: normalizeDecimal(stats["24h_ch"], 18, 8),
      volume: normalizeDecimal(stats["24h_quoteVolume"], 38, 8),
      nameFa: item.faBaseAsset || item.faName || null,
      nameEn: item.baseAsset || null,
    }, fetchedAt);
    if (row) rows.push(row);
  }
  if (!rows.length) throw new Error("Wallex returned no TMN/IRT-quoted crypto markets");
  return rows;
}

async function fetchMappedSymbols(
  exchange: "bit24" | "kifpool",
  supabaseUrl: string,
  serviceHeaders: Record<string, string>,
) {
  const url = new URL(supabaseUrl + "/rest/v1/exchange_asset_observations");
  url.searchParams.set("select", "base_symbol");
  url.searchParams.set("exchange", "eq." + exchange);
  url.searchParams.set("is_active", "eq.true");
  url.searchParams.set("coingecko_id", "not.is.null");
  url.searchParams.set("limit", "3000");
  const response = await fetch(url.toString(), {
    headers: serviceHeaders,
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error(exchange + " mapped-asset lookup failed: " + response.status);
  const rows = await response.json();
  if (!Array.isArray(rows)) throw new Error(exchange + " mapped-asset lookup returned invalid data");
  return new Set(rows.map((row: any) => String(row?.base_symbol || "").toUpperCase()).filter(validAsset));
}

async function fetchBit24(
  fetchedAt: string,
  supabaseUrl: string,
  serviceHeaders: Record<string, string>,
) {
  const [payload, mappedSymbols] = await Promise.all([
    getJson("https://pro.bit24.cash/api/v3/markets", "Bit24"),
    fetchMappedSymbols("bit24", supabaseUrl, serviceHeaders),
  ]);
  const markets: any[] = [];
  const visit = (value: any, depth = 0) => {
    if (!value || typeof value !== "object" || depth > 8) return;
    if (Array.isArray(value)) {
      for (const item of value) visit(item, depth + 1);
      return;
    }
    if (value.base_coin && value.quote_coin && value.market_24h_information) markets.push(value);
    for (const child of Object.values(value)) visit(child, depth + 1);
  };
  visit(payload);

  const rows = [];
  for (const item of markets) {
    const quote = String(item?.quote_coin?.symbol || "").toUpperCase();
    if (quote !== "IRT") continue;
    const asset = String(item?.base_coin?.symbol || "").toUpperCase();
    if (!validAsset(asset) || !mappedSymbols.has(asset)) continue;
    const stats = item?.market_24h_information || {};
    const price = decimalOrNull(stats.last_price);
    if (price === null || compareDecimals(price, "0") <= 0) continue;
    const row = makeRow("bit24", asset, {
      // last_price is the market's last traded price; each_price is not substituted.
      price,
      // This public ticker payload does not provide independent bid/ask values.
      high: decimalOrNull(stats.max_price),
      low: decimalOrNull(stats.min_price),
      change: normalizeDecimal(stats.change_percent, 18, 8),
      volume: normalizeDecimal(stats.quote_volume, 38, 8),
      nameFa: item?.base_coin?.fa_name || null,
      nameEn: item?.base_coin?.name || null,
    }, fetchedAt);
    if (row) rows.push(row);
  }
  if (!rows.length) throw new Error("Bit24 returned no mapped IRT markets with a valid last price");
  return rows;
}

const KIFPOOL_BODY = {
  operationName: "headerCoins",
  variables: { search: "", offset: 0, limit: 2000 },
  extensions: {
    persistedQuery: {
      version: 1,
      sha256Hash: "bb149e99c1d2da2ca162085286128da78a9bd3936198e47e28028e20961f6f3c",
    },
  },
};

const KIFPOOL_QUERY = `query headerCoins($search: String, $offset: Int, $limit: Int) {
  coinList(offset: $offset, limit: $limit, query: $search) {
    coins {
      ...CoinCardCore
      name
      priceSellIRT
      __typename
    }
    total
    __typename
  }
}

fragment CoinCardCore on CoinDetailType {
  faName
  smallImage
  price
  priceChangePercent
  slug
  nameId
  symbol
  __typename
}`;

async function fetchKifpool(
  fetchedAt: string,
  supabaseUrl: string,
  serviceHeaders: Record<string, string>,
) {
  const [mappedSymbols, response] = await Promise.all([
    fetchMappedSymbols("kifpool", supabaseUrl, serviceHeaders),
    fetch("https://kifpool.me/api/graphql", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        origin: "https://kifpool.me",
        referer: "https://kifpool.me/markets",
        "user-agent": "Mozilla/5.0 DigiArz-Toman-Market/1.0",
      },
      body: JSON.stringify(KIFPOOL_BODY),
      signal: AbortSignal.timeout(15000),
    }),
  ]);
  if (!response.ok) throw new Error("Kifpool HTTP " + response.status);
  let payload = parse(await response.text()) as any;
  const hashExpired = Array.isArray(payload?.errors) && payload.errors.some(
    (error: any) => error?.extensions?.code === "PERSISTED_QUERY_NOT_FOUND",
  );
  if (hashExpired) {
    // Apollo persisted-query hashes can change after a frontend deployment.
    const retry = await fetch("https://kifpool.me/api/graphql", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        origin: "https://kifpool.me",
        referer: "https://kifpool.me/markets",
        "user-agent": "Mozilla/5.0 DigiArz-Toman-Market/1.0",
      },
      body: JSON.stringify({ ...KIFPOOL_BODY, query: KIFPOOL_QUERY }),
      signal: AbortSignal.timeout(15000),
    });
    if (!retry.ok) throw new Error("Kifpool GraphQL fallback HTTP " + retry.status);
    payload = parse(await retry.text()) as any;
  }
  const coins = payload?.data?.coinList?.coins;
  if (!Array.isArray(coins) || payload?.errors?.length) {
    throw new Error("Kifpool returned an invalid persisted GraphQL market response");
  }

  const rows = [];
  for (const item of coins) {
    const asset = String(item?.symbol || "").toUpperCase();
    if (!validAsset(asset) || !mappedSymbols.has(asset)) continue;
    const price = decimalOrNull(item?.priceSellIRT);
    if (price === null || compareDecimals(price, "0") <= 0) continue;
    const row = makeRow("kifpool", asset, {
      // Kifpool exposes a sell-side IRT price only; never invent buy/bid/ask values.
      price,
      change: normalizeDecimal(item?.priceChangePercent, 18, 8),
      nameFa: item?.faName || null,
      nameEn: item?.name || null,
    }, fetchedAt);
    if (row) rows.push(row);
  }
  if (!rows.length) throw new Error("Kifpool returned no mapped assets with a valid priceSellIRT");
  return rows;
}

export const handler = async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ success: false, error: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = req.headers.get("Authorization") || "";
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return json({ success: false, error: "Server configuration is incomplete" }, 500);
  }
  if (!authorization.startsWith("Bearer ")) {
    return json({ success: false, error: "Authentication required" }, 401);
  }

  let stage = "auth_user";
  try {
    stage = "auth_user";
    const userResponse = await fetch(supabaseUrl + "/auth/v1/user", {
      headers: { apikey: anonKey, Authorization: authorization },
      signal: AbortSignal.timeout(8000),
    });
    if (!userResponse.ok) return json({ success: false, error: "Valid user session required" }, 401);

    const serviceHeaders = { apikey: serviceKey, Authorization: "Bearer " + serviceKey };
    stage = "cache_read";
    const latestResponse = await fetch(
      supabaseUrl + "/rest/v1/market_toman_prices?select=fetched_at&order=fetched_at.asc&limit=1",
      { headers: serviceHeaders, signal: AbortSignal.timeout(8000) },
    );
    if (!latestResponse.ok) throw new Error("Could not check Toman market cache");
    const latestRows = await latestResponse.json();
    const latestAt = latestRows?.[0]?.fetched_at ? new Date(latestRows[0].fetched_at).getTime() : 0;
    if (latestAt > 0 && Date.now() - latestAt < 45000) {
      return json({
        success: true, saved: 0, history_saved: 0, cached: true,
        updated_at: latestRows[0].fetched_at,
        sources: { cache: { ok: true, count: 0 } },
      });
    }

    const fetchedAt = new Date().toISOString();
    stage = "provider_fetch";
    const sourceResults = await Promise.allSettled([
      fetchNobitex(fetchedAt),
      fetchWallex(fetchedAt),
      fetchBit24(fetchedAt, supabaseUrl, serviceHeaders),
      fetchKifpool(fetchedAt, supabaseUrl, serviceHeaders),
    ]);
    const sourceNames = ["nobitex", "wallex", "bit24", "kifpool"];
    const providerResult = collectProviderResults(sourceNames, sourceResults);
    const { sources, rows } = providerResult;
    for (const provider of providerResult.failed) {
      console.warn("Toman market provider failed", { provider, error: sources[provider].error });
    }
    const emptyOutcome = emptyProviderOutcome(providerResult);
    if (emptyOutcome) return json(emptyOutcome.body, emptyOutcome.status);

    const deduped = dedupeMarketRows(rows);
    const writeRows = deduped.rows;
    if (!writeRows.length) {
      return json({
        success: false,
        error: "همه نمادها به‌دلیل تعارض قیمت تکراری کنار گذاشته شدند.",
        sources,
        dedupe: {
          duplicate_rows_removed: deduped.duplicateRowsRemoved,
          conflicting_symbols_skipped: deduped.conflictingSymbolsSkipped,
        },
      }, 502);
    }

    console.info("Toman market rows normalized", {
      received: rows.length,
      unique: writeRows.length,
      duplicate_rows_removed: deduped.duplicateRowsRemoved,
      conflicting_symbols_skipped: deduped.conflictingSymbolsSkipped,
    });

    stage = "price_upsert";
    const writeUrl = new URL(supabaseUrl + "/rest/v1/market_toman_prices");
    writeUrl.searchParams.set("on_conflict", "exchange,asset_symbol,quote_currency");
    const writeResponse = await fetch(writeUrl.toString(), {
      method: "POST",
      headers: {
        ...serviceHeaders, "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify(writeRows),
      signal: AbortSignal.timeout(15000),
    });
    if (!writeResponse.ok) {
      const detail = (await writeResponse.text()).slice(0, 220);
      console.error("Toman market upsert failed", { status: writeResponse.status, detail });
      throw new Error("Toman market upsert failed: " + writeResponse.status + " " + detail);
    }

    // Keep prior rows when a provider returns a partial snapshot.
    // The unique key bounds this table to one current row per exchange/asset/quote.
    // Staleness is surfaced by market_toman_performance; destructive cleanup is handled separately.

    let historySaved = 0;
    let historyWarning: string | null = null;
    stage = "history_rpc";
    try {
      const historyRows = writeRows.map(row => ({
        exchange: row.exchange, asset_symbol: row.asset_symbol,
        price_toman: row.price_toman, bid_toman: row.bid_toman,
        ask_toman: row.ask_toman, change_24h_pct: row.change_24h_pct,
        volume_24h_toman: row.volume_24h_toman,
        asset_name_fa: row.asset_name_fa, asset_name_en: row.asset_name_en,
        recorded_at: fetchedAt,
      }));
      const historyResponse = await fetch(
        supabaseUrl + "/rest/v1/rpc/insert_market_toman_history_if_due",
        {
          method: "POST",
          headers: { ...serviceHeaders, "Content-Type": "application/json" },
          body: JSON.stringify({ p_rows: historyRows }),
          signal: AbortSignal.timeout(15000),
        },
      );
      if (!historyResponse.ok) {
        throw new Error("Atomic history RPC failed: " + historyResponse.status + " " + (await historyResponse.text()).slice(0, 180));
      }
      historySaved = Number(await historyResponse.json()) || 0;
    } catch (error) {
      historyWarning = String(error).slice(0, 220);
    }

    return json({
      success: true, saved: writeRows.length, history_saved: historySaved,
      updated_at: fetchedAt, sources,
      dedupe: {
        received: rows.length,
        duplicate_rows_removed: deduped.duplicateRowsRemoved,
        conflicting_symbols_skipped: deduped.conflictingSymbolsSkipped,
      },
      ...(historyWarning ? { history_warning: historyWarning } : {}),
      note: "Prices are read-only market references in Toman. They are not used to execute demo trades.",
    });
  } catch (error) {
    const detail = String(error).slice(0, 300);
    console.error("Toman market refresh failed", { stage, error: detail });
    return json({ success: false, error: error instanceof Error ? error.message : String(error), stage }, 502);
  }
};

if (import.meta.main) Deno.serve(handler);
