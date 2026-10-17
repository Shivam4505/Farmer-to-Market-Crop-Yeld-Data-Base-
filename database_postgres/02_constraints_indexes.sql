-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — PostgreSQL Performance Indexes
-- Script: database_postgres/02_constraints_indexes.sql
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_field_farmer ON FIELD(farmer_id);
CREATE INDEX IF NOT EXISTS idx_yield_field ON YIELD_RECORD(field_id);
CREATE INDEX IF NOT EXISTS idx_yield_crop ON YIELD_RECORD(crop_id);
CREATE INDEX IF NOT EXISTS idx_yield_harvest ON YIELD_RECORD(crop_id, field_id, harvest_date DESC);
CREATE INDEX IF NOT EXISTS idx_price_mkt_crop ON PRICE_RECORD(market_id, crop_id);
CREATE INDEX IF NOT EXISTS idx_price_crop_date_modal ON PRICE_RECORD(crop_id, price_date, modal_price);
CREATE INDEX IF NOT EXISTS idx_sale_farmer ON SALE_TRANSACTION(farmer_id);
CREATE INDEX IF NOT EXISTS idx_sale_crop_mkt ON SALE_TRANSACTION(crop_id, market_id);
CREATE INDEX IF NOT EXISTS idx_sale_date ON SALE_TRANSACTION(sale_date);
CREATE INDEX IF NOT EXISTS idx_alert_crop_mkt_date ON PRICE_ALERT(crop_id, market_id, alert_date);
CREATE INDEX IF NOT EXISTS idx_farmer_district ON FARMER(district);
CREATE INDEX IF NOT EXISTS idx_market_district ON MARKET(district);
CREATE INDEX IF NOT EXISTS idx_user_farmer ON APP_USER(farmer_id);
