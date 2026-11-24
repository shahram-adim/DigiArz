/**
 * Pure safety helpers shared by the sync Edge Function and Node regression tests.
 */

export function isSuperAdminRpcAuthorized(httpOk, responseBody) {
  return httpOk === true && responseBody === true;
}

/**
 * Collect every page from Bitpin's market catalog.
 * Pagination is constrained to the exact catalog origin and pathname.
 */
export async function collectBitpinMarketPages({
  firstPayload,
  catalogUrl,
  fetchPage,
  maxPages = 20,
}) {
  if (!firstPayload || !Array.isArray(firstPayload.results)) {
    throw new Error("Bitpin catalog response has no results array");
  }
  if (typeof fetchPage !== "function") {
    throw new Error("Bitpin pagination requires a fetch function");
  }
  if (!Number.isInteger(maxPages) || maxPages < 1) {
    throw new Error("Bitpin pagination maxPages must be a positive integer");
  }

  const catalog = new URL(catalogUrl);
  const rows = [...firstPayload.results];
  let nextPage = typeof firstPayload.next === "string" && firstPayload.next.length
    ? firstPayload.next
    : null;
  let pageCount = 1;

  while (nextPage && pageCount < maxPages) {
    const nextUrl = new URL(nextPage, catalog);
    if (nextUrl.origin !== catalog.origin || nextUrl.pathname !== catalog.pathname) {
      throw new Error("Bitpin pagination returned an unexpected URL");
    }

    const response = await fetchPage(nextUrl.toString());
    if (!response?.ok) {
      throw new Error(`Bitpin page ${pageCount + 1} HTTP ${response?.status ?? "unknown"}`);
    }

    const pagePayload = await response.json();
    if (!pagePayload || !Array.isArray(pagePayload.results)) {
      throw new Error("Bitpin pagination response has no results array");
    }

    rows.push(...pagePayload.results);
    nextPage = typeof pagePayload.next === "string" && pagePayload.next.length
      ? pagePayload.next
      : null;
    pageCount += 1;
  }

  if (nextPage) {
    throw new Error(`Bitpin catalog exceeded the ${maxPages}-page safety limit`);
  }

  return { ...firstPayload, results: rows, next: null };
}
