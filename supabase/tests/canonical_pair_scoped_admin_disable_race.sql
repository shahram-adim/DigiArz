-- Disposable canonical pair-scoped admin disable and worker race fixture.
-- This schema is isolated; it does not model or modify Production tables.
DROP SCHEMA IF EXISTS canonical_pair_disable CASCADE;
CREATE SCHEMA canonical_pair_disable;

CREATE TABLE canonical_pair_disable.pairs (
  pair_id uuid PRIMARY KEY,
  display_pair text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT true
);
CREATE TABLE canonical_pair_disable.orders (
  order_id uuid PRIMARY KEY,
  pair_id uuid NOT NULL REFERENCES canonical_pair_disable.pairs(pair_id),
  order_type text NOT NULL CHECK (order_type IN ('limit','conditional')),
  status text NOT NULL CHECK (status IN ('pending','partially_filled','filled','cancelled')),
  amount numeric NOT NULL CHECK (amount > 0),
  filled_amount numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL,
  CHECK (filled_amount >= 0 AND filled_amount <= amount),
  CHECK (remaining_amount >= 0 AND remaining_amount = amount - filled_amount),
  UNIQUE (order_id, pair_id)
);
CREATE TABLE canonical_pair_disable.conditional_orders (
  order_id uuid PRIMARY KEY REFERENCES canonical_pair_disable.orders(order_id),
  pair_id uuid NOT NULL REFERENCES canonical_pair_disable.pairs(pair_id),
  status text NOT NULL CHECK (status IN ('pending','triggered','filled','cancelled')),
  FOREIGN KEY (order_id, pair_id)
    REFERENCES canonical_pair_disable.orders(order_id, pair_id)
);
CREATE TABLE canonical_pair_disable.reservations (
  order_id uuid PRIMARY KEY REFERENCES canonical_pair_disable.orders(order_id),
  pair_id uuid NOT NULL REFERENCES canonical_pair_disable.pairs(pair_id),
  reserved_amount numeric NOT NULL CHECK (reserved_amount > 0),
  consumed_amount numeric NOT NULL DEFAULT 0,
  released_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL CHECK (status IN ('reserved','consumed','released')),
  CHECK (consumed_amount >= 0 AND consumed_amount <= reserved_amount),
  CHECK (released_amount >= 0 AND released_amount <= reserved_amount - consumed_amount),
  FOREIGN KEY (order_id, pair_id)
    REFERENCES canonical_pair_disable.orders(order_id, pair_id)
);

CREATE OR REPLACE FUNCTION canonical_pair_disable.disable_pair(p_pair_id uuid)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_pair canonical_pair_disable.pairs%ROWTYPE;
  v_cancelled integer := 0;
  v_released integer := 0;
BEGIN
  SELECT * INTO v_pair
  FROM canonical_pair_disable.pairs
  WHERE pair_id = p_pair_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'pair not found'; END IF;

  UPDATE canonical_pair_disable.conditional_orders co
  SET status = 'cancelled'
  FROM canonical_pair_disable.orders o
  WHERE co.order_id = o.order_id
    AND co.pair_id = p_pair_id
    AND o.pair_id = p_pair_id
    AND o.status IN ('pending','partially_filled')
    AND co.status = 'pending';

  UPDATE canonical_pair_disable.reservations r
  SET released_amount = r.reserved_amount - r.consumed_amount,
      status = CASE WHEN r.consumed_amount >= r.reserved_amount
                    THEN 'consumed' ELSE 'released' END
  FROM canonical_pair_disable.orders o
  WHERE r.order_id = o.order_id
    AND r.pair_id = p_pair_id
    AND o.pair_id = p_pair_id
    AND o.order_type IN ('limit','conditional')
    AND o.status IN ('pending','partially_filled')
    AND r.status = 'reserved';
  GET DIAGNOSTICS v_released = ROW_COUNT;

  UPDATE canonical_pair_disable.orders
  SET status = 'cancelled',
      remaining_amount = amount - filled_amount
  WHERE pair_id = p_pair_id
    AND order_type IN ('limit','conditional')
    AND status IN ('pending','partially_filled');
  GET DIAGNOSTICS v_cancelled = ROW_COUNT;

  UPDATE canonical_pair_disable.pairs
  SET is_enabled = false
  WHERE pair_id = p_pair_id;

  RETURN jsonb_build_object(
    'pair_id', p_pair_id,
    'cancelled_orders', v_cancelled,
    'released_reservations', v_released
  );
END;
$$;

-- Repeated disable must be idempotent: no duplicate release or order mutation.
DO $$
DECLARE
  v_result jsonb;
BEGIN
  v_result := canonical_pair_disable.disable_pair('10000000-0000-0000-0000-000000000001');
  IF (v_result->>'cancelled_orders')::integer <> 0 THEN
    RAISE EXCEPTION 'second disable unexpectedly cancelled more orders';
  END IF;
  IF (v_result->>'released_reservations')::integer <> 0 THEN
    RAISE EXCEPTION 'second disable unexpectedly released reservations again';
  END IF;
  IF (SELECT count(*) FROM canonical_pair_disable.reservations
      WHERE pair_id='10000000-0000-0000-0000-000000000001'
        AND status='released' AND released_amount=75) <> 2 THEN
    RAISE EXCEPTION 'repeated disable changed cumulative reservation accounting';
  END IF;
END;
$$;

-- Worker follows the same pair-then-order lock order as admin disable.
CREATE OR REPLACE FUNCTION canonical_pair_disable.process_order(
  p_order_id uuid,
  p_pause_seconds numeric DEFAULT 0
)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_pair_id uuid;
  v_pair canonical_pair_disable.pairs%ROWTYPE;
  v_order canonical_pair_disable.orders%ROWTYPE;
BEGIN
  SELECT pair_id INTO v_pair_id
  FROM canonical_pair_disable.orders
  WHERE order_id = p_order_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'order not found'; END IF;

  SELECT * INTO v_pair
  FROM canonical_pair_disable.pairs
  WHERE pair_id = v_pair_id
  FOR UPDATE;
  IF NOT FOUND OR NOT v_pair.is_enabled THEN RETURN false; END IF;

  SELECT * INTO v_order
  FROM canonical_pair_disable.orders
  WHERE order_id = p_order_id AND pair_id = v_pair_id
  FOR UPDATE;
  IF NOT FOUND OR v_order.status NOT IN ('pending','partially_filled') THEN RETURN false; END IF;

  IF p_pause_seconds > 0 THEN PERFORM pg_sleep(p_pause_seconds::double precision); END IF;

  UPDATE canonical_pair_disable.orders
  SET status = 'filled', filled_amount = amount, remaining_amount = 0
  WHERE order_id = p_order_id AND pair_id = v_pair_id
    AND status IN ('pending','partially_filled');

  UPDATE canonical_pair_disable.reservations
  SET consumed_amount = reserved_amount,
      released_amount = 0,
      status = 'consumed'
  WHERE order_id = p_order_id AND pair_id = v_pair_id
    AND status = 'reserved';

  RETURN FOUND;
END;
$$;

-- Same display symbol, distinct immutable pair IDs.
INSERT INTO canonical_pair_disable.pairs(pair_id,display_pair) VALUES
('10000000-0000-0000-0000-000000000001','DUPUSDT'),
('10000000-0000-0000-0000-000000000002','DUPUSDT'),
('10000000-0000-0000-0000-000000000003','RACEUSDT'),
('10000000-0000-0000-0000-000000000004','RACEUSDT'),
('10000000-0000-0000-0000-000000000005','LOCKUSDT'),
('10000000-0000-0000-0000-000000000006','LOCKUSDT');

INSERT INTO canonical_pair_disable.orders(order_id,pair_id,order_type,status,amount,filled_amount,remaining_amount) VALUES
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','limit','pending',100,25,75),
('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','conditional','partially_filled',100,25,75),
('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002','limit','pending',100,0,100),
('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000002','conditional','pending',100,0,100),
('20000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000003','limit','pending',10,0,10),
('20000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000004','limit','pending',10,0,10),
('20000000-0000-0000-0000-000000000007','10000000-0000-0000-0000-000000000005','limit','pending',10,0,10),
('20000000-0000-0000-0000-000000000008','10000000-0000-0000-0000-000000000006','limit','pending',10,0,10);

INSERT INTO canonical_pair_disable.conditional_orders(order_id,pair_id,status) VALUES
('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','pending'),
('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000002','pending');

INSERT INTO canonical_pair_disable.reservations(order_id,pair_id,reserved_amount,consumed_amount,released_amount,status) VALUES
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',100,25,0,'reserved'),
('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001',100,25,0,'reserved'),
('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002',100,0,0,'reserved'),
('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000002',100,0,0,'reserved'),
('20000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000003',10,0,0,'reserved'),
('20000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000004',10,0,0,'reserved'),
('20000000-0000-0000-0000-000000000007','10000000-0000-0000-0000-000000000005',10,0,0,'reserved'),
('20000000-0000-0000-0000-000000000008','10000000-0000-0000-0000-000000000006',10,0,0,'reserved');

-- Pair-scope regression: disabling pair 1 must not touch pair 2 with same display symbol.
SELECT canonical_pair_disable.disable_pair('10000000-0000-0000-0000-000000000001');
DO $$
BEGIN
  IF (SELECT is_enabled FROM canonical_pair_disable.pairs WHERE pair_id='10000000-0000-0000-0000-000000000001') THEN RAISE EXCEPTION 'target pair remained enabled'; END IF;
  IF (SELECT count(*) FROM canonical_pair_disable.orders WHERE pair_id='10000000-0000-0000-0000-000000000001' AND status='cancelled') <> 2 THEN RAISE EXCEPTION 'target pair orders not cancelled'; END IF;
  IF (SELECT count(*) FROM canonical_pair_disable.reservations WHERE pair_id='10000000-0000-0000-0000-000000000001' AND status='released' AND released_amount=75) <> 2 THEN RAISE EXCEPTION 'target pair reservations not released with cumulative accounting'; END IF;
  IF (SELECT status FROM canonical_pair_disable.conditional_orders WHERE order_id='20000000-0000-0000-0000-000000000002') <> 'cancelled' THEN RAISE EXCEPTION 'target conditional order not cancelled'; END IF;
  IF NOT (SELECT is_enabled FROM canonical_pair_disable.pairs WHERE pair_id='10000000-0000-0000-0000-000000000002') THEN RAISE EXCEPTION 'unrelated same-symbol pair was disabled'; END IF;
  IF (SELECT count(*) FROM canonical_pair_disable.orders WHERE pair_id='10000000-0000-0000-0000-000000000002' AND status='pending') <> 2 THEN RAISE EXCEPTION 'unrelated same-symbol orders changed'; END IF;
  IF (SELECT count(*) FROM canonical_pair_disable.reservations WHERE pair_id='10000000-0000-0000-0000-000000000002' AND status='reserved') <> 2 THEN RAISE EXCEPTION 'unrelated same-symbol reservations changed'; END IF;
  IF (SELECT status FROM canonical_pair_disable.conditional_orders WHERE order_id='20000000-0000-0000-0000-000000000004') <> 'pending' THEN RAISE EXCEPTION 'unrelated conditional order changed'; END IF;
END;
$$;
