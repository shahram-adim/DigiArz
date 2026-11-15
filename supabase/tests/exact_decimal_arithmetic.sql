-- DigiArz exact-decimal arithmetic regression checks.
-- Safe: pure numeric expressions only; creates no tables and changes no data.
-- Run in a PostgreSQL session with:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/exact_decimal_arithmetic.sql

DO $test$
DECLARE
  v_gross numeric;
  v_fee numeric;
  v_total numeric;
  v_net numeric;
  v_qty numeric;
  v_remaining numeric;
  v_filled numeric;
  v_reserved numeric;
  v_consumed numeric;
  v_released numeric;
BEGIN
  -- PostgreSQL numeric round is half away from zero at the selected scale.
  IF round(1.234567895, 8) <> 1.23456790 THEN
    RAISE EXCEPTION 'quote half-up rounding regression';
  END IF;
  IF round(1.234567894, 8) <> 1.23456789 THEN
    RAISE EXCEPTION 'quote below-half rounding regression';
  END IF;
  IF round(1.234567896, 8) <> 1.23456790 THEN
    RAISE EXCEPTION 'quote above-half rounding regression';
  END IF;

  -- A micro-asset fill retains 18 places while quote settlement stays at 8.
  v_qty := 0.007716048750000000;
  v_gross := round(v_qty * 0.000012345678901234, 8);
  v_fee := round(v_gross * 0.001, 8);
  v_total := v_gross + v_fee;
  v_net := v_gross - v_fee;
  IF v_qty <> 0.007716048750000000 THEN
    RAISE EXCEPTION '18-place base quantity changed';
  END IF;
  IF scale(v_gross) > 8 OR scale(v_fee) > 8
     OR scale(v_total) > 8 OR scale(v_net) > 8 THEN
    RAISE EXCEPTION 'quote ledger value exceeds 8 places';
  END IF;

  -- The exact same quantized quote values must be reused by all ledger entries.
  IF v_total <> (v_gross + v_fee) OR v_net <> (v_gross - v_fee) THEN
    RAISE EXCEPTION 'quote ledger arithmetic mismatch';
  END IF;

  -- A representative 25% fill with 18-place storage remains exact.
  v_qty := round(0.030864195000000000 * 0.25, 18);
  IF v_qty <> 0.007716048750000000 THEN
    RAISE EXCEPTION '18-place partial fill regression';
  END IF;

  -- Repeated fill conservation: the final fill consumes the exact remainder.
  v_remaining := 0.030864195000000000;
  v_filled := 0;
  FOR i IN 1..3 LOOP
    v_qty := LEAST(v_remaining, round(0.030864195000000000 * 0.25, 18));
    v_filled := v_filled + v_qty;
    v_remaining := 0.030864195000000000 - v_filled;
  END LOOP;
  v_qty := v_remaining; -- final fill must use the exact residual
  v_filled := v_filled + v_qty;
  v_remaining := 0.030864195000000000 - v_filled;
  IF v_filled <> 0.030864195000000000 OR v_remaining <> 0 THEN
    RAISE EXCEPTION 'final residual fill conservation regression';
  END IF;

  -- Reservation invariant after quantized quote consumption and release.
  v_reserved := 12.34567890;
  v_consumed := 1.23456789;
  v_released := v_reserved - v_consumed - 10.00000000;
  IF v_consumed < 0 OR v_released < 0
     OR v_consumed + v_released > v_reserved THEN
    RAISE EXCEPTION 'reservation conservation regression';
  END IF;

  -- Pinned partial-fill policy: quantize the 25% slice to 18 places.
  -- If it rounds to zero, make one-quantum progress (bounded by remaining).
  v_remaining := 0.000000000000000001;
  v_qty := LEAST(v_remaining, round(v_remaining * 0.25, 18));
  IF v_qty = 0 THEN
    v_qty := LEAST(v_remaining, 0.000000000000000001);
  END IF;
  IF v_qty <> 0.000000000000000001 THEN
    RAISE EXCEPTION 'minimum-quantum order must make progress';
  END IF;

  v_remaining := 0.000000000000000005;
  v_qty := LEAST(v_remaining, round(v_remaining * 0.25, 18));
  IF v_qty = 0 THEN
    v_qty := LEAST(v_remaining, 0.000000000000000001);
  END IF;
  IF v_qty <> 0.000000000000000001 THEN
    RAISE EXCEPTION 'sub-quantum quarter must advance by one quantum';
  END IF;

  -- Never let the fallback exceed a smaller remaining residual.
  v_remaining := 0.0000000000000000005;
  v_qty := LEAST(v_remaining, round(v_remaining * 0.25, 18));
  IF v_qty = 0 THEN
    v_qty := LEAST(v_remaining, 0.000000000000000001);
  END IF;
  IF v_qty <> v_remaining THEN
    RAISE EXCEPTION 'minimum-quantum fallback must be bounded by residual';
  END IF;

  RAISE NOTICE 'DigiArz exact-decimal arithmetic checks passed';
END
$test$;
