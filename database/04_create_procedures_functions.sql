-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — PL/SQL Stored Procedures, Functions & Cursors
-- Script: 04_create_procedures_functions.sql
-- Description:
--   1. proc_best_market: Explicit-cursor procedure returning the top market
--      and 30-day average price for a given crop.
--   2. fn_expected_revenue: Stored function computing farmer projected revenue
--      based on latest harvested yield and recent modal market price.
--   3. proc_cursor_demo_market_summary: Detailed explicit cursor demonstration
--      showing DECLARE, OPEN, FETCH, EXIT WHEN, and CLOSE lifecycles.
--   4. proc_record_sale: Transaction-safe procedure for logging crop sales.
-- ============================================================================

SET SERVEROUTPUT ON;

-- ----------------------------------------------------------------------------
-- 1. STORED PROCEDURE: proc_best_market (Explicit Cursor)
-- Purpose: Identifies the mandi offering the highest average modal price for
--          a crop over the last 30 days.
-- Inputs:  p_crop_id (NUMBER)
-- Outputs: p_market_id (NUMBER), p_market_name (VARCHAR2),
--          p_avg_price (NUMBER), p_result (VARCHAR2 summary)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_best_market(
    p_crop_id       IN  NUMBER,
    p_market_id     OUT NUMBER,
    p_market_name   OUT VARCHAR2,
    p_avg_price     OUT NUMBER,
    p_result        OUT VARCHAR2
) IS
    -- Step 1: Explicit Cursor Declaration
    -- Aggregates modal price across markets for the designated crop over past 30 days
    CURSOR c_prices IS
        SELECT m.market_id,
               m.market_name,
               m.district,
               ROUND(AVG(p.modal_price), 2) AS avg_price
        FROM   PRICE_RECORD p
        JOIN   MARKET m ON m.market_id = p.market_id
        WHERE  p.crop_id = p_crop_id
          AND  p.price_date >= (TRUNC(SYSDATE) - 30)
        GROUP  BY m.market_id, m.market_name, m.district
        ORDER  BY AVG(p.modal_price) DESC;

    v_rec c_prices%ROWTYPE;
BEGIN
    -- Step 2: Open Cursor
    OPEN c_prices;

    -- Step 3: Fetch First (Highest Ranked) Row
    FETCH c_prices INTO v_rec;

    -- Check if matching records were found
    IF c_prices%FOUND THEN
        p_market_id   := v_rec.market_id;
        p_market_name := v_rec.market_name;
        p_avg_price   := v_rec.avg_price;
        p_result      := v_rec.market_name || ' (' || v_rec.district || ') @ Rs.' ||
                         TO_CHAR(v_rec.avg_price) || '/qtl (30d avg)';
    ELSE
        -- Safe fallback when no 30-day price history exists
        p_market_id   := NULL;
        p_market_name := 'No Market Data';
        p_avg_price   := 0;
        p_result      := 'No price records found for Crop ID ' || p_crop_id || ' in the last 30 days';
    END IF;

    -- Step 4: Close Cursor
    CLOSE c_prices;

EXCEPTION
    WHEN OTHERS THEN
        IF c_prices%ISOPEN THEN
            CLOSE c_prices;
        END IF;
        p_market_id   := NULL;
        p_market_name := 'Error';
        p_avg_price   := 0;
        p_result      := 'Error evaluating best market: ' || SQLERRM;
END proc_best_market;
/
SHOW ERRORS PROCEDURE proc_best_market;

-- ----------------------------------------------------------------------------
-- 2. STORED FUNCTION: fn_expected_revenue
-- Purpose: Estimates expected gross revenue for a farmer cultivating a crop.
-- Formula: (Latest Harvested Actual Yield in quintals) × (Recent Modal Price in Rs/qtl)
-- Inputs:  p_farmer_id (NUMBER), p_crop_id (NUMBER)
-- Returns: Estimated revenue in Rupees (NUMBER)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_expected_revenue(
    p_farmer_id IN NUMBER,
    p_crop_id   IN NUMBER
) RETURN NUMBER IS
    v_actual_yield NUMBER(10, 2) := 0;
    v_unit_price   NUMBER(10, 2) := 0;
    v_est_revenue  NUMBER(14, 2) := 0;
BEGIN
    -- 1. Fetch the most recent harvested yield for this farmer and crop
    -- Uses a subquery ordered by harvest_date DESC to pick the latest valid harvest
    BEGIN
        SELECT actual_yield_qtl
        INTO   v_actual_yield
        FROM (
            SELECT y.actual_yield_qtl
            FROM   YIELD_RECORD y
            JOIN   FIELD f ON f.field_id = y.field_id
            WHERE  f.farmer_id = p_farmer_id
              AND  y.crop_id = p_crop_id
              AND  y.harvest_date <= TRUNC(SYSDATE)
            ORDER  BY y.harvest_date DESC
        )
        WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- No harvested yield record for this farmer/crop
            RETURN 0;
    END;

    -- 2. Fetch the recent 30-day state-wide average modal price for this crop
    -- If no 30-day data exists, fallback to the latest known modal price
    BEGIN
        SELECT ROUND(AVG(modal_price), 2)
        INTO   v_unit_price
        FROM   PRICE_RECORD
        WHERE  crop_id = p_crop_id
          AND  price_date >= (TRUNC(SYSDATE) - 30);

        IF v_unit_price IS NULL OR v_unit_price = 0 THEN
            SELECT modal_price
            INTO   v_unit_price
            FROM (
                SELECT modal_price
                FROM   PRICE_RECORD
                WHERE  crop_id = p_crop_id
                ORDER  BY price_date DESC
            )
            WHERE ROWNUM = 1;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_unit_price := 0;
    END;

    -- 3. Calculate Projected Revenue = Yield (qtl) * Price (Rs/qtl)
    v_est_revenue := ROUND(v_actual_yield * v_unit_price, 2);

    RETURN v_est_revenue;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END fn_expected_revenue;
/
SHOW ERRORS FUNCTION fn_expected_revenue;

-- ----------------------------------------------------------------------------
-- 3. EXPLICIT CURSOR DEMONSTRATION: proc_cursor_demo_market_summary
-- Purpose: Comprehensive educational demonstration of PL/SQL Cursor Lifecycle:
--          DECLARE -> OPEN -> FETCH -> EXIT WHEN %NOTFOUND -> CLOSE.
--          Also contrasts with Cursor FOR Loop syntax for viva examination.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_cursor_demo_market_summary(
    p_crop_id IN NUMBER
) IS
    -- STEP 1: Cursor Declaration with parameter binding
    CURSOR c_market_stats IS
        SELECT m.market_id,
               m.market_name,
               m.district,
               COUNT(p.price_id)           AS total_observations,
               ROUND(MIN(p.min_price), 2)   AS lowest_price,
               ROUND(MAX(p.max_price), 2)   AS highest_price,
               ROUND(AVG(p.modal_price), 2) AS avg_modal_price
        FROM   MARKET m
        JOIN   PRICE_RECORD p ON p.market_id = m.market_id
        WHERE  p.crop_id = p_crop_id
          AND  p.price_date >= (TRUNC(SYSDATE) - 30)
        GROUP  BY m.market_id, m.market_name, m.district
        ORDER  BY avg_modal_price DESC;

    -- Local record variable based on cursor structure
    v_rec         c_market_stats%ROWTYPE;
    v_row_count   PLS_INTEGER := 0;
    v_crop_name   VARCHAR2(100);
BEGIN
    SELECT NVL(crop_name, 'Unknown') INTO v_crop_name FROM CROP WHERE crop_id = p_crop_id;

    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('ADBMS PL/SQL CURSOR DEMO: 30-Day Market Analysis for: ' || v_crop_name);
    DBMS_OUTPUT.PUT_LINE('Demonstrating: DECLARE -> OPEN -> FETCH -> EXIT WHEN -> CLOSE');
    DBMS_OUTPUT.PUT_LINE('================================================================');

    -- STEP 2: OPEN CURSOR
    OPEN c_market_stats;
    DBMS_OUTPUT.PUT_LINE('[CURSOR STATE]: Cursor c_market_stats successfully OPENED.');

    -- STEP 3 & 4: LOOP with FETCH and EXIT WHEN %NOTFOUND
    LOOP
        FETCH c_market_stats INTO v_rec;
        EXIT WHEN c_market_stats%NOTFOUND;

        v_row_count := v_row_count + 1;
        DBMS_OUTPUT.PUT_LINE('Rank ' || v_row_count || ' | Market: ' || RPAD(v_rec.market_name, 18) ||
                             ' | District: ' || RPAD(v_rec.district, 12) ||
                             ' | Avg Modal: Rs.' || LPAD(TO_CHAR(v_rec.avg_modal_price), 7) || '/qtl' ||
                             ' | Range: [' || v_rec.lowest_price || ' - ' || v_rec.highest_price || ']');
    END LOOP;

    -- STEP 5: CLOSE CURSOR
    IF c_market_stats%ISOPEN THEN
        CLOSE c_market_stats;
        DBMS_OUTPUT.PUT_LINE('[CURSOR STATE]: Cursor successfully CLOSED. Total rows fetched: ' || v_row_count);
    END IF;

    IF v_row_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No price observations found for Crop ID ' || p_crop_id || ' in past 30 days.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('================================================================');

EXCEPTION
    WHEN OTHERS THEN
        IF c_market_stats%ISOPEN THEN
            CLOSE c_market_stats;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Error in cursor execution: ' || SQLERRM);
END proc_cursor_demo_market_summary;
/
SHOW ERRORS PROCEDURE proc_cursor_demo_market_summary;

-- ----------------------------------------------------------------------------
-- 4. TRANSACTION PROCEDURE: proc_record_sale
-- Purpose: Records a crop sale transaction safely with parameter validation
--          and atomic transaction control (COMMIT / ROLLBACK).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_record_sale(
    p_farmer_id     IN  NUMBER,
    p_market_id     IN  NUMBER,
    p_crop_id       IN  NUMBER,
    p_quantity_qtl  IN  NUMBER,
    p_price_per_qtl IN  NUMBER,
    p_sale_date     IN  DATE,
    p_sale_id       OUT NUMBER,
    p_total_amount  OUT NUMBER,
    p_status        OUT VARCHAR2
) IS
    v_farmer_exists NUMBER;
    v_market_exists NUMBER;
    v_crop_exists   NUMBER;
BEGIN
    -- 1. Input parameter validations
    IF p_quantity_qtl <= 0 THEN
        p_status := 'ERROR: Quantity must be greater than zero.';
        RETURN;
    END IF;

    IF p_price_per_qtl <= 0 THEN
        p_status := 'ERROR: Price per quintal must be greater than zero.';
        RETURN;
    END IF;

    -- 2. Foreign Key existence checks
    SELECT COUNT(*) INTO v_farmer_exists FROM FARMER WHERE farmer_id = p_farmer_id;
    IF v_farmer_exists = 0 THEN
        p_status := 'ERROR: Farmer ID ' || p_farmer_id || ' does not exist.';
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_market_exists FROM MARKET WHERE market_id = p_market_id;
    IF v_market_exists = 0 THEN
        p_status := 'ERROR: Market ID ' || p_market_id || ' does not exist.';
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_crop_exists FROM CROP WHERE crop_id = p_crop_id;
    IF v_crop_exists = 0 THEN
        p_status := 'ERROR: Crop ID ' || p_crop_id || ' does not exist.';
        RETURN;
    END IF;

    -- 3. Execute Insert (total_amount is automatically computed virtual column)
    INSERT INTO SALE_TRANSACTION (
        farmer_id,
        market_id,
        crop_id,
        quantity_qtl,
        sale_date,
        price_per_qtl
    ) VALUES (
        p_farmer_id,
        p_market_id,
        p_crop_id,
        p_quantity_qtl,
        NVL(p_sale_date, TRUNC(SYSDATE)),
        p_price_per_qtl
    )
    RETURNING sale_id, total_amount INTO p_sale_id, p_total_amount;

    -- 4. Explicit Transaction Commit
    COMMIT;
    p_status := 'SUCCESS: Sale transaction recorded successfully.';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_sale_id      := NULL;
        p_total_amount := NULL;
        p_status       := 'TRANSACTION ERROR: ' || SQLERRM;
END proc_record_sale;
/
SHOW ERRORS PROCEDURE proc_record_sale;
