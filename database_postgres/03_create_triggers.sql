-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — PL/pgSQL Triggers
-- Script: database_postgres/03_create_triggers.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 1: trg_validate_harvest
-- Enforces that harvest_date > sowing_date; raises exception if invalid.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_trg_validate_harvest()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.harvest_date <= NEW.sowing_date THEN
        RAISE EXCEPTION 'Business Rule Violation: Harvest date (%) must be strictly after sowing date (%).',
            NEW.harvest_date, NEW.sowing_date;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_harvest ON YIELD_RECORD;
CREATE TRIGGER trg_validate_harvest
BEFORE INSERT OR UPDATE ON YIELD_RECORD
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validate_harvest();

-- ----------------------------------------------------------------------------
-- TRIGGER 2: trg_price_alert
-- Detects price swing > 20% vs 7-day prior average and auto-logs alert.
-- Handles both INSERT and UPDATE with duplicate alert deduplication.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_trg_price_alert()
RETURNS TRIGGER AS $$
DECLARE
    v_prior_avg NUMERIC(10, 2);
    v_prior_count INTEGER;
    v_deviation_pct NUMERIC(6, 2);
    v_crop_name VARCHAR(100);
    v_market_name VARCHAR(100);
    v_alert_msg VARCHAR(255);
BEGIN
    -- Query 7-day rolling baseline strictly before inserted/updated date
    SELECT COALESCE(AVG(modal_price), 0), COUNT(*)
    INTO v_prior_avg, v_prior_count
    FROM PRICE_RECORD
    WHERE crop_id = NEW.crop_id
      AND market_id = NEW.market_id
      AND price_date < NEW.price_date
      AND price_date >= (NEW.price_date - INTERVAL '7 days');

    IF v_prior_count >= 1 AND v_prior_avg > 0 THEN
        v_deviation_pct := ROUND(((NEW.modal_price - v_prior_avg) / v_prior_avg) * 100.0, 2);

        IF ABS(v_deviation_pct) > 20.00 THEN
            SELECT crop_name INTO v_crop_name FROM CROP WHERE crop_id = NEW.crop_id;
            SELECT market_name INTO v_market_name FROM MARKET WHERE market_id = NEW.market_id;

            IF v_deviation_pct > 0 THEN
                v_alert_msg := 'Price surge of +' || v_deviation_pct || '% for ' || v_crop_name ||
                               ' at ' || v_market_name || ' (7d avg: Rs.' || v_prior_avg ||
                               ', new: Rs.' || NEW.modal_price || ')';
            ELSE
                v_alert_msg := 'Price crash of ' || v_deviation_pct || '% for ' || v_crop_name ||
                               ' at ' || v_market_name || ' (7d avg: Rs.' || v_prior_avg ||
                               ', new: Rs.' || NEW.modal_price || ')';
            END IF;

            -- Prevent duplicate alerts for the same crop, market, date
            IF EXISTS (
                SELECT 1 FROM PRICE_ALERT 
                WHERE crop_id = NEW.crop_id 
                  AND market_id = NEW.market_id 
                  AND alert_date = NEW.price_date
            ) THEN
                UPDATE PRICE_ALERT
                SET deviation_pct = v_deviation_pct,
                    alert_message = v_alert_msg,
                    created_at = CURRENT_TIMESTAMP
                WHERE crop_id = NEW.crop_id 
                  AND market_id = NEW.market_id 
                  AND alert_date = NEW.price_date;
            ELSE
                INSERT INTO PRICE_ALERT (crop_id, market_id, alert_date, deviation_pct, alert_message)
                VALUES (NEW.crop_id, NEW.market_id, NEW.price_date, v_deviation_pct, v_alert_msg);
            END IF;
        ELSE
            -- If updated price returns to within ±20%, clean up prior alert for this date
            DELETE FROM PRICE_ALERT
            WHERE crop_id = NEW.crop_id 
              AND market_id = NEW.market_id 
              AND alert_date = NEW.price_date;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_price_alert ON PRICE_RECORD;
CREATE TRIGGER trg_price_alert
AFTER INSERT OR UPDATE ON PRICE_RECORD
FOR EACH ROW
EXECUTE FUNCTION fn_trg_price_alert();

-- ----------------------------------------------------------------------------
-- TRIGGER 3: trg_price_audit
-- Audit trail recording all INSERT, UPDATE, and DELETE actions on PRICE_RECORD.
-- Captures previous values, new values, transactional user, and timestamp.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_trg_price_audit()
RETURNS TRIGGER AS $$
DECLARE
    v_user VARCHAR(50);
BEGIN
    -- Extract application session user set by backend transaction via set_config('app.user_name', ...)
    v_user := COALESCE(NULLIF(current_setting('app.user_name', true), ''), CURRENT_USER);

    IF (TG_OP = 'INSERT') THEN
        INSERT INTO PRICE_AUDIT (
            price_id, market_id, crop_id, price_date, action,
            old_min_price, old_max_price, old_modal_price,
            new_min_price, new_max_price, new_modal_price,
            changed_by, changed_at
        ) VALUES (
            NEW.price_id, NEW.market_id, NEW.crop_id, NEW.price_date, 'INSERT',
            NULL, NULL, NULL,
            NEW.min_price, NEW.max_price, NEW.modal_price,
            v_user, CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO PRICE_AUDIT (
            price_id, market_id, crop_id, price_date, action,
            old_min_price, old_max_price, old_modal_price,
            new_min_price, new_max_price, new_modal_price,
            changed_by, changed_at
        ) VALUES (
            NEW.price_id, NEW.market_id, NEW.crop_id, NEW.price_date, 'UPDATE',
            OLD.min_price, OLD.max_price, OLD.modal_price,
            NEW.min_price, NEW.max_price, NEW.modal_price,
            v_user, CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO PRICE_AUDIT (
            price_id, market_id, crop_id, price_date, action,
            old_min_price, old_max_price, old_modal_price,
            new_min_price, new_max_price, new_modal_price,
            changed_by, changed_at
        ) VALUES (
            OLD.price_id, OLD.market_id, OLD.crop_id, OLD.price_date, 'DELETE',
            OLD.min_price, OLD.max_price, OLD.modal_price,
            NULL, NULL, NULL,
            v_user, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_price_audit ON PRICE_RECORD;
CREATE TRIGGER trg_price_audit
AFTER INSERT OR UPDATE OR DELETE ON PRICE_RECORD
FOR EACH ROW
EXECUTE FUNCTION fn_trg_price_audit();
