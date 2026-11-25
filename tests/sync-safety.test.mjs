import test from "node:test";
import assert from "node:assert/strict";
import {
  collectBitpinMarketPages,
  isSuperAdminRpcAuthorized,
} from "../src/sync-safety.mjs";

test("authorizes only an HTTP-successful RPC with the literal boolean true", () => {
  assert.equal(isSuperAdminRpcAuthorized(true, true), true);
  assert.equal(isSuperAdminRpcAuthorized(true, false), false);
  assert.equal(isSuperAdminRpcAuthorized(true, "true"), false);
  assert.equal(isSuperAdminRpcAuthorized(true, { data: true }), false);
  assert.equal(isSuperAdminRpcAuthorized(true, null), false);
  assert.equal(isSuperAdminRpcAuthorized(false, true), false);
});

test("collects all Bitpin pages from the exact catalog endpoint", async () => {
  const requested = [];
  const result = await collectBitpinMarketPages({
    catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
    firstPayload: {
      count: 3,
      results: [{ code: "BTC_IRT" }],
      next: "?page=2",
    },
    fetchPage: async (url, options) => {
      requested.push(url);
      assert.deepEqual(options, { redirect: "error" });
      return {
        ok: true,
        json: async () => ({
          results: [{ code: "ETH_IRT" }, { code: "SOL_IRT" }],
          next: null,
        }),
      };
    },
  });

  assert.deepEqual(requested, ["https://api.bitpin.ir/api/v1/mkt/markets/?page=2"]);
  assert.deepEqual(result.results.map((row) => row.code), ["BTC_IRT", "ETH_IRT", "SOL_IRT"]);
  assert.equal(result.next, null);
  assert.equal(result.count, 3);
});

test("rejects pagination to another origin", async () => {
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { results: [], next: "https://evil.example/api/v1/mkt/markets/?page=2" },
      fetchPage: async () => { throw new Error("must not fetch an untrusted URL"); },
    }),
    /unexpected URL/,
  );
});

test("rejects pagination to a different path on the same origin", async () => {
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { results: [], next: "/api/v1/private/export/" },
      fetchPage: async () => { throw new Error("must not fetch an unexpected path"); },
    }),
    /unexpected URL/,
  );
});

test("rejects unsuccessful page responses", async () => {
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { results: [], next: "?page=2" },
      fetchPage: async () => ({ ok: false, status: 503 }),
    }),
    /HTTP 503/,
  );
});

test("rejects malformed page payloads", async () => {
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { results: [], next: "?page=2" },
      fetchPage: async () => ({ ok: true, json: async () => ({ results: "not-an-array" }) }),
    }),
    /no results array/,
  );
});

test("fails closed when the catalog exceeds the page limit", async () => {
  let calls = 0;
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { results: [], next: "?page=2" },
      maxPages: 3,
      fetchPage: async () => {
        calls += 1;
        return {
          ok: true,
          json: async () => ({ results: [], next: `?page=${calls + 2}` }),
        };
      },
    }),
    /exceeded the 3-page safety limit/,
  );
  assert.equal(calls, 2);
});

test("rejects a first-page payload without a results array", async () => {
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { next: null },
      fetchPage: async () => ({ ok: true, json: async () => ({ results: [] }) }),
    }),
    /no results array/,
  );
});


test("rejects a pagination response that reports a followed redirect", async () => {
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { results: [], next: "?page=2" },
      fetchPage: async () => ({
        ok: true,
        redirected: true,
        url: "https://evil.example/redirected",
        json: async () => ({ results: [] }),
      }),
    }),
    /unexpected redirect/,
  );
});

test("rejects a response URL that escaped the exact Bitpin catalog endpoint", async () => {
  await assert.rejects(
    collectBitpinMarketPages({
      catalogUrl: "https://api.bitpin.ir/api/v1/mkt/markets/",
      firstPayload: { results: [], next: "?page=2" },
      fetchPage: async () => ({
        ok: true,
        redirected: false,
        url: "https://api.bitpin.ir/api/v1/private/export/",
        json: async () => ({ results: [] }),
      }),
    }),
    /unexpected URL/,
  );
});
