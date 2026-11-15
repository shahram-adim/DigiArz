(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.DigiArzDecimal = factory();
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  const POW10 = [1n];
  function pow10(n) {
    if (!Number.isInteger(n) || n < 0 || n > 100) throw new RangeError('scale out of range');
    while (POW10.length <= n) POW10.push(POW10[POW10.length - 1] * 10n);
    return POW10[n];
  }

  function parseParts(value, options) {
    const opts = options || {};
    if (typeof value !== 'string') throw new TypeError('decimal value must be a string');
    if (!/^-?\d+(?:\.\d+)?$/.test(value)) throw new TypeError('invalid decimal string');
    const negative = value[0] === '-';
    if (negative && opts.allowNegative === false) throw new RangeError('negative values are not allowed');
    const unsigned = negative ? value.slice(1) : value;
    const pieces = unsigned.split('.');
    const integerRaw = pieces[0];
    const fractionRaw = pieces[1] || '';
    const integerDigits = integerRaw.replace(/^0+/, '').length || 1;
    const maxIntegerDigits = opts.maxIntegerDigits === undefined ? 20 : opts.maxIntegerDigits;
    const maxFractionDigits = opts.maxFractionDigits === undefined ? 18 : opts.maxFractionDigits;
    if (!Number.isInteger(maxIntegerDigits) || maxIntegerDigits < 1 || maxIntegerDigits > 20) throw new RangeError('invalid integer precision limit');
    if (!Number.isInteger(maxFractionDigits) || maxFractionDigits < 0 || maxFractionDigits > 18) throw new RangeError('invalid fractional precision limit');
    if (integerDigits > maxIntegerDigits) throw new RangeError('integer range exceeded');
    if (fractionRaw.length > maxFractionDigits) throw new RangeError('fractional precision exceeded');
    const digits = (integerRaw + fractionRaw).replace(/^0+(?=\d)/, '');
    let coefficient = BigInt(digits || '0');
    if (negative && coefficient !== 0n) coefficient = -coefficient;
    let scale = fractionRaw.length;
    while (scale > 0 && coefficient % 10n === 0n) {
      coefficient /= 10n;
      scale--;
    }
    return { coefficient, scale };
  }

  function partsToString(parts) {
    let coefficient = parts.coefficient;
    let scale = parts.scale;
    const negative = coefficient < 0n;
    if (negative) coefficient = -coefficient;
    while (scale > 0 && coefficient % 10n === 0n) {
      coefficient /= 10n;
      scale--;
    }
    let digits = coefficient.toString();
    if (scale > 0) {
      digits = digits.padStart(scale + 1, '0');
      const split = digits.length - scale;
      digits = digits.slice(0, split) + '.' + digits.slice(split);
    }
    return (negative && coefficient !== 0n ? '-' : '') + digits;
  }

  function rescale(parts, scale, rounding) {
    if (!Number.isInteger(scale) || scale < 0 || scale > 18) throw new RangeError('output scale out of range');
    if (parts.scale <= scale) return { coefficient: parts.coefficient * pow10(scale - parts.scale), scale };
    const divisor = pow10(parts.scale - scale);
    let q = parts.coefficient / divisor;
    const rem = parts.coefficient % divisor;
    if (rounding === 'half-up' && (rem < 0n ? -rem : rem) * 2n >= divisor) q += parts.coefficient < 0n ? -1n : 1n;
    else if (rounding !== undefined && rounding !== 'down' && rounding !== 'half-up') throw new TypeError('unsupported rounding mode');
    return { coefficient: q, scale };
  }

  function align(a, b) {
    const scale = Math.max(a.scale, b.scale);
    return {
      a: a.coefficient * pow10(scale - a.scale),
      b: b.coefficient * pow10(scale - b.scale),
      scale
    };
  }

  function parseDecimal(value, options) { return partsToString(parseParts(value, options)); }

  function compareDecimal(a, b) {
    const p = align(parseParts(a), parseParts(b));
    return p.a < p.b ? -1 : p.a > p.b ? 1 : 0;
  }

  function addDecimal(a, b, scale) {
    const p = align(parseParts(a), parseParts(b));
    const result = { coefficient: p.a + p.b, scale: p.scale };
    return partsToString(scale === undefined ? result : rescale(result, scale, 'down'));
  }

  function subtractDecimal(a, b, scale) {
    const p = align(parseParts(a), parseParts(b));
    const result = { coefficient: p.a - p.b, scale: p.scale };
    return partsToString(scale === undefined ? result : rescale(result, scale, 'down'));
  }

  function multiplyDecimal(a, b, scale, rounding) {
    if (scale === undefined) scale = 18;
    const x = parseParts(a), y = parseParts(b);
    return partsToString(rescale({ coefficient: x.coefficient * y.coefficient, scale: x.scale + y.scale }, scale, rounding || 'down'));
  }

  function divideDecimal(a, b, scale, rounding) {
    if (scale === undefined) scale = 18;
    const x = parseParts(a), y = parseParts(b);
    if (y.coefficient === 0n) throw new RangeError('division by zero');
    if (!Number.isInteger(scale) || scale < 0 || scale > 18) throw new RangeError('output scale out of range');
    const numerator = x.coefficient * pow10(y.scale + scale);
    const denominator = y.coefficient * pow10(x.scale);
    let q = numerator / denominator;
    const rem = numerator % denominator;
    if (rounding === 'half-up' && (rem < 0n ? -rem : rem) * 2n >= (denominator < 0n ? -denominator : denominator)) q += (numerator < 0n) !== (denominator < 0n) ? -1n : 1n;
    else if (rounding !== undefined && rounding !== 'down' && rounding !== 'half-up') throw new TypeError('unsupported rounding mode');
    return partsToString({ coefficient: q, scale });
  }

  function formatDecimal(value, options) {
    const opts = options || {};
    const maxFractionDigits = opts.maxFractionDigits === undefined ? 18 : opts.maxFractionDigits;
    const minFractionDigits = opts.minFractionDigits === undefined ? 0 : opts.minFractionDigits;
    if (!Number.isInteger(minFractionDigits) || minFractionDigits < 0 || minFractionDigits > 18 ||
        !Number.isInteger(maxFractionDigits) || maxFractionDigits < minFractionDigits || maxFractionDigits > 18) {
      throw new RangeError('invalid display precision');
    }
    const parts = rescale(parseParts(value), maxFractionDigits, opts.rounding || 'down');
    let s = partsToString(parts);
    let [integer, fraction = ''] = s.split('.');
    const negative = integer[0] === '-';
    const absInteger = negative ? integer.slice(1) : integer;
    const grouped = absInteger.replace(/\B(?=(\d{3})+(?!\d))/g, opts.groupSeparator === undefined ? ',' : opts.groupSeparator);
    while (fraction.length > minFractionDigits && fraction.endsWith('0')) fraction = fraction.slice(0, -1);
    fraction = fraction.padEnd(minFractionDigits, '0');
    return (negative ? '-' : '') + grouped + (fraction ? (opts.decimalSeparator === undefined ? '.' : opts.decimalSeparator) + fraction : '');
  }

  return Object.freeze({ parseDecimal, compareDecimal, addDecimal, subtractDecimal, multiplyDecimal, divideDecimal, formatDecimal });
});
