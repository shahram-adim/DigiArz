'use strict';
(function (root, factory) {
  const api = factory(root && root.DigiDecimal);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.DigiPortfolioValuation = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (D) {
  'use strict';
  if (!D) throw new Error('DigiDecimal is required for portfolio valuation');
  const SCALE = 18;
  const OPTIONS = { allowNegative: true, maxFractionDigits: 18, maxIntegerDigits: 24 };

  function parse(value) {
    return D.parseDecimal(String(value ?? '0'), OPTIONS);
  }

  function canonical(value) {
    try { return D.toString(parse(value)); } catch (_) { return null; }
  }

  function compare(a, b) {
    return D.compareDecimal(parse(a), parse(b));
  }

  function positiveOrZero(value) {
    try {
      const parsed = parse(value);
      return parsed.coefficient > 0n ? D.toString(parsed) : '0';
    } catch (_) {
      return '0';
    }
  }

  function value(quantity, unitPrice, scale = SCALE) {
    try {
      const q = parse(quantity), p = parse(unitPrice);
      if (q.coefficient < 0n || p.coefficient < 0n) return null;
      return D.multiplyDecimal(q, p, scale);
    } catch (_) {
      return null;
    }
  }

  function sum(values, scale = SCALE) {
    let total = parse('0');
    for (const item of Array.isArray(values) ? values : []) {
      const parsed = parse(item);
      if (parsed.coefficient < 0n) throw new TypeError('Negative portfolio amount');
      total = parse(D.addDecimal(total, parsed, scale));
    }
    return D.toString(total);
  }

  return Object.freeze({ canonical, compare, positiveOrZero, value, sum, SCALE });
});
