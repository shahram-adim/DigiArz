'use strict';
(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.DigiMarketHoldings = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  const QUOTE_ASSETS = ['USDT', 'IRT'];

  function isPositiveBalance(value) {
    if (typeof value === 'number') return Number.isFinite(value) && value > 0;
    if (typeof value === 'bigint') return value > 0n;
    if (typeof value !== 'string') return false;
    const text = value.trim();
    if (!text) return false;
    if (/^\\+?(?:\\d+(?:\\.\\d*)?|\\.\\d+)$/.test(text)) return /[1-9]/.test(text);
    const scientific = /^\\+?((?:\\d+(?:\\.\\d*)?|\\.\\d+))[eE][+-]?\\d+$/.exec(text);
    return !!scientific && /[1-9]/.test(scientific[1]);
  }

  function getOwnedAssets(assetRows, walletUsdt) {
    const byAsset = new Map();
    for (const item of Array.isArray(assetRows) ? assetRows : []) {
      const asset = String(item?.asset ?? '').trim().toUpperCase();
      if (!asset || asset === 'USDT' || !isPositiveBalance(item?.balance)) continue;
      byAsset.set(asset, { ...item, asset });
    }
    if (isPositiveBalance(walletUsdt)) {
      byAsset.set('USDT', { asset: 'USDT', balance: walletUsdt, source: 'wallets' });
    }
    return Array.from(byAsset.values());
  }

  function getBaseAsset(symbol) {
    const value = String(symbol ?? '').trim().toUpperCase();
    for (const quote of QUOTE_ASSETS) {
      if (value.length > quote.length && value.endsWith(quote)) return value.slice(0, -quote.length);
    }
    return value;
  }

  function filterMarketsByHoldings(marketRows, assetRows, walletUsdt) {
    const owned = new Set(getOwnedAssets(assetRows, walletUsdt).map(item => item.asset));
    return (Array.isArray(marketRows) ? marketRows : [])
      .filter(item => owned.has(getBaseAsset(item?.symbol)));
  }

  return Object.freeze({ isPositiveBalance, getOwnedAssets, getBaseAsset, filterMarketsByHoldings });
});
