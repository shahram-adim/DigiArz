import { handler } from "./index.ts";

const envKeys = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY"] as const;

async function withMockedRuntime(
  mode: "timeout-wallex" | "malformed-nobitex" | "all-providers-fail",
  run: (writes: () => number) => Promise<void>,
) {
  const previousEnv = new Map(envKeys.map((key) => [key, Deno.env.get(key)]));
  const originalFetch = globalThis.fetch;
  let writes = 0;

  Deno.env.set("SUPABASE_URL", "https://digiarz-test.supabase.co");
  Deno.env.set("SUPABASE_ANON_KEY", "test-anon");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-role");

  globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input);

    if (url.endsWith("/auth/v1/user")) return new Response("{}", { status: 200 });
    if (url.includes("/rest/v1/market_toman_prices?select=fetched_at")) {
      return new Response("[]", { status: 200 });
    }
    if (url.includes("/rest/v1/exchange_asset_observations?")) {
      return new Response("[]", { status: 200 });
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
      return Response.json({ data: [] });
    }

    if (url.includes("kifpool.me/api/graphql")) {
      if (mode === "all-providers-fail") throw new Error("Kifpool unavailable");
      return Response.json({ data: { coinList: { coins: [] } } });
    }

    throw new Error("Unexpected test fetch URL: " + url + " " + String(init?.method || "GET"));
  }) as typeof fetch;

  try {
    await run(() => writes);
  } finally {
    globalThis.fetch = originalFetch;
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
});
