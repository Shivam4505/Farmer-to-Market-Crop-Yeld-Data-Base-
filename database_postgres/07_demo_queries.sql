-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — PostgreSQL Demonstration & Analytical Queries
-- Script: database_postgres/07_demo_queries.sql
-- Run in pgAdmin 4 Query Tool
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TOP 3 MARKETS FOR WHEAT (LAST 30 DAYS)
-- ----------------------------------------------------------------------------

SELECT
    m.market_name,
    m.district,
    ROUND(AVG(p.modal_price), 2) AS avg_price_rs_qtl,
    COUNT(p.price_id) AS total_observations
FROM PRICE_RECORD p
JOIN MARKET m ON m.market_id = p.market_id
JOIN CROP c ON c.crop_id = p.crop_id
WHERE c.crop_name = 'Wheat'
  AND p.price_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY m.market_name, m.district
ORDER BY avg_price_rs_qtl DESC
LIMIT 3;


-- ----------------------------------------------------------------------------
-- 2. CALL STORED PROCEDURE: proc_best_market
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    v_mkt_id INTEGER;
    v_mkt_name VARCHAR(100);
    v_price NUMERIC(10, 2);
    v_result VARCHAR(255);
BEGIN
    CALL proc_best_market(
        1, v_mkt_id, v_mkt_name, v_price, v_result
    );

    RAISE NOTICE 'Wheat Best Market: %', v_result;

    CALL proc_best_market(
        2, v_mkt_id, v_mkt_name, v_price, v_result
    );

    RAISE NOTICE 'Onion Best Market: %', v_result;
END;
$$;


-- ----------------------------------------------------------------------------
-- 3. CALL STORED FUNCTION: fn_expected_revenue
-- Explicitly use the three-argument function to avoid ambiguity.
-- The quantity below is 1 quintal; change it to your required quantity.
-- ----------------------------------------------------------------------------

SELECT
    f.farmer_id,
    f.name AS farmer_name,
    f.district AS farmer_district,
    c.crop_id,
    c.crop_name,
    fn_expected_revenue(
        f.farmer_id,
        c.crop_id,
        1::NUMERIC
    ) AS projected_revenue_inr
FROM FARMER f
CROSS JOIN CROP c
WHERE fn_expected_revenue(
    f.farmer_id,
    c.crop_id,
    1::NUMERIC
) > 0
ORDER BY projected_revenue_inr DESC;


-- ----------------------------------------------------------------------------
-- 4. CALL EXPLICIT CURSOR DEMO PROCEDURE
-- ----------------------------------------------------------------------------

CALL proc_cursor_demo_market_summary(1);


-- ----------------------------------------------------------------------------
-- 5. EXPECTED VS ACTUAL YIELD VARIANCE REPORT
-- ----------------------------------------------------------------------------

SELECT
    farmer_name,
    crop_name,
    soil_type,
    expected_yield_qtl,
    actual_yield_qtl,
    yield_variance_qtl,
    performance_pct,
    yield_status
FROM vw_crop_yield_summary
ORDER BY performance_pct DESC;


-- ----------------------------------------------------------------------------
-- 6. TRIGGER-GENERATED PRICE ALERTS
-- ----------------------------------------------------------------------------

SELECT
    alert_id,
    alert_date,
    crop_name,
    market_name,
    deviation_pct || '%' AS deviation,
    alert_severity,
    alert_direction,
    alert_message
FROM vw_price_alert_feed;


-- ----------------------------------------------------------------------------
-- 7. DISTRIBUTED DATA: HORIZONTAL FRAGMENTATION & RECONSTRUCTION
-- ----------------------------------------------------------------------------

SELECT
    'Fragment: Nashik Mandi Node' AS dataset,
    COUNT(*) AS total_records
FROM vw_mandi_frag_nashik

UNION ALL

SELECT
    'Fragment: Pune Mandi Node' AS dataset,
    COUNT(*) AS total_records
FROM vw_mandi_frag_pune

UNION ALL

SELECT
    'Fragment: Ahmednagar Node' AS dataset,
    COUNT(*) AS total_records
FROM vw_mandi_frag_ahmednagar

UNION ALL

SELECT
    'Federated Global Union' AS dataset,
    COUNT(*) AS total_records
FROM vw_mandi_consolidated_federation;