'use strict';
(function (root, factory) {
  const api = factory(root && root.DigiDecimal);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.DigiPortfolioValuation = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (D) {
  'use strict';
  if (!D) throw new Error('DigiDecimal is required for portfolio valuation');
  const SCALE = 8;

  function canonical(value) {
    try {
      const parsed = D.parseDecimal(String(value ?? '0'), {
        maxFractionDigits: 18,
        maxIntegerDigits: 24
      });
      return D.toString(parsed);
    } catch (_) {
      return null;
    }
  }

  function positiveOrZero(value) {
    const parsed = canonical(value);
    return parsed !== null && D.compareDecimal(parsed, '0') > 0 ? parsed : '0';
  }

  function value(quantity, unitPrice, scale = SCALE) {
    const q = canonical(quantity), p = canonical(unitPrice);
    if (q === null || p === null || D.compareDecimal(q, '0') < 0 || D.compareDecimal(p, '0') < 0) {
      return null;
    }
    return D.multiplyDecimal(q, p, scale);
  }

  function sum(values, scale = SCALE) {
    return (Array.isArray(values) ? values : []).reduce((total, item) => {
      const parsed = canonical(item);
      if (parsed === null) throw new TypeError('Invalid portfolio amount');
      return D.addDecimal(total, parsed, scale);
    }, '0');
  }

  return Object.freeze({ canonical, positiveOrZero, value, sum, SCALE });
});
