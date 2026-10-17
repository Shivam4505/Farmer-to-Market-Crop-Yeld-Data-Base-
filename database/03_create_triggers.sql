-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — PL/SQL Database Triggers
-- Script: 03_create_triggers.sql
-- Description:
--   1. trg_validate_harvest: BEFORE INSERT/UPDATE row trigger on YIELD_RECORD
--      rejects invalid harvest dates (harvest_date <= sowing_date).
--   2. trg_price_alert: COMPOUND TRIGGER on PRICE_RECORD that avoids
--      ORA-04091 (mutating table error), checks 7-day rolling baseline,
--      and auto-logs alerts for price deviations > 20%.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 1: trg_validate_harvest
-- Purpose: Enforce temporal business logic for crop cultivation cycles.
-- Type: Row-level BEFORE INSERT OR UPDATE trigger on YIELD_RECORD.
-- Exception: Raises application error -20001 with readable details.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_validate_harvest
BEFORE INSERT OR UPDATE ON YIELD_RECORD
FOR EACH ROW
BEGIN
    -- Validate that harvest date occurs strictly after sowing date
    IF :NEW.harvest_date <= :NEW.sowing_date THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Business Rule Violation: Harvest date (' ||
            TO_CHAR(:NEW.harvest_date, 'YYYY-MM-DD') ||
            ') must be strictly after sowing date (' ||
            TO_CHAR(:NEW.sowing_date, 'YYYY-MM-DD') || ').'
        );
    END IF;
END;
/
SHOW ERRORS TRIGGER trg_validate_harvest;

-- ----------------------------------------------------------------------------
-- TRIGGER 2: trg_price_alert (COMPOUND TRIGGER)
-- Purpose: Detect sudden price volatility (> 20% swing vs 7-day prior average).
-- Why Compound Trigger?
--   A standard AFTER INSERT FOR EACH ROW trigger on PRICE_RECORD querying
--   PRICE_RECORD causes ORA-04091 (table is mutating).
--   A COMPOUND TRIGGER solves this cleanly:
--     1. In AFTER EACH ROW: Buffers newly inserted rows in a PL/SQL collection.
--     2. In AFTER STATEMENT: Table mutation lock is cleared. Queries the 7-day
--        prior historical average (excluding the new row) and inserts alerts.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_price_alert
FOR INSERT ON PRICE_RECORD
COMPOUND TRIGGER

    -- Type to hold buffered row data
    TYPE t_price_row IS RECORD (
        price_id    NUMBER,
        market_id   NUMBER,
        crop_id     NUMBER,
        price_date  DATE,
        modal_price NUMBER
    );
    TYPE t_price_table IS TABLE OF t_price_row INDEX BY PLS_INTEGER;

    -- Package-level state variables for this statement execution
    g_new_prices t_price_table;

    -- Section 1: BEFORE STATEMENT — Reset the buffer for each statement
    BEFORE STATEMENT IS
    BEGIN
        g_new_prices.DELETE;
    END BEFORE STATEMENT;

    -- Section 2: AFTER EACH ROW — Capture new rows into memory buffer
    AFTER EACH ROW IS
    BEGIN
        g_new_prices(g_new_prices.COUNT + 1).price_id    := :NEW.price_id;
        g_new_prices(g_new_prices.COUNT).market_id       := :NEW.market_id;
        g_new_prices(g_new_prices.COUNT).crop_id         := :NEW.crop_id;
        g_new_prices(g_new_prices.COUNT).price_date      := :NEW.price_date;
        g_new_prices(g_new_prices.COUNT).modal_price     := :NEW.modal_price;
    END AFTER EACH ROW;

    -- Section 3: AFTER STATEMENT — Evaluate baseline and log alerts safely
    AFTER STATEMENT IS
        v_prior_avg     NUMBER;
        v_prior_count   NUMBER;
        v_deviation_pct NUMBER;
        v_crop_name     VARCHAR2(100);
        v_market_name   VARCHAR2(100);
        v_alert_msg     VARCHAR2(255);
    BEGIN
        IF g_new_prices.COUNT > 0 THEN
            FOR i IN 1 .. g_new_prices.COUNT LOOP
                -- Compute rolling 7-day average strictly PRIOR to the inserted date
                -- Note: price_date < g_new_prices(i).price_date prevents distorting the baseline
                SELECT NVL(AVG(modal_price), 0), COUNT(*)
                INTO   v_prior_avg, v_prior_count
                FROM   PRICE_RECORD
                WHERE  crop_id = g_new_prices(i).crop_id
                  AND  market_id = g_new_prices(i).market_id
                  AND  price_date < g_new_prices(i).price_date
                  AND  price_date >= (g_new_prices(i).price_date - 7);

                -- Only trigger alert if sufficient prior historical data exists and average > 0
                IF v_prior_count >= 1 AND v_prior_avg > 0 THEN
                    v_deviation_pct := ROUND(((g_new_prices(i).modal_price - v_prior_avg) / v_prior_avg) * 100, 2);

                    -- Check if absolute percentage deviation exceeds threshold of 20%
                    IF ABS(v_deviation_pct) > 20.00 THEN
                        -- Retrieve descriptive names for clear alert messaging
                        BEGIN
                            SELECT crop_name INTO v_crop_name FROM CROP WHERE crop_id = g_new_prices(i).crop_id;
                        EXCEPTION
                            WHEN OTHERS THEN v_crop_name := 'Crop #' || g_new_prices(i).crop_id;
                        END;

                        BEGIN
                            SELECT market_name INTO v_market_name FROM MARKET WHERE market_id = g_new_prices(i).market_id;
                        EXCEPTION
                            WHEN OTHERS THEN v_market_name := 'Market #' || g_new_prices(i).market_id;
                        END;

                        IF v_deviation_pct > 0 THEN
                            v_alert_msg := 'Price surge of +' || TO_CHAR(v_deviation_pct) || '% for ' ||
                                           v_crop_name || ' at ' || v_market_name || ' (7d avg: Rs.' ||
                                           TO_CHAR(ROUND(v_prior_avg, 2)) || ', new: Rs.' ||
                                           TO_CHAR(g_new_prices(i).modal_price) || ')';
                        ELSE
                            v_alert_msg := 'Price drop of ' || TO_CHAR(v_deviation_pct) || '% for ' ||
                                           v_crop_name || ' at ' || v_market_name || ' (7d avg: Rs.' ||
                                           TO_CHAR(ROUND(v_prior_avg, 2)) || ', new: Rs.' ||
                                           TO_CHAR(g_new_prices(i).modal_price) || ')';
                        END IF;

                        -- Insert the alert record
                        INSERT INTO PRICE_ALERT (
                            crop_id,
                            market_id,
                            alert_date,
                            deviation_pct,
                            alert_message
                        ) VALUES (
                            g_new_prices(i).crop_id,
                            g_new_prices(i).market_id,
                            g_new_prices(i).price_date,
                            v_deviation_pct,
                            v_alert_msg
                        );
                    END IF;
                END IF;
            END LOOP;
        END IF;
    END AFTER STATEMENT;

END trg_price_alert;
/
SHOW ERRORS TRIGGER trg_price_alert;
