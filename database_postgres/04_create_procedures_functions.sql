-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — PL/pgSQL Stored Procedures, Functions & Explicit Cursors
-- Script: database_postgres/04_create_procedures_functions.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. STORED PROCEDURE: proc_best_market (Explicit Cursor)
-- Inputs:  p_crop_id (INTEGER)
-- Outputs: INOUT parameters for market_name, avg_price, result
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_best_market(
    p_crop_id       IN  INTEGER,
    p_market_id     INOUT INTEGER DEFAULT NULL,
    p_market_name   INOUT VARCHAR(100) DEFAULT NULL,
    p_avg_price     INOUT NUMERIC(10, 2) DEFAULT NULL,
    p_result        INOUT VARCHAR(255) DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    -- Explicit Cursor Declaration over 30-day prices
    c_prices CURSOR FOR
        SELECT m.market_id,
               m.market_name,
               m.district,
               ROUND(AVG(p.modal_price), 2) AS avg_price
        FROM   PRICE_RECORD p
        JOIN   MARKET m ON m.market_id = p.market_id
        WHERE  p.crop_id = p_crop_id
          AND  p.price_date >= (CURRENT_DATE - INTERVAL '30 days')
        GROUP  BY m.market_id, m.market_name, m.district
        ORDER  BY AVG(p.modal_price) DESC;

    v_rec RECORD;
BEGIN
    OPEN c_prices;
    FETCH c_prices INTO v_rec;

    IF FOUND THEN
        p_market_id   := v_rec.market_id;
        p_market_name := v_rec.market_name;
        p_avg_price   := v_rec.avg_price;
        p_result      := v_rec.market_name || ' (' || v_rec.district || ') @ Rs.' ||
                         v_rec.avg_price || '/qtl (30d avg)';
    ELSE
        p_market_id   := NULL;
        p_market_name := 'No Market Data';
        p_avg_price   := 0;
        p_result      := 'No price records found for Crop ID ' || p_crop_id || ' in last 30 days';
    END IF;

    CLOSE c_prices;
EXCEPTION
    WHEN OTHERS THEN
        p_market_id   := NULL;
        p_market_name := 'Error';
        p_avg_price   := 0;
        p_result      := 'Error: ' || SQLERRM;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. STORED FUNCTION: fn_expected_revenue
-- Formula: (Latest Harvested Yield in qtl) * (Recent Modal Price in Rs/qtl)
-- Returns: Estimated revenue in Rupees
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_expected_revenue(
    p_farmer_id INTEGER,
    p_crop_id   INTEGER
) RETURNS NUMERIC(14, 2)
LANGUAGE plpgsql AS $$
DECLARE
    v_actual_yield NUMERIC(10, 2) := 0;
    v_unit_price   NUMERIC(10, 2) := 0;
    v_est_revenue  NUMERIC(14, 2) := 0;
BEGIN
    -- 1. Fetch latest harvested yield for this farmer and crop
    SELECT y.actual_yield_qtl
    INTO v_actual_yield
    FROM YIELD_RECORD y
    JOIN FIELD f ON f.field_id = y.field_id
    WHERE f.farmer_id = p_farmer_id
      AND y.crop_id = p_crop_id
      AND y.harvest_date <= CURRENT_DATE
    ORDER BY y.harvest_date DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN 0;
    END IF;

    -- 2. Fetch 30-day average modal price for this crop
    SELECT ROUND(AVG(modal_price), 2)
    INTO v_unit_price
    FROM PRICE_RECORD
    WHERE crop_id = p_crop_id
      AND price_date >= (CURRENT_DATE - INTERVAL '30 days');

    IF v_unit_price IS NULL OR v_unit_price = 0 THEN
        SELECT modal_price
        INTO v_unit_price
        FROM PRICE_RECORD
        WHERE crop_id = p_crop_id
        ORDER BY price_date DESC
        LIMIT 1;
    END IF;

    v_est_revenue := ROUND(v_actual_yield * COALESCE(v_unit_price, 0), 2);
    RETURN v_est_revenue;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. EXPLICIT CURSOR DEMO PROCEDURE: proc_cursor_demo_market_summary
-- Demonstrates: DECLARE -> OPEN -> FETCH -> EXIT WHEN NOT FOUND -> CLOSE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_cursor_demo_market_summary(p_crop_id INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    c_market_stats CURSOR FOR
        SELECT m.market_id,
               m.market_name,
               m.district,
               COUNT(p.price_id)           AS total_obs,
               ROUND(MIN(p.min_price), 2)   AS lowest_price,
               ROUND(MAX(p.max_price), 2)   AS highest_price,
               ROUND(AVG(p.modal_price), 2) AS avg_modal
        FROM   MARKET m
        JOIN   PRICE_RECORD p ON p.market_id = m.market_id
        WHERE  p.crop_id = p_crop_id
          AND  p.price_date >= (CURRENT_DATE - INTERVAL '30 days')
        GROUP  BY m.market_id, m.market_name, m.district
        ORDER  BY avg_modal DESC;

    v_rec RECORD;
    v_row_count INTEGER := 0;
    v_crop_name VARCHAR(100);
BEGIN
    SELECT COALESCE(crop_name, 'Unknown') INTO v_crop_name FROM CROP WHERE crop_id = p_crop_id;

    RAISE NOTICE '================================================================';
    RAISE NOTICE 'PL/pgSQL CURSOR DEMO: 30-Day Market Analysis for: %', v_crop_name;
    RAISE NOTICE 'Demonstrating: DECLARE -> OPEN -> FETCH -> EXIT WHEN -> CLOSE';
    RAISE NOTICE '================================================================';

    OPEN c_market_stats;
    RAISE NOTICE '[CURSOR STATE]: Cursor c_market_stats successfully OPENED.';

    LOOP
        FETCH c_market_stats INTO v_rec;
        EXIT WHEN NOT FOUND;

        v_row_count := v_row_count + 1;
        RAISE NOTICE 'Rank % | Market: % | District: % | Avg Modal: Rs.%/qtl | Range: [% - %]',
            v_row_count, v_rec.market_name, v_rec.district, v_rec.avg_modal, v_rec.lowest_price, v_rec.highest_price;
    END LOOP;

    CLOSE c_market_stats;
    RAISE NOTICE '[CURSOR STATE]: Cursor successfully CLOSED. Total rows: %', v_row_count;
    RAISE NOTICE '================================================================';
END;
$$;
