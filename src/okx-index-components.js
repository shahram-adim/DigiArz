'use strict';

const D = require('./decimal.js');

function parsePositiveDecimal(value, field) {
  if (typeof value !== 'string' || !/^\d+(?:\.\d+)?$/.test(value)) {
    throw new TypeError(field + ' must be a decimal string');
  }
  const parsed = D.parseDecimal(value, {
    allowNegative: false,
    maxFractionDigits: 36,
    maxIntegerDigits: 24
  });
  if (parsed.coefficient <= 0n) throw new RangeError(field + ' must be positive');
  return value;
}

function parseWeight(value) {
  if (typeof value !== 'string' || !/^\d+(?:\.\d+)?$/.test(value)) {
    throw new TypeError('component weight must be a decimal string');
  }
  const parsed = D.parseDecimal(value, {
    allowNegative: false,
    maxFractionDigits: 18,
    maxIntegerDigits: 2
  });
  if (parsed.coefficient <= 0n || D.compareDecimal(value, '1') > 0) {
    throw new RangeError('component weight must be in (0, 1]');
  }
  return value;
}

function parseOkxIndexComponents(rawBody, expectedIndex) {
  if (typeof rawBody !== 'string') throw new TypeError('raw response body must be a string');
  if (typeof expectedIndex !== 'string' || !/^[A-Z0-9]+-[A-Z0-9]+$/.test(expectedIndex)) {
    throw new TypeError('expected index is invalid');
  }

  let payload;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    throw new TypeError('response body is not valid JSON');
  }

  if (!payload || payload.code !== '0' || !payload.data || typeof payload.data !== 'object' || Array.isArray(payload.data)) {
    throw new Error('OKX index-components response is not successful');
  }
  const data = payload.data;
  if (data.index !== expectedIndex) throw new Error('OKX response index does not match the requested index');

  const indexPrice = parsePositiveDecimal(data.last, 'index last price');
  if (typeof data.ts !== 'string' || !/^\d{13}$/.test(data.ts) || BigInt(data.ts) <= 0n) {
    throw new TypeError('provider timestamp must be a 13-digit millisecond string');
  }
  if (!Array.isArray(data.components) || data.components.length === 0) {
    throw new TypeError('components must be a non-empty array');
  }

  let weightTotal = '0';
  const seenComponents = new Set();
  const components = data.components.map((item, position) => {
    if (!item || typeof item !== 'object' || Array.isArray(item)) throw new TypeError('component ' + position + ' must be an object');
    if (typeof item.exch !== 'string' || !item.exch.trim()) {
      throw new TypeError('component exchange label is missing');
    }
    if (typeof item.symbol !== 'string' || !/^[A-Z0-9]+\/[A-Z0-9]+$/.test(item.symbol)) {
      throw new TypeError('component raw spot pair is invalid');
    }
    const componentIdentity = JSON.stringify([item.exch, item.symbol]);
    if (seenComponents.has(componentIdentity)) {
      throw new Error('duplicate exchange and spot pair component');
    }
    seenComponents.add(componentIdentity);
    const weight = parseWeight(item.wgt);
    const sourcePrice = parsePositiveDecimal(item.symPx, 'component source price');
    const convertedPrice = parsePositiveDecimal(item.cnvPx, 'component converted price');
    weightTotal = D.addDecimal(weightTotal, weight);
    return Object.freeze({
      exchangeLabelRaw: item.exch,
      spotPairRaw: item.symbol,
      weight,
      sourcePrice,
      convertedPrice
    });
  });

  if (D.compareDecimal(weightTotal, '1') !== 0) {
    throw new Error('component weights must sum exactly to 1');
  }

  return Object.freeze({
    provider: 'OKX',
    schemaVersion: 'okx-index-components-v1',
    index: data.index,
    indexPrice,
    providerTimestampMs: data.ts,
    components: Object.freeze(components),
    componentWeightTotal: weightTotal
  });
}

module.exports = Object.freeze({ parseOkxIndexComponents });
