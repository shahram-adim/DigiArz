/**
 * Convert Promise.allSettled provider outcomes into a stable response summary.
 * A failed provider is isolated; fulfilled provider rows remain usable.
 */
export function collectProviderResults(sourceNames, settledResults) {
  if (!Array.isArray(sourceNames) || !Array.isArray(settledResults) || sourceNames.length !== settledResults.length) {
    throw new TypeError("Provider names and results must be matching arrays");
  }

  const sources = {};
  const rows = [];
  const failed = [];

  settledResults.forEach((result, index) => {
    const key = sourceNames[index];
    if (result?.status === "fulfilled" && Array.isArray(result.value)) {
      sources[key] = { ok: true, count: result.value.length };
      rows.push(...result.value);
      return;
    }

    const reason = result?.status === "rejected"
      ? result.reason
      : new TypeError("Provider returned a non-array result");
    const error = String(reason).slice(0, 220);
    sources[key] = { ok: false, count: 0, error };
    failed.push(key);
  });

  return { sources, rows, failed };
}

/** Return the HTTP outcome when every provider failed or yielded no usable rows. */
export function emptyProviderOutcome(result) {
  if (result.rows.length > 0) return null;
  return {
    status: 502,
    body: {
      success: false,
      error: "هیچ منبعی قیمت معتبر تومانی برنگرداند.",
      sources: result.sources,
    },
  };
}
