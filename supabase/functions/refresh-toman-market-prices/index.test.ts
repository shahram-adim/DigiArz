import { handler } from "./index.ts";

const envKeys = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY"] as const;

async function withMockedRuntime(
  mode: "timeout-wallex" | "malformed-nobitex" | "all-providers-fail" | "cache-read-fail" | "partial-cache-stale" | "kifpool-hash-expired" | "bit24-pagination",
  run: (writes: () => number, errorLog: () => unknown[] | null, cacheOrder: () => string | null, kifpoolRequests: () => number) => Promise<void>,
) {
  const previousEnv = new Map(envKeys.map((key) => [key, Deno.env.get(key)]));
  const originalFetch = globalThis.fetch;
  let writes = 0;
  let capturedError: unknown[] | null = null;
  let capturedCacheOrder: string | null = null;
  let kifpoolRequestCount = 0;
  const originalConsoleError = console.error;

  Deno.env.set("SUPABASE_URL", "https://digiarz-test.supabase.co");
  Deno.env.set("SUPABASE_ANON_KEY", "test-anon");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-role");

  console.error = (...args: unknown[]) => { capturedError = args; };
  globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input);

    if (url.endsWith("/auth/v1/user")) return new Response("{}", { status: 200 });
    if (url.includes("/rest/v1/market_toman_prices?select=fetched_at")) {
      capturedCacheOrder = new URL(url).searchParams.get("order");
      if (mode === "cache-read-fail") return new Response("database unavailable", { status: 503 });
      if (mode === "partial-cache-stale") return Response.json([{ fetched_at: "2026-11-17T22:04:26.622Z" }]);
      return new Response("[]", { status: 200 });
    }
    if (url.includes("/rest/v1/exchange_asset_observations?")) {
      const exchange = new URL(url).searchParams.get("exchange");
      return Response.json(
        (exchange === "eq.kifpool" && mode === "kifpool-hash-expired") ||
        (exchange === "eq.bit24" && mode === "bit24-pagination")
          ? [{ base_symbol: "BTC" }]
          : [],
      );
    }
    if (url.includes("/rest/v1/market_toman_prices?on_conflict=")) {
      writes += 1;
      return new Response(null, { status: 204 });
    }
    if (url.includes("/rest/v1/rpc/insert_market_toman_history_if_due")) {
      return new Response("0", { status: 200 });
    }

    if (url.includes("apiv2.nobitex.ir")) {
      if (mode === "all-providers-fail") throw new Error("Nobitex unavailable");
      if (mode === "malformed-nobitex") return new Response("{broken", { status: 200 });
      return Response.json({
        status: "ok",
        stats: {
          "BTC-RLS": {
            latest: "123456789",
            bestBuy: "123456700",
            bestSell: "123456800",
            dayHigh: "130000000",
            dayLow: "120000000",
            dayChange: "1.25",
            volumeDst: "1000000000",
          },
        },
      });
    }

    if (url.includes("api.wallex.ir")) {
      if (mode === "all-providers-fail") throw new Error("Wallex unavailable");
      if (mode === "timeout-wallex") throw new DOMException("request timed out", "AbortError");
      return Response.json({
        success: true,
        result: {
          symbols: {
            BTCIRT: {
              symbol: "BTCIRT",
              quoteAsset: "IRT",
              baseAsset: "Bitcoin",
              stats: {
                lastPrice: "12345678",
                bidPrice: "12345000",
                askPrice: "12346000",
                "24h_highPrice": "13000000",
                "24h_lowPrice": "12000000",
                "24h_ch": "1.2",
                "24h_quoteVolume": "500000000",
              },
            },
          },
        },
      });
    }

    if (url.includes("pro.bit24.cash")) {
      if (mode === "all-providers-fail") throw new Error("Bit24 unavailable");
      if (mode === "bit24-pagination") {
        const page = Number(new URL(url).searchParams.get("page") || "1");
        if (page === 1) return Response.json({ data: { results: [], last_page: 2 } });
        return Response.json({
          data: {
            last_page: 2,
            results: [{
              base_coin: { symbol: "BTC", name: "Bitcoin", fa_name: "بیت کوین" },
              quote_coin: { symbol: "IRT", name: "Toman" },
              market_24h_information: {
                last_price: "123456789",
                max_price: "130000000",
                min_price: "120000000",
                change_percent: "1.25",
                quote_volume: "1000000000",
              },
            }],
          },
        });
      }
      return Response.json({ data: { results: [], last_page: 1 } });
    }

    if (url.includes("kifpool.me/api/graphql")) {
      if (mode === "all-providers-fail") throw new Error("Kifpool unavailable");
      kifpoolRequestCount += 1;
      if (mode === "kifpool-hash-expired" && kifpoolRequestCount === 1) {
        return Response.json({ errors: [{ extensions: { code: "PERSISTED_QUERY_NOT_FOUND" } }] });
      }
      if (mode === "kifpool-hash-expired") {
        const body = JSON.parse(String(init?.body || "{}"));
        if (typeof body.query !== "string" || !body.query.includes("priceSellIRT")) {
          throw new Error("Kifpool fallback query text was not sent");
        }
        return Response.json({ data: { coinList: { coins: [{ symbol: "BTC", priceSellIRT: "123456789", priceChangePercent: "1.25", faName: "بیت کوین", name: "Bitcoin" }] } } });
      }
      return Response.json({ data: { coinList: { coins: [] } } });
    }

    throw new Error("Unexpected test fetch URL: " + url + " " + String(init?.method || "GET"));
  }) as typeof fetch;

  try {
    await run(() => writes, () => capturedError, () => capturedCacheOrder, () => kifpoolRequestCount);
  } finally {
    globalThis.fetch = originalFetch;
    console.error = originalConsoleError;
    for (const key of envKeys) {
      const value = previousEnv.get(key);
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
  }
}

Deno.test("Toman refresh HTTP handler isolates provider failures and refuses empty snapshots", async (t) => {
  await t.step("provider timeout does not block successful sources", async () => {
    await withMockedRuntime("timeout-wallex", async (writes) => {
      const response = await handler(new Request("https://edge.test/refresh", {
        method: "POST",
        headers: { Authorization: "Bearer test-user-token" },
      }));
      const body = await response.json();
      if (response.status !== 200) throw new Error("Expected 200, got " + response.status);
      if (body.success !== true || body.sources.nobitex.ok !== true) throw new Error("Healthy provider rows were not retained");
      if (body.sources.wallex.ok !== false) throw new Error("Timed-out provider was not marked failed");
      if (writes() !== 1) throw new Error("Expected exactly one current-price upsert");
    });
  });

  await t.step("malformed JSON is isolated to its provider", async () => {
    await withMockedRuntime("malformed-nobitex", async (writes) => {
      const response = await handler(new Request("https://edge.test/refresh", {
        method: "POST",
        headers: { Authorization: "Bearer test-user-token" },
      }));
      const body = await response.json();
      if (response.status !== 200) throw new Error("Expected 200, got " + response.status);
      if (body.sources.nobitex.ok !== false) throw new Error("Malformed Nobitex JSON was accepted");
      if (body.sources.wallex.ok !== true) throw new Error("Healthy Wallex rows were lost");
      if (writes() !== 1) throw new Error("Expected exactly one current-price upsert");
    });
  });

  await t.step("all provider failures return 502 and never write an empty snapshot", async () => {
    await withMockedRuntime("all-providers-fail", async (writes) => {
      const response = await handler(new Request("https://edge.test/refresh", {
        method: "POST",
        headers: { Authorization: "Bearer test-user-token" },
      }));
      const body = await response.json();
      if (response.status !== 502 || body.success !== false) throw new Error("Expected an explicit 502 failure");
      if (writes() !== 0) throw new Error("An empty provider snapshot must never be written");
    });
  });

  await t.step("cache failures expose a structured diagnostic stage", async () => {
    await withMockedRuntime("cache-read-fail", async (writes, errorLog) => {
      const response = await handler(new Request("https://edge.test/refresh", {
        method: "POST",
        headers: { Authorization: "Bearer test-user-token" },
      }));
      const body = await response.json();
      if (response.status !== 502 || body.stage !== "cache_read") {
        throw new Error("Cache failure did not expose the cache_read stage");
      }
      const logged = errorLog();
      if (!logged || logged[0] !== "Toman market refresh failed") {
        throw new Error("Structured failure log was not emitted");
      }
      if (writes() !== 0) throw new Error("Cache failure must not write market rows");
    });
  });

  await t.step("a recent partial snapshot cannot hide older stale rows", async () => {
    await withMockedRuntime("partial-cache-stale", async (writes, _errorLog, cacheOrder) => {
      const response = await handler(new Request("https://edge.test/refresh", {
        method: "POST",
        headers: { Authorization: "Bearer test-user-token" },
      }));
      const body = await response.json();
      if (response.status !== 200 || body.cached === true) {
        throw new Error("A stale oldest row was incorrectly treated as a fresh cache");
      }
      if (cacheOrder() !== "fetched_at.asc") {
        throw new Error("Cache freshness must be determined by the oldest row");
      }
      if (body.sources.nobitex.ok !== true) throw new Error("Provider refresh did not run for stale rows");
      if (writes() !== 1) throw new Error("Expected a refresh upsert after detecting stale rows");
    });
  });


  await t.step("Kifpool retries with GraphQL text when its persisted query hash expires", async () => {
    await withMockedRuntime("kifpool-hash-expired", async (writes, _errorLog, _cacheOrder, kifpoolRequests) => {
      const response = await handler(new Request("https://edge.test/refresh", {
        method: "POST",
        headers: { Authorization: "Bearer test-user-token" },
      }));
      const body = await response.json();
      if (response.status !== 200) throw new Error("Expected 200 after Kifpool fallback, got " + response.status);
      if (body.sources.kifpool.ok !== true) throw new Error("Kifpool fallback response was not accepted");
      if (kifpoolRequests() !== 2) throw new Error("Expected one persisted-query request and one text-query retry");
      if (writes() !== 1) throw new Error("Expected one aggregated current-price upsert");
    });
  });

  await t.step("Bit24 fetches later pages and retains a mapped IRT market", async () => {
    await withMockedRuntime("bit24-pagination", async (writes) => {
      const response = await handler(new Request("https://edge.test/refresh", {
        method: "POST",
        headers: { Authorization: "Bearer test-user-token" },
      }));
      const body = await response.json();
      if (response.status !== 200) throw new Error("Expected 200 for paginated Bit24 market");
      if (body.sources.bit24.ok !== true || body.sources.bit24.count !== 1) {
        throw new Error("Bit24 market from page two was not retained");
      }
      if (writes() !== 1) throw new Error("Expected one aggregated market upsert");
    });
  });
  });
});
