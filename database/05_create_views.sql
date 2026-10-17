-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — Database Views & Distributed Fragmentation Simulation
-- Script: 05_create_views.sql
-- Description:
--   1. Analytical views: yield summary, 30-day price trends, top 3 markets.
--   2. Alert feeds and farmer revenue summaries.
--   3. Logical horizontal fragmentation simulation (Nashik, Pune, Ahmednagar)
--      and federated reconstruction across distributed mandi nodes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. VIEW: vw_crop_yield_summary
-- Purpose: Unified view joining farmer, field, crop, and yield records.
-- Computes variance (actual - expected), performance percentage, and duration.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_crop_yield_summary AS
SELECT 
    y.yield_id,
    f.farmer_id,
    fm.name                 AS farmer_name,
    fm.phone                AS farmer_phone,
    fm.district             AS farmer_district,
    f.field_id,
    f.location              AS field_location,
    f.soil_type,
    f.area_acres            AS field_acres,
    c.crop_id,
    c.crop_name,
    c.category              AS crop_category,
    c.season                AS crop_season,
    y.sowing_date,
    y.harvest_date,
    (y.harvest_date - y.sowing_date) AS growth_duration_days,
    y.expected_yield_qtl,
    y.actual_yield_qtl,
    ROUND(y.actual_yield_qtl - y.expected_yield_qtl, 2) AS yield_variance_qtl,
    CASE 
        WHEN y.expected_yield_qtl > 0 THEN 
            ROUND((y.actual_yield_qtl / y.expected_yield_qtl) * 100, 2)
        ELSE 100.00
    END AS performance_pct,
    CASE
        WHEN y.actual_yield_qtl > y.expected_yield_qtl THEN 'Exceeded Expected'
        WHEN y.actual_yield_qtl = y.expected_yield_qtl THEN 'Met Expected'
        ELSE 'Below Expected'
    END AS yield_status
FROM YIELD_RECORD y
JOIN FIELD f  ON f.field_id = y.field_id
JOIN FARMER fm ON fm.farmer_id = f.farmer_id
JOIN CROP c   ON c.crop_id = y.crop_id;

-- ----------------------------------------------------------------------------
-- 2. VIEW: vw_market_price_trends
-- Purpose: 30-day statistical price movements (min, max, modal, volatility)
--          per crop and mandi.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_market_price_trends AS
SELECT 
    p.market_id,
    m.market_name,
    m.district              AS market_district,
    m.state                 AS market_state,
    p.crop_id,
    c.crop_name,
    c.category              AS crop_category,
    COUNT(p.price_id)       AS recorded_days,
    ROUND(MIN(p.min_price), 2)   AS period_min_price,
    ROUND(MAX(p.max_price), 2)   AS period_max_price,
    ROUND(AVG(p.modal_price), 2) AS avg_modal_price,
    ROUND(MAX(p.modal_price) - MIN(p.modal_price), 2) AS price_spread,
    MAX(p.price_date)       AS latest_price_date
FROM PRICE_RECORD p
JOIN MARKET m ON m.market_id = p.market_id
JOIN CROP c   ON c.crop_id = p.crop_id
WHERE p.price_date >= (TRUNC(SYSDATE) - 30)
GROUP BY p.market_id, m.market_name, m.district, m.state, p.crop_id, c.crop_name, c.category;

-- ----------------------------------------------------------------------------
-- 3. VIEW: vw_top_three_markets
-- Purpose: Ranks top 3 mandis for every crop based on 30-day average modal price
--          using the Oracle analytic window function DENSE_RANK().
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_top_three_markets AS
WITH ranked_markets AS (
    SELECT 
        c.crop_id,
        c.crop_name,
        m.market_id,
        m.market_name,
        m.district,
        m.state,
        ROUND(AVG(p.modal_price), 2) AS avg_modal_price,
        COUNT(p.price_id)            AS price_samples,
        DENSE_RANK() OVER (
            PARTITION BY c.crop_id 
            ORDER BY AVG(p.modal_price) DESC
        ) AS market_rank
    FROM PRICE_RECORD p
    JOIN MARKET m ON m.market_id = p.market_id
    JOIN CROP c   ON c.crop_id = p.crop_id
    WHERE p.price_date >= (TRUNC(SYSDATE) - 30)
    GROUP BY c.crop_id, c.crop_name, m.market_id, m.market_name, m.district, m.state
)
SELECT 
    crop_id,
    crop_name,
    market_rank,
    market_id,
    market_name,
    district,
    state,
    avg_modal_price,
    price_samples
FROM ranked_markets
WHERE market_rank <= 3;

-- ----------------------------------------------------------------------------
-- 4. VIEW: vw_price_alert_feed
-- Purpose: Formatted real-time feed of automated price alerts with severity.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_price_alert_feed AS
SELECT 
    pa.alert_id,
    pa.alert_date,
    pa.crop_id,
    c.crop_name,
    c.category          AS crop_category,
    pa.market_id,
    m.market_name,
    m.district          AS market_district,
    pa.deviation_pct,
    CASE 
        WHEN ABS(pa.deviation_pct) >= 30 THEN 'CRITICAL'
        WHEN ABS(pa.deviation_pct) >= 20 THEN 'HIGH'
        ELSE 'MODERATE'
    END AS alert_severity,
    CASE 
        WHEN pa.deviation_pct > 0 THEN 'PRICE_SURGE'
        ELSE 'PRICE_CRASH'
    END AS alert_direction,
    pa.alert_message,
    pa.created_at
FROM PRICE_ALERT pa
JOIN CROP c   ON c.crop_id = pa.crop_id
JOIN MARKET m ON m.market_id = pa.market_id;

-- ----------------------------------------------------------------------------
-- 5. VIEW: vw_farmer_revenue_summary
-- Purpose: Financial realization summary per farmer across all transactions.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_farmer_revenue_summary AS
SELECT 
    f.farmer_id,
    f.name                  AS farmer_name,
    f.phone                 AS farmer_phone,
    f.village,
    f.district,
    COUNT(s.sale_id)        AS total_sales_count,
    NVL(SUM(s.quantity_qtl), 0) AS total_quantity_sold_qtl,
    NVL(SUM(s.total_amount), 0) AS total_revenue_inr,
    CASE 
        WHEN NVL(SUM(s.quantity_qtl), 0) > 0 THEN 
            ROUND(SUM(s.total_amount) / SUM(s.quantity_qtl), 2)
        ELSE 0
    END AS avg_realized_price_per_qtl,
    MAX(s.sale_date)        AS last_sale_date
FROM FARMER f
LEFT JOIN SALE_TRANSACTION s ON s.farmer_id = f.farmer_id
GROUP BY f.farmer_id, f.name, f.phone, f.village, f.district;

-- ----------------------------------------------------------------------------
-- 6. DISTRIBUTED DATA CONCEPT: LOGICAL HORIZONTAL FRAGMENTATION SIMULATION
-- ADBMS Concept: Mandi nodes produce prices locally. In a distributed DBMS,
-- data is fragmented horizontally by District (Predicate: district = 'X').
-- Here we simulate 3 regional nodes and a consolidated global union.
-- ----------------------------------------------------------------------------

-- 6a. Regional Fragment: Nashik Mandi Node
CREATE OR REPLACE VIEW vw_mandi_frag_nashik AS
SELECT 
    'NODE_NASHIK' AS simulated_node,
    p.price_id,
    p.market_id,
    m.market_name,
    m.district,
    p.crop_id,
    c.crop_name,
    p.price_date,
    p.min_price,
    p.max_price,
    p.modal_price
FROM PRICE_RECORD p
JOIN MARKET m ON m.market_id = p.market_id
JOIN CROP c   ON c.crop_id = p.crop_id
WHERE m.district = 'Nashik';

-- 6b. Regional Fragment: Pune Mandi Node
CREATE OR REPLACE VIEW vw_mandi_frag_pune AS
SELECT 
    'NODE_PUNE' AS simulated_node,
    p.price_id,
    p.market_id,
    m.market_name,
    m.district,
    p.crop_id,
    c.crop_name,
    p.price_date,
    p.min_price,
    p.max_price,
    p.modal_price
FROM PRICE_RECORD p
JOIN MARKET m ON m.market_id = p.market_id
JOIN CROP c   ON c.crop_id = p.crop_id
WHERE m.district = 'Pune';

-- 6c. Regional Fragment: Ahmednagar Mandi Node
CREATE OR REPLACE VIEW vw_mandi_frag_ahmednagar AS
SELECT 
    'NODE_AHMEDNAGAR' AS simulated_node,
    p.price_id,
    p.market_id,
    m.market_name,
    m.district,
    p.crop_id,
    c.crop_name,
    p.price_date,
    p.min_price,
    p.max_price,
    p.modal_price
FROM PRICE_RECORD p
JOIN MARKET m ON m.market_id = p.market_id
JOIN CROP c   ON c.crop_id = p.crop_id
WHERE m.district = 'Ahmednagar';

-- 6d. Consolidated Global View (Reconstruction Completeness Rule)
-- Demonstrates how a central node queries across horizontal fragments via UNION ALL
CREATE OR REPLACE VIEW vw_mandi_consolidated_federation AS
SELECT * FROM vw_mandi_frag_nashik
UNION ALL
SELECT * FROM vw_mandi_frag_pune
UNION ALL
SELECT * FROM vw_mandi_frag_ahmednagar;
