'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { isPositiveBalance, getOwnedAssets, getBaseAsset, filterMarketsByHoldings } = require('../src/market-holdings.js');

test('positive holdings include the authoritative USDT wallet and exclude stale asset_balances USDT rows', () => {
  const owned = getOwnedAssets([
    { asset: 'btc', balance: '0.12500000' },
    { asset: 'ETH', balance: '0' },
    { asset: 'USDT', balance: '999.00' },
    { asset: 'XRP', balance: '-2' },
    { asset: 'DOGE', balance: 'not-a-number' }
  ], '12.50000000');
  assert.deepEqual(owned.map(item => item.asset).sort(), ['BTC', 'USDT']);
  assert.equal(owned.find(item => item.asset === 'USDT').balance, '12.50000000');
  assert.equal(owned.find(item => item.asset === 'USDT').source, 'wallets');
});

test('zero or invalid USDT wallet balance does not create an owned USDT asset', () => {
  assert.deepEqual(getOwnedAssets([{ asset: 'BTC', balance: '0' }], '0'), []);
  assert.deepEqual(getOwnedAssets([], 'invalid'), []);
  assert.deepEqual(getOwnedAssets([], '-1'), []);
});

test('positive-balance detection handles numeric, decimal-string and scientific values safely', () => {
  assert.equal(isPositiveBalance(1e-8), true);
  assert.equal(isPositiveBalance('0.00000001'), true);
  assert.equal(isPositiveBalance('1e-400'), true);
  assert.equal(isPositiveBalance('0.00000000'), false);
  assert.equal(isPositiveBalance('0'), false);
  assert.equal(isPositiveBalance('-0.1'), false);
  assert.equal(isPositiveBalance('NaN'), false);
});

test('base asset is extracted for both USDT and IRT quote pairs', () => {
  assert.equal(getBaseAsset('btcusdt'), 'BTC');
  assert.equal(getBaseAsset('BTCIRT'), 'BTC');
  assert.equal(getBaseAsset('USDTIRT'), 'USDT');
});

test('mine-market filter includes held base assets in both quote markets, not quote-only assets', () => {
  const markets = [
    { symbol: 'BTCUSDT' }, { symbol: 'BTCIRT' }, { symbol: 'ETHUSDT' },
    { symbol: 'USDTIRT' }, { symbol: 'XRPIRT' }
  ];
  const rows = filterMarketsByHoldings(markets, [{ asset: 'BTC', balance: '0.25' }, { asset: 'ETH', balance: '0' }], '4.5');
  assert.deepEqual(rows.map(item => item.symbol), ['BTCUSDT', 'BTCIRT', 'USDTIRT']);
});
