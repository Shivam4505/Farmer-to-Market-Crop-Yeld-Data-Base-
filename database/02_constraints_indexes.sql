-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — Performance Indexes & Referential Integrity
-- Script: 02_constraints_indexes.sql
-- Description: Creates B-Tree performance indexes on all Foreign Keys
--              and high-frequency analytical query paths (rolling averages,
--              recent harvest queries, market rank searches).
-- ============================================================================

-- Safely drop indexes if they exist
BEGIN
    FOR idx IN (SELECT index_name FROM user_indexes WHERE index_name IN (
        'IDX_FIELD_FARMER', 'IDX_YIELD_FIELD', 'IDX_YIELD_CROP',
        'IDX_YIELD_HARVEST', 'IDX_PRICE_MKT_CROP', 'IDX_PRICE_CROP_DATE_MODAL',
        'IDX_SALE_FARMER', 'IDX_SALE_CROP_MKT', 'IDX_SALE_DATE',
        'IDX_ALERT_CROP_MKT_DATE', 'IDX_FARMER_DISTRICT', 'IDX_MARKET_DISTRICT',
        'IDX_USER_FARMER', 'UK_FARMER_PHONE'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP INDEX ' || idx.index_name;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- ----------------------------------------------------------------------------
-- 1. CANDIDATE KEYS & UNIQUE CONSTRAINTS
-- ----------------------------------------------------------------------------
-- Ensure farmer telephone numbers are unique across the database
ALTER TABLE FARMER ADD CONSTRAINT uk_farmer_phone UNIQUE (phone);

-- ----------------------------------------------------------------------------
-- 2. FOREIGN KEY B-TREE INDEXES
-- In Oracle, unindexed foreign keys cause share locks on child tables during
-- parent updates/deletions, which can lead to deadlocks in concurrent workloads.
-- ----------------------------------------------------------------------------

-- Index on FIELD(farmer_id)
CREATE INDEX idx_field_farmer ON FIELD(farmer_id);

-- Indexes on YIELD_RECORD
CREATE INDEX idx_yield_field ON YIELD_RECORD(field_id);
CREATE INDEX idx_yield_crop ON YIELD_RECORD(crop_id);

-- Composite index on YIELD_RECORD for recent harvest lookup per field & crop
-- Powers fn_expected_revenue: WHERE f.farmer_id = :1 AND y.crop_id = :2 ORDER BY harvest_date DESC
CREATE INDEX idx_yield_harvest ON YIELD_RECORD(crop_id, field_id, harvest_date DESC);

-- Indexes on PRICE_RECORD
CREATE INDEX idx_price_mkt_crop ON PRICE_RECORD(market_id, crop_id);

-- Composite covering index on PRICE_RECORD for 7-day baseline & 30-day market ranking
-- Extremely high impact: avoids table lookups for rolling average and best market procedure
CREATE INDEX idx_price_crop_date_modal ON PRICE_RECORD(crop_id, price_date, modal_price);

-- Indexes on SALE_TRANSACTION
CREATE INDEX idx_sale_farmer ON SALE_TRANSACTION(farmer_id);
CREATE INDEX idx_sale_crop_mkt ON SALE_TRANSACTION(crop_id, market_id);
CREATE INDEX idx_sale_date ON SALE_TRANSACTION(sale_date);

-- Indexes on PRICE_ALERT
CREATE INDEX idx_alert_crop_mkt_date ON PRICE_ALERT(crop_id, market_id, alert_date);

-- Indexes on Master Tables for District-Based Horizontal Fragmentation queries
CREATE INDEX idx_farmer_district ON FARMER(district);
CREATE INDEX idx_market_district ON MARKET(district);

-- Indexes on Authentication mapping
CREATE INDEX idx_user_farmer ON APP_USER(farmer_id);
