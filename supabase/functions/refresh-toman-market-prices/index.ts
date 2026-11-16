import "jsr:@supabase/functions-js/edge-runtime.d.ts";

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

const numberOrNull = (...values: unknown[]): number | null => {
  for (const value of values) {
    if (value === null || value === undefined || value === "") continue;
    const parsed = Number(String(value).replace(/,/g, ""));
    if (Number.isFinite(parsed)) return parsed;
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
  return await response.json();
}

function makeRow(
  exchange: string,
  asset: string,
  values: {
    price: number | null; bid?: number | null; ask?: number | null;
    high?: number | null; low?: number | null; change?: number | null;
    volume?: number | null; nameFa?: string | null; nameEn?: string | null;
  },
  fetchedAt: string,
) {
  if (!validAsset(asset) || !Number.isFinite(values.price) || Number(values.price) <= 0) return null;
  const positive = (v: number | null | undefined) => v !== null && v !== undefined && Number.isFinite(v) && v > 0 ? v : null;
  const nonNegative = (v: number | null | undefined) => v !== null && v !== undefined && Number.isFinite(v) && v >= 0 ? v : null;
  return {
    exchange,
    asset_symbol: asset,
    quote_currency: "TOMAN",
    price_toman: values.price,
    bid_toman: positive(values.bid),
    ask_toman: positive(values.ask),
    high_24h_toman: positive(values.high),
    low_24h_toman: positive(values.low),
    change_24h_pct: values.change !== null && values.change !== undefined && Number.isFinite(values.change) ? values.change : null,
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
      const n = numberOrNull(value);
      return n !== null && n > 0 ? n / 10 : null;
    };
    const row = makeRow("nobitex", asset, {
      price: rialToToman(stats.latest),
      bid: rialToToman(stats.bestBuy),
      ask: rialToToman(stats.bestSell),
      high: rialToToman(stats.dayHigh),
      low: rialToToman(stats.dayLow),
      change: numberOrNull(stats.dayChange),
      volume: rialToToman(stats.volumeDst),
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
      price: numberOrNull(stats.lastPrice),
      bid: numberOrNull(stats.bidPrice),
      ask: numberOrNull(stats.askPrice),
      high: numberOrNull(stats["24h_highPrice"]),
      low: numberOrNull(stats["24h_lowPrice"]),
      change: numberOrNull(stats["24h_ch"]),
      volume: numberOrNull(stats["24h_quoteVolume"]),
      nameFa: item.faBaseAsset || item.faName || null,
      nameEn: item.baseAsset || null,
    }, fetchedAt);
    if (row) rows.push(row);
  }
  if (!rows.length) throw new Error("Wallex returned no TMN/IRT-quoted crypto markets");
  return rows;
}

function bitpinTickerEntries(payload: any): Array<[string, any]> {
  const source = payload?.results ?? payload?.data ?? payload?.tickers ?? payload;
  if (Array.isArray(source)) {
    return source.map((item: any) => [String(item?.symbol || item?.market || ""), item]);
  }
  if (source && typeof source === "object") {
    return Object.entries(source).map(([key, value]) => [
      String((value as any)?.symbol || (value as any)?.market || key), value,
    ]);
  }
  return [];
}

async function fetchBitpin(fetchedAt: string) {
  const payload = await getJson("https://api.bitpin.org/api/v1/mkt/tickers/", "Bitpin");
  const rows = [];
  for (const [rawSymbol, item] of bitpinTickerEntries(payload)) {
    const symbol = rawSymbol.toUpperCase().replace(/[\/-]/g, "_");
    const match = /^([A-Z0-9]{2,20})_?(?:IRT|TMN)$/.exec(symbol);
    if (!match) continue;
    const asset = match[1];
    const row = makeRow("bitpin", asset, {
      price: numberOrNull(item?.last, item?.last_price, item?.lastPrice, item?.price),
      bid: numberOrNull(item?.bid, item?.best_bid, item?.bidPrice),
      ask: numberOrNull(item?.ask, item?.best_ask, item?.askPrice),
      high: numberOrNull(item?.high, item?.high_price, item?.highPrice),
      low: numberOrNull(item?.low, item?.low_price, item?.lowPrice),
      change: numberOrNull(item?.percentage, item?.priceChangePercent, item?.price_change_percent, item?.change_percent),
      volume: numberOrNull(item?.quoteVolume, item?.quote_volume, item?.quote_volume_24h, item?.quoteVolume24h),
      nameFa: item?.base_asset_name_fa || item?.faBaseAsset || null,
      nameEn: item?.base_asset_name || item?.baseAsset || null,
    }, fetchedAt);
    if (row) rows.push(row);
  }
  if (!rows.length) throw new Error("Bitpin returned no IRT/TMN ticker rows in the recognized format");
  return rows;
}

Deno.serve(async (req: Request) => {
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

  try {
    const userResponse = await fetch(supabaseUrl + "/auth/v1/user", {
      headers: { apikey: anonKey, Authorization: authorization },
      signal: AbortSignal.timeout(8000),
    });
    if (!userResponse.ok) return json({ success: false, error: "Valid user session required" }, 401);

    const serviceHeaders = { apikey: serviceKey, Authorization: "Bearer " + serviceKey };
    const latestResponse = await fetch(
      supabaseUrl + "/rest/v1/market_toman_prices?select=fetched_at&order=fetched_at.desc&limit=1",
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
    const sourceResults = await Promise.allSettled([
      fetchNobitex(fetchedAt), fetchWallex(fetchedAt), fetchBitpin(fetchedAt),
    ]);
    const sourceNames = ["nobitex", "wallex", "bitpin"];
    const sources: Record<string, { ok: boolean; count: number; error?: string }> = {};
    const rows: any[] = [];
    sourceResults.forEach((result, index) => {
      const key = sourceNames[index];
      if (result.status === "fulfilled") {
        sources[key] = { ok: true, count: result.value.length };
        rows.push(...result.value);
      } else {
        sources[key] = { ok: false, count: 0, error: String(result.reason).slice(0, 220) };
      }
    });
    if (!rows.length) {
      return json({ success: false, error: "هیچ منبعی قیمت معتبر تومانی برنگرداند.", sources }, 502);
    }

    const writeResponse = await fetch(supabaseUrl + "/rest/v1/market_toman_prices", {
      method: "POST",
      headers: {
        ...serviceHeaders, "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify(rows),
      signal: AbortSignal.timeout(15000),
    });
    if (!writeResponse.ok) {
      throw new Error("Toman market write failed: " + writeResponse.status + " " + (await writeResponse.text()).slice(0, 220));
    }

    // Keep the current-price table compact; long-term snapshots live in the history table.
    let cleanupWarning: string | null = null;
    try {
      const cleanupUrl = new URL(supabaseUrl + "/rest/v1/market_toman_prices");
      cleanupUrl.searchParams.set("exchange", "in.(nobitex,wallex,bitpin)");
      cleanupUrl.searchParams.set("fetched_at", "lt." + fetchedAt);
      const cleanupResponse = await fetch(cleanupUrl.toString(), {
        method: "DELETE",
        headers: { ...serviceHeaders, Prefer: "return=minimal" },
        signal: AbortSignal.timeout(10000),
      });
      if (!cleanupResponse.ok) throw new Error("Current-price cleanup failed: " + cleanupResponse.status);
    } catch (error) {
      cleanupWarning = String(error).slice(0, 180);
    }

    let historySaved = 0;
    let historyWarning: string | null = null;
    try {
      const cutoff = new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString();
      const historyResponse = await fetch(
        supabaseUrl + "/rest/v1/market_toman_price_history?select=exchange,asset_symbol,recorded_at&recorded_at=gte." + encodeURIComponent(cutoff) + "&limit=10000",
        { headers: serviceHeaders, signal: AbortSignal.timeout(10000) },
      );
      if (!historyResponse.ok) throw new Error("History pre-check failed: " + historyResponse.status);
      const recentHistory = await historyResponse.json();
      const seen = new Set((recentHistory || []).map((item: any) => item.exchange + ":" + item.asset_symbol));
      const historyRows = rows
        .filter(row => !seen.has(row.exchange + ":" + row.asset_symbol))
        .map(row => ({
          exchange: row.exchange, asset_symbol: row.asset_symbol,
          price_toman: row.price_toman, bid_toman: row.bid_toman,
          ask_toman: row.ask_toman, change_24h_pct: row.change_24h_pct,
          volume_24h_toman: row.volume_24h_toman,
          asset_name_fa: row.asset_name_fa, asset_name_en: row.asset_name_en,
          recorded_at: fetchedAt,
        }));
      if (historyRows.length) {
        const historyWrite = await fetch(supabaseUrl + "/rest/v1/market_toman_price_history", {
          method: "POST",
          headers: { ...serviceHeaders, "Content-Type": "application/json", Prefer: "return=minimal" },
          body: JSON.stringify(historyRows),
          signal: AbortSignal.timeout(15000),
        });
        if (!historyWrite.ok) throw new Error("History write failed: " + historyWrite.status + " " + (await historyWrite.text()).slice(0, 180));
        historySaved = historyRows.length;
      }
    } catch (error) {
      historyWarning = String(error).slice(0, 220);
    }

    return json({
      success: true, saved: rows.length, history_saved: historySaved,
      updated_at: fetchedAt, sources,
      ...(historyWarning ? { history_warning: historyWarning } : {}),
      ...(cleanupWarning ? { cleanup_warning: cleanupWarning } : {}),
      note: "Prices are read-only market references in Toman. They are not used to execute demo trades.",
    });
  } catch (error) {
    return json({ success: false, error: error instanceof Error ? error.message : String(error) }, 502);
  }
});
