(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.DigiDecimal = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const POW10 = [1n];
  function pow10(n) {
    if (!Number.isInteger(n) || n < 0 || n > 1000) throw new RangeError('Invalid decimal scale');
    while (POW10.length <= n) POW10.push(POW10[POW10.length - 1] * 10n);
    return POW10[n];
  }
  function normalize(coefficient, scale) {
    if (coefficient === 0n) return { coefficient: 0n, scale: 0 };
    while (scale > 0 && coefficient % 10n === 0n) { coefficient /= 10n; scale--; }
    return { coefficient, scale };
  }
  function parseDecimal(input, options) {
    const opts = options || {};
    const maxFractionDigits = opts.maxFractionDigits === undefined ? 18 : opts.maxFractionDigits;
    const maxIntegerDigits = opts.maxIntegerDigits === undefined ? 16 : opts.maxIntegerDigits;
    const allowNegative = opts.allowNegative === true;
    if (typeof input !== 'string' && typeof input !== 'number' && typeof input !== 'bigint') throw new TypeError('Decimal must be a string or integer');
    const text = String(input);
    if (!text || text !== text.trim() || !/^-?\d+(?:\.\d+)?$/.test(text)) throw new TypeError('Invalid decimal syntax');
    if (text[0] === '-' && !allowNegative) throw new RangeError('Negative values are not allowed');
    const unsigned = text[0] === '-' ? text.slice(1) : text;
    const parts = unsigned.split('.');
    const integer = parts[0], fraction = parts[1] || '';
    if (integer.replace(/^0+(?=\d)/, '').length > maxIntegerDigits) throw new RangeError('Too many integer digits');
    if (fraction.length > maxFractionDigits) throw new RangeError('Too many fractional digits');
    const digits = (integer + fraction).replace(/^0+(?=\d)/, '');
    let coefficient = BigInt(digits || '0');
    if (text[0] === '-') coefficient = -coefficient;
    const value = normalize(coefficient, fraction.length);
    return { coefficient: value.coefficient, scale: value.scale };
  }
  function toString(value) {
    const v = typeof value === 'string' ? parseDecimal(value, { allowNegative: true }) : value;
    const negative = v.coefficient < 0n;
    let digits = (negative ? -v.coefficient : v.coefficient).toString();
    if (v.scale) { digits = digits.padStart(v.scale + 1, '0'); digits = digits.slice(0, -v.scale) + '.' + digits.slice(-v.scale); }
    return (negative ? '-' : '') + digits;
  }
  function align(a, b) {
    const x = typeof a === 'string' ? parseDecimal(a, { allowNegative: true }) : a;
    const y = typeof b === 'string' ? parseDecimal(b, { allowNegative: true }) : b;
    const scale = Math.max(x.scale, y.scale);
    return { x: x.coefficient * pow10(scale - x.scale), y: y.coefficient * pow10(scale - y.scale), scale };
  }
  function compareDecimal(a, b) { const v = align(a, b); return v.x < v.y ? -1 : v.x > v.y ? 1 : 0; }
  function roundToScale(value, targetScale) {
    if (!Number.isInteger(targetScale) || targetScale < 0 || targetScale > 1000) throw new RangeError('Invalid target scale');
    if (value.scale <= targetScale) return normalize(value.coefficient * pow10(targetScale - value.scale), targetScale);
    const divisor = pow10(value.scale - targetScale), quotient = value.coefficient / divisor, remainder = value.coefficient % divisor;
    const absRemainder = remainder < 0n ? -remainder : remainder;
    const rounded = absRemainder * 2n >= divisor ? quotient + (value.coefficient < 0n ? -1n : 1n) : quotient;
    return normalize(rounded, targetScale);
  }
  function addDecimal(a, b, scale) {
    const v = align(a, b), target = scale === undefined ? v.scale : scale;
    return toString(roundToScale({ coefficient: v.x + v.y, scale: v.scale }, target));
  }
  function subtractDecimal(a, b, scale) {
    const v = align(a, b), target = scale === undefined ? v.scale : scale;
    return toString(roundToScale({ coefficient: v.x - v.y, scale: v.scale }, target));
  }
  function multiplyDecimal(a, b, scale, rounding) {
    const x = typeof a === 'string' ? parseDecimal(a, { allowNegative: true }) : a;
    const y = typeof b === 'string' ? parseDecimal(b, { allowNegative: true }) : b;
    const result = { coefficient: x.coefficient * y.coefficient, scale: x.scale + y.scale };
    if (rounding === 'down' && result.scale > scale) return toString(normalize(result.coefficient / pow10(result.scale - scale), scale));
    return toString(roundToScale(result, scale));
  }
  function divideDecimal(a, b, scale, rounding) {
    const x = typeof a === 'string' ? parseDecimal(a, { allowNegative: true }) : a;
    const y = typeof b === 'string' ? parseDecimal(b, { allowNegative: true }) : b;
    if (y.coefficient === 0n) throw new RangeError('Division by zero');
    const exponent = scale + y.scale - x.scale;
    let numerator = x.coefficient, denominator = y.coefficient;
    if (exponent >= 0) numerator *= pow10(exponent); else denominator *= pow10(-exponent);
    let quotient = numerator / denominator;
    const remainder = numerator % denominator;
    if (rounding !== 'down' && (remainder < 0n ? -remainder : remainder) * 2n >= (denominator < 0n ? -denominator : denominator)) quotient += (numerator < 0n) !== (denominator < 0n) ? -1n : 1n;
    return toString(normalize(quotient, scale));
  }
  function formatDecimal(value, options) {
    const opts = options || {}, maxFractionDigits = opts.maxFractionDigits === undefined ? 18 : opts.maxFractionDigits;
    const minFractionDigits = opts.minFractionDigits === undefined ? 0 : opts.minFractionDigits, grouping = opts.grouping !== false;
    const parsed = typeof value === 'string' ? parseDecimal(value, { allowNegative: true, maxFractionDigits: 1000, maxIntegerDigits: 1000 }) : value;
    const text = toString(roundToScale(parsed, maxFractionDigits));
    let [integer, fraction = ''] = text.split('.');
    fraction = fraction.replace(/0+$/, '');
    while (fraction.length < minFractionDigits) fraction += '0';
    if (grouping) integer = integer.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return integer + (fraction ? '.' + fraction : '');
  }
  return Object.freeze({ parseDecimal, compareDecimal, addDecimal, subtractDecimal, multiplyDecimal, divideDecimal, formatDecimal, toString });
});