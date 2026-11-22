const DECIMAL_PATTERN = /^([+-]?)(\d+)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$/;

function incrementDigits(value) {
  const digits = value.split("");
  for (let index = digits.length - 1; index >= 0; index -= 1) {
    if (digits[index] !== "9") {
      digits[index] = String(Number(digits[index]) + 1);
      return digits.join("");
    }
    digits[index] = "0";
  }
  return "1" + digits.join("");
}

/**
 * Convert a JSON number, lossless-json number, or numeric string to a canonical
 * decimal string compatible with a PostgreSQL NUMERIC(precision, scale).
 * Excess fractional digits are rounded half away from zero, matching PostgreSQL
 * NUMERIC input behavior. Values outside the declared precision are rejected.
 */
export function normalizeDecimal(value, precision = 30, scale = 10) {
  if (value === null || value === undefined || value === "") return null;
  if (!Number.isInteger(precision) || !Number.isInteger(scale) || precision < 1 || scale < 0 || scale > precision) return null;

  let raw;
  if (typeof value === "string") raw = value.trim().replace(/,/g, "");
  else if (typeof value === "number") {
    if (!Number.isFinite(value)) return null;
    raw = String(value);
  } else if (typeof value === "bigint") raw = value.toString();
  else if (typeof value === "object" && typeof value.toString === "function") raw = value.toString();
  else return null;

  const match = DECIMAL_PATTERN.exec(raw);
  if (!match) return null;
  const negative = match[1] === "-";
  const integerPart = match[2];
  const fractionPart = match[3] || "";
  const exponent = Number(match[4] || 0);
  if (!Number.isSafeInteger(exponent) || Math.abs(exponent) > 100) return null;

  const rawDigits = integerPart + fractionPart;
  const leadingZeros = rawDigits.length - rawDigits.replace(/^0+/, "").length;
  const coefficient = rawDigits.replace(/^0+/, "") || "0";
  const point = integerPart.length + exponent - leadingZeros;
  let integer;
  let fraction;
  if (point <= 0) {
    integer = "0";
    fraction = "0".repeat(Math.min(-point, scale + 1)) + coefficient;
  } else if (point >= coefficient.length) {
    integer = coefficient + "0".repeat(point - coefficient.length);
    fraction = "";
  } else {
    integer = coefficient.slice(0, point);
    fraction = coefficient.slice(point);
  }

  integer = integer.replace(/^0+/, "") || "0";
  const discarded = fraction.slice(scale);
  fraction = fraction.slice(0, scale).padEnd(scale, "0");
  let combined = integer + fraction;
  if (discarded.length && discarded[0] >= "5") combined = incrementDigits(combined);

  if (combined.length <= scale) combined = combined.padStart(scale + 1, "0");
  integer = scale === 0 ? combined : combined.slice(0, -scale);
  fraction = scale === 0 ? "" : combined.slice(-scale);
  integer = integer.replace(/^0+/, "") || "0";

  const maxIntegerDigits = precision - scale;
  if (integer.length > maxIntegerDigits) return null;
  fraction = fraction.replace(/0+$/, "");
  const isZero = integer === "0" && fraction === "";
  const sign = negative && !isZero ? "-" : "";
  return sign + integer + (fraction ? "." + fraction : "");
}

export function shiftDecimal(value, exponent, precision = 30, scale = 10) {
  if (!Number.isInteger(exponent) || Math.abs(exponent) > 100 || value === null || value === undefined) return null;
  let raw;
  if (typeof value === "string") raw = value.trim().replace(/,/g, "");
  else if (typeof value === "number" && Number.isFinite(value)) raw = String(value);
  else if (typeof value === "bigint") raw = value.toString();
  else if (typeof value === "object" && typeof value.toString === "function") raw = value.toString();
  else return null;
  if (!DECIMAL_PATTERN.test(raw)) return null;
  return normalizeDecimal(raw + "e" + String(exponent), precision, scale);
}

export function compareDecimals(left, right) {
  const a = normalizeDecimal(left, 80, 40);
  const b = normalizeDecimal(right, 80, 40);
  if (a === null || b === null) throw new TypeError("Cannot compare invalid decimal values");
  const negativeA = a.startsWith("-");
  const negativeB = b.startsWith("-");
  if (negativeA !== negativeB) return negativeA ? -1 : 1;
  const absA = negativeA ? a.slice(1) : a;
  const absB = negativeB ? b.slice(1) : b;
  const [intA, fracA = ""] = absA.split(".");
  const [intB, fracB = ""] = absB.split(".");
  let result = 0;
  if (intA.length !== intB.length) result = intA.length < intB.length ? -1 : 1;
  else if (intA !== intB) result = intA < intB ? -1 : 1;
  else {
    const width = Math.max(fracA.length, fracB.length);
    const fa = fracA.padEnd(width, "0");
    const fb = fracB.padEnd(width, "0");
    result = fa === fb ? 0 : fa < fb ? -1 : 1;
  }
  return negativeA ? -result : result;
}

export function equalDecimals(left, right) {
  if (left === null || left === undefined || right === null || right === undefined) {
    return (left ?? null) === (right ?? null);
  }
  return compareDecimals(left, right) === 0;
}
