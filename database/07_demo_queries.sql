-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — Core Demonstration & Analytical Queries
-- Script: 07_demo_queries.sql
-- Description:
--   Executes all primary business and analytical queries requested in the
--   presentation (Slides 8, 9, 11) and project specifications:
--   1. Top 3 markets for Wheat (Slide 11 presentation query)
--   2. Best market stored procedure invocation (Slide 9)
--   3. Farmer expected revenue stored function (Slide 9)
--   4. Explicit cursor demonstration execution
--   5. Expected vs Actual Yield variance and performance report
--   6. Trigger-generated price alerts inspection
--   7. Distributed horizontal fragmentation and reconstruction query
-- ============================================================================

SET LINESIZE 200;
SET PAGESIZE 100;
SET SERVEROUTPUT ON;
COL market_name FORMAT A25;
COL district FORMAT A15;
COL crop_name FORMAT A15;
COL farmer_name FORMAT A20;
COL alert_message FORMAT A60;

PROMPT ================================================================================
PROMPT 1. SLIDE 11 QUERY: TOP 3 MARKETS FOR WHEAT (LAST 30 DAYS)
PROMPT ================================================================================
SELECT 
    m.market_name,
    m.district,
    ROUND(AVG(p.modal_price), 2) AS avg_price_rs_qtl,
    COUNT(p.price_id)            AS total_observations
FROM   PRICE_RECORD p
JOIN   MARKET m ON m.market_id = p.market_id
JOIN   CROP c   ON c.crop_id = p.crop_id
WHERE  c.crop_name = 'Wheat'
  AND  p.price_date >= (TRUNC(SYSDATE) - 30)
GROUP  BY m.market_name, m.district
ORDER  BY avg_price_rs_qtl DESC
FETCH FIRST 3 ROWS ONLY;

PROMPT ================================================================================
PROMPT 2. PL/SQL STORED PROCEDURE CALL: proc_best_market FOR WHEAT & ONION
PROMPT ================================================================================
DECLARE
    v_mkt_id   NUMBER;
    v_mkt_name VARCHAR2(100);
    v_price    NUMBER;
    v_result   VARCHAR2(255);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Testing proc_best_market for Wheat (Crop ID 1) ---');
    proc_best_market(1, v_mkt_id, v_mkt_name, v_price, v_result);
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_result);

    DBMS_OUTPUT.PUT_LINE('--- Testing proc_best_market for Onion (Crop ID 2) ---');
    proc_best_market(2, v_mkt_id, v_mkt_name, v_price, v_result);
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_result);

    DBMS_OUTPUT.PUT_LINE('--- Testing proc_best_market for Grapes (Crop ID 5) ---');
    proc_best_market(5, v_mkt_id, v_mkt_name, v_price, v_result);
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_result);
END;
/

PROMPT ================================================================================
PROMPT 3. PL/SQL STORED FUNCTION CALL: fn_expected_revenue IN SELECT QUERY
PROMPT Calculates expected revenue = (Latest Harvested Yield) * (Recent Modal Price)
PROMPT ================================================================================
SELECT 
    f.farmer_id,
    f.name                         AS farmer_name,
    f.district                     AS farmer_district,
    c.crop_id,
    c.crop_name,
    fn_expected_revenue(f.farmer_id, c.crop_id) AS projected_revenue_inr
FROM FARMER f
CROSS JOIN CROP c
WHERE fn_expected_revenue(f.farmer_id, c.crop_id) > 0
ORDER BY projected_revenue_inr DESC;

PROMPT ================================================================================
PROMPT 4. EXPLICIT CURSOR LIFECYCLE DEMONSTRATION
PROMPT Executes proc_cursor_demo_market_summary for Crop ID 1 (Wheat)
PROMPT ================================================================================
BEGIN
    proc_cursor_demo_market_summary(1);
END;
/

PROMPT ================================================================================
PROMPT 5. EXPECTED VS ACTUAL YIELD VARIANCE REPORT (FROM VIEW)
PROMPT ================================================================================
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

PROMPT ================================================================================
PROMPT 6. TRIGGER-GENERATED PRICE ALERTS (FROM trg_price_alert COMPOUND TRIGGER)
PROMPT ================================================================================
SELECT 
    alert_id,
    TO_CHAR(alert_date, 'YYYY-MM-DD') AS alert_date,
    crop_name,
    market_name,
    deviation_pct || '%' AS deviation,
    alert_severity,
    alert_direction,
    alert_message
FROM vw_price_alert_feed;

PROMPT ================================================================================
PROMPT 7. DISTRIBUTED DATA CONCEPT: HORIZONTAL FRAGMENTATION & RECONSTRUCTION
PROMPT Compares simulated regional node counts with global federated union
PROMPT ================================================================================
SELECT 'Fragment: Nashik Mandi Node' AS dataset, COUNT(*) AS total_records FROM vw_mandi_frag_nashik
UNION ALL
SELECT 'Fragment: Pune Mandi Node'   AS dataset, COUNT(*) AS total_records FROM vw_mandi_frag_pune
UNION ALL
SELECT 'Fragment: Ahmednagar Node'   AS dataset, COUNT(*) AS total_records FROM vw_mandi_frag_ahmednagar
UNION ALL
SELECT 'Federated Global Union'      AS dataset, COUNT(*) AS total_records FROM vw_mandi_consolidated_federation;

PROMPT ================================================================================
PROMPT 8. TOP 3 MARKETS RANKED PER CROP (FROM vw_top_three_markets)
PROMPT ================================================================================
SELECT 
    crop_name,
    market_rank,
    market_name,
    district,
    avg_modal_price AS avg_modal_price_rs_qtl
FROM vw_top_three_markets
ORDER BY crop_name, market_rank;

PROMPT ================================================================================
PROMPT 9. REALIZED SALES & FARMER REVENUE SUMMARY (FROM VIEW)
PROMPT ================================================================================
SELECT 
    farmer_name,
    district,
    total_sales_count,
    total_quantity_sold_qtl,
    total_revenue_inr,
    avg_realized_price_per_qtl
FROM vw_farmer_revenue_summary
WHERE total_sales_count > 0
ORDER BY total_revenue_inr DESC;
