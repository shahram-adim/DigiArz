import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { extractPersianNameCandidate } from "../../../src/persian-asset-names.mjs";

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

const EXCHANGES = [
  { id: "nobitex", url: "https://apiv2.nobitex.ir/v2/options", kind: "nobitex" },
  { id: "wallex", url: "https://api.wallex.ir/v1/markets", kind: "markets" },
  { id: "bitpin", url: "https://api.bitpin.ir/api/v1/mkt/markets/", kind: "markets" },
  { id: "ramzinex", url: "https://api.ramzinex.ir/exchange/api/v1.0/exchange/pairs", kind: "markets" },
  { id: "tabdeal", url: "https://api-web.tabdeal.org/r/plots/currencies/dynamic-info/", kind: "markets" },
  { id: "ompfinex", url: "https://api.ompfinex.com/v2/market", kind: "markets" },
  { id: "exir", url: "https://api.exir.io/v2/ticker/all", kind: "markets" },
  { id: "abantether", url: "https://api.abantether.ir/api/v2/manager/coins", kind: "coins" },
  { id: "bit24", url: "https://pro.bit24.cash/api/v3/markets", kind: "markets" },
  { id: "balinex", url: "https://datafeed.balinex.com/api/datafeed", kind: "markets" },
  { id: "okex", url: "https://azapi.ok-ex.io/api/v1/asset/otc", kind: "markets" },
  { id: "tetherland", url: "https://service.tetherland.com/api/v5", kind: "markets" },
  { id: "kifpool", url: "https://kifpool.me/api/graphql", kind: "kifpool" },
] as const;

const norm = (v: unknown): string | null => {
  if (typeof v !== "string" && typeof v !== "number") return null;
  const s = String(v).trim().toUpperCase();
  return /^[A-Z0-9]{2,20}$/.test(s) ? s : null;
};
const get = (o: Record<string, unknown>, keys: string[]) => {
  for (const k of keys) if (o[k] !== undefined && o[k] !== null) return o[k];
  return null;
};
function records(root: unknown): Record<string, unknown>[] {
  const out: Record<string, unknown>[] = [];
  const seen = new Set<object>();
  const walk = (v: unknown, depth: number) => {
    if (!v || typeof v !== "object" || depth > 7 || seen.has(v as object)) return;
    seen.add(v as object);
    if (Array.isArray(v)) {
      for (const x of v.slice(0, 10000)) walk(x, depth + 1);
      return;
    }
    const o = v as Record<string, unknown>;
    const keys = Object.keys(o);
    if (keys.some(k => ["symbol","market","pair","baseAsset","base_currency","baseCurrency","currency","coin","currency1"].includes(k))) out.push(o);
    for (const [k, x] of Object.entries(o)) {
      if (["message","description","html"].includes(k)) continue;
      walk(x, depth + 1);
    }
  };
  walk(root, 0);
  return out;
}
function extract(exchange: typeof EXCHANGES[number], payload: unknown) {
  const out = new Map<string, Record<string, unknown>>();
  for (const o of records(payload)) {
    const bitpinBase = exchange.id === "bitpin" ? get(o, ["currency1"]) : null;
    const baseRaw = bitpinBase && typeof bitpinBase === "object"
      ? get(bitpinBase as Record<string, unknown>, ["code"])
      : get(o, ["baseAsset","base_asset","baseCurrency","base_currency","base","currency","coin","asset","code"]);
    const bitpinQuote = exchange.id === "bitpin" ? get(o, ["currency2"]) : null;
    const quoteRaw = bitpinQuote && typeof bitpinQuote === "object"
      ? get(bitpinQuote as Record<string, unknown>, ["code"])
      : get(o, ["quoteAsset","quote_asset","quoteCurrency","quote_currency","quote"]);
    const marketRaw = exchange.id === "bitpin"
      ? get(o, ["code"])
      : get(o, ["symbol","market","pair","marketSymbol","market_symbol","name"]);
    let base = norm(baseRaw);
    let quote = norm(quoteRaw);
    let market = typeof marketRaw === "string" ? marketRaw.trim().toUpperCase().replace(/[\s_]/g, "") : null;
    if (exchange.kind === "nobitex" || exchange.kind === "coins") {
      if (!base) base = norm(get(o, ["code","symbol","currency","coin"]));
      market = base ?? market;
    }
    if (exchange.kind === "kifpool") {
      const rawSymbol = get(o, ["symbol"]);
      const symbol = typeof rawSymbol === "string" ? rawSymbol.trim().toUpperCase() : "";
      if (/^[A-Z][A-Z0-9]{0,19}$/.test(symbol)) {
        base = symbol;
        market = symbol;
      } else {
        base = null;
        market = null;
      }
      quote = "IRT";
    }
    if (!base && market) {
      const m = market.replace(/[-_/]/g, "");
      const q = ["IRT","IRR","USDT","USDC","BTC","ETH"].find(x => m.endsWith(x) && m.length > x.length);
      if (q) { base = norm(m.slice(0, -q.length)); quote = q; }
    }
    if (!base || !market || market.length > 40) continue;
    const validMarket = exchange.kind === "kifpool"
      ? /^[A-Z][A-Z0-9_-]{0,39}$/.test(market)
      : /^[A-Z0-9_-]{2,40}$/.test(market);
    if (!validMarket) continue;
    const activeRaw = get(o, ["is_active","active","enabled","isEnabled","status","state"]);
    const inactive = activeRaw === false || activeRaw === 0 || ["inactive","disabled","delisted","closed","false"].includes(String(activeRaw).toLowerCase());
    const name = get(o, ["name","title","fullName","full_name"]);
    out.set(market, {
      exchange: exchange.id, market_symbol: market, base_symbol: base,
      quote_symbol: quote, asset_name: typeof name === "string" ? name.slice(0,120) : null,
      source_url: exchange.url, source_payload: { ...o, _digiarz_persian_name_candidate: extractPersianNameCandidate(exchange.id, o) }, is_active: !inactive,
    });
  }
  return [...out.values()];
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return Response.json({ error: "Authentication required" }, { status: 401 });

  const adminCheck = await fetch(`${supabaseUrl}/rest/v1/rpc/is_current_user_super_admin`, {
    method: "POST",
    headers: { apikey: anonKey, Authorization: auth, "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  if (!adminCheck.ok) return Response.json({ error: "Super administrator access required" }, { status: 403 });

  const results: Record<string, unknown>[] = [];
  for (const ex of EXCHANGES) {
    try {
      const response = ex.kind === "kifpool"
        ? await fetch(ex.url, {
            method: "POST",
            headers: {
              accept: "application/json",
              "content-type": "application/json",
              origin: "https://kifpool.me",
              referer: "https://kifpool.me/markets",
              "user-agent": "Mozilla/5.0 DigiArz-market-catalog/1.0",
            },
            body: JSON.stringify(KIFPOOL_BODY),
            signal: AbortSignal.timeout(15000),
          })
        : await fetch(ex.url, {
            headers: { accept: "application/json", "user-agent": "DigiArz-market-catalog/1.0" },
            signal: AbortSignal.timeout(12000),
          });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      let payload = await response.json();
      if (ex.id === "bitpin") {
        const marketRows = Array.isArray(payload?.results) ? [...payload.results] : [];
        let nextPage = typeof payload?.next === "string" ? payload.next : null;
        let pageCount = 1;
        const catalogOrigin = new URL(ex.url).origin;
        while (nextPage && pageCount < 20) {
          const nextUrl = new URL(nextPage, ex.url);
          if (nextUrl.origin !== catalogOrigin || !nextUrl.pathname.includes("/mkt/markets/")) {
            throw new Error("Bitpin pagination returned an unexpected URL");
          }
          const pageResponse = await fetch(nextUrl.toString(), {
            headers: { accept: "application/json", "user-agent": "DigiArz-market-catalog/1.0" },
            signal: AbortSignal.timeout(12000),
          });
          if (!pageResponse.ok) throw new Error(`Bitpin page ${pageCount + 1} HTTP ${pageResponse.status}`);
          const pagePayload = await pageResponse.json();
          if (!Array.isArray(pagePayload?.results)) throw new Error("Bitpin pagination response has no results array");
          marketRows.push(...pagePayload.results);
          nextPage = typeof pagePayload?.next === "string" ? pagePayload.next : null;
          pageCount += 1;
        }
        if (nextPage) throw new Error("Bitpin catalog exceeded the 20-page safety limit");
        payload = { ...payload, results: marketRows, next: null };
      }
      if (ex.kind === "kifpool" && (!payload?.data?.coinList?.coins || payload?.errors?.length)) {
        throw new Error("Kifpool persisted GraphQL market query failed");
      }
      const rows = extract(ex, payload);
      if (ex.kind === "kifpool" && rows.length < 100) {
        throw new Error(`Kifpool returned an unexpectedly small catalog: ${rows.length}`);
      }
      if (rows.length) {
        const write = await fetch(`${supabaseUrl}/rest/v1/exchange_asset_observations?on_conflict=exchange,market_symbol`, {
          method: "POST",
          headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, "Content-Type": "application/json", Prefer: "resolution=merge-duplicates,return=minimal" },
          body: JSON.stringify(rows.map(row => ({ ...row, last_seen_at: new Date().toISOString() }))),
        });
        if (!write.ok) throw new Error(`Database write failed: ${write.status} ${(await write.text()).slice(0,180)}`);
      }
      results.push({ exchange: ex.id, status: "ok", observations: rows.length });
    } catch (e) {
      results.push({ exchange: ex.id, status: "error", message: String(e).slice(0,240) });
    }
  }
  return Response.json({ success: results.some(x => x.status === "ok"), results, note: "Observations are staged only; no assets or demo trading pairs are automatically enabled." });
});
