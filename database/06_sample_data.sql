-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — Comprehensive Sample Data Seeding
-- Script: 06_sample_data.sql
-- Description:
--   Seeds 8 Farmers, 11 Fields, 6 Crops with EER Specializations,
--   5 APMC Mandis, seasonal Yield Records, dynamic 30-day Price Records,
--   Sale Transactions, and Demo Users for RBAC testing.
-- ============================================================================

SET SERVEROUTPUT ON;

-- ----------------------------------------------------------------------------
-- 1. SEED FARMERS (8 Farmers across Maharashtra agricultural belts)
-- ----------------------------------------------------------------------------
INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Ramesh Patil', '9822011223', 'Vinchur', 'Nashik', 12.50);

INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Suresh Deshmukh', '9822022334', 'Dindori', 'Nashik', 8.00);

INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Vikas Shinde', '9822033445', 'Baramati', 'Pune', 15.00);

INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Santosh Jadhav', '9822044556', 'Narayangaon', 'Pune', 6.50);

INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Prakash Kadam', '9822055667', 'Rahuri', 'Ahmednagar', 10.00);

INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Ganesh Pawar', '9822066778', 'Sangamner', 'Ahmednagar', 7.50);

INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Sunita More', '9822077889', 'Pachora', 'Jalgaon', 5.00);

INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Rajesh Thorat', '9822088990', 'Niphad', 'Nashik', 9.00);

COMMIT;

-- ----------------------------------------------------------------------------
-- 2. SEED FIELDS (11 Land Parcels linked to Farmers)
-- ----------------------------------------------------------------------------
-- Farmer 1 (Ramesh Patil - Nashik)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (1, 'Vinchur North Plot A', 'Black Soil', 6.50);
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (1, 'Vinchur Canal Parcel B', 'Alluvial', 6.00);

-- Farmer 2 (Suresh Deshmukh - Nashik)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (2, 'Dindori Hill slope', 'Red Soil', 4.50);
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (2, 'Dindori Valley Basin', 'Black Soil', 3.50);

-- Farmer 3 (Vikas Shinde - Pune)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (3, 'Baramati Canal Road', 'Black Soil', 10.00);
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (3, 'Baramati South Orchard', 'Clay Loam', 5.00);

-- Farmer 4 (Santosh Jadhav - Pune)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (4, 'Narayangaon Bypass', 'Alluvial', 6.50);

-- Farmer 5 (Prakash Kadam - Ahmednagar)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (5, 'Rahuri Farm Sector 1', 'Black Soil', 5.50);
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (5, 'Rahuri Farm Sector 2', 'Sandy Loam', 4.50);

-- Farmer 6 (Ganesh Pawar - Ahmednagar)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (6, 'Sangamner Riverbank', 'Alluvial', 7.50);

-- Farmer 7 (Sunita More - Jalgaon)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (7, 'Pachora Central Field', 'Black Soil', 5.00);

-- Farmer 8 (Rajesh Thorat - Nashik)
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES (8, 'Niphad Vineyard Block 1', 'Clay Loam', 9.00);

COMMIT;

-- ----------------------------------------------------------------------------
-- 3. SEED CROPS (6 Major Crops)
-- ----------------------------------------------------------------------------
INSERT INTO CROP (crop_id, crop_name, category, season) VALUES (1, 'Wheat', 'Cereal', 'Rabi');
INSERT INTO CROP (crop_id, crop_name, category, season) VALUES (2, 'Onion', 'Vegetable', 'Rabi');
INSERT INTO CROP (crop_id, crop_name, category, season) VALUES (3, 'Tomato', 'Vegetable', 'Kharif');
INSERT INTO CROP (crop_id, crop_name, category, season) VALUES (4, 'Soybean', 'Oilseed', 'Kharif');
INSERT INTO CROP (crop_id, crop_name, category, season) VALUES (5, 'Grapes', 'Fruit', 'Perennial');
INSERT INTO CROP (crop_id, crop_name, category, season) VALUES (6, 'Rice', 'Cereal', 'Kharif');

COMMIT;

-- ----------------------------------------------------------------------------
-- 4. SEED CROP SPECIALIZATION TABLES (EER 1:1 Subclasses)
-- ----------------------------------------------------------------------------
-- CEREAL_CROP (avg_duration_days)
INSERT INTO CEREAL_CROP (crop_id, avg_duration_days) VALUES (1, 120); -- Wheat
INSERT INTO CEREAL_CROP (crop_id, avg_duration_days) VALUES (4, 105); -- Soybean
INSERT INTO CEREAL_CROP (crop_id, avg_duration_days) VALUES (6, 135); -- Rice

-- VEGETABLE_CROP (perishability_days)
INSERT INTO VEGETABLE_CROP (crop_id, perishability_days) VALUES (2, 60); -- Onion
INSERT INTO VEGETABLE_CROP (crop_id, perishability_days) VALUES (3, 14); -- Tomato

-- FRUIT_CROP (harvest_cycle_years)
INSERT INTO FRUIT_CROP (crop_id, harvest_cycle_years) VALUES (5, 1.0); -- Grapes

COMMIT;

-- ----------------------------------------------------------------------------
-- 5. SEED MARKETS (5 Prominent APMC Mandis)
-- ----------------------------------------------------------------------------
INSERT INTO MARKET (market_id, market_name, district, state) VALUES
(1, 'Lasalgaon APMC', 'Nashik', 'Maharashtra');

INSERT INTO MARKET (market_id, market_name, district, state) VALUES
(2, 'Nashik APMC', 'Nashik', 'Maharashtra');

INSERT INTO MARKET (market_id, market_name, district, state) VALUES
(3, 'Pune Mandi (Gultekdi)', 'Pune', 'Maharashtra');

INSERT INTO MARKET (market_id, market_name, district, state) VALUES
(4, 'Pimpalgaon Baswant APMC', 'Nashik', 'Maharashtra');

INSERT INTO MARKET (market_id, market_name, district, state) VALUES
(5, 'Ahmednagar APMC', 'Ahmednagar', 'Maharashtra');

COMMIT;

-- ----------------------------------------------------------------------------
-- 6. SEED YIELD RECORDS (Seasonal cultivation across fields)
-- ----------------------------------------------------------------------------
-- Field 1 (Farmer 1, Black Soil) - Onion Rabi
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (1, 2, TO_DATE('2025-11-15', 'YYYY-MM-DD'), TO_DATE('2026-03-20', 'YYYY-MM-DD'), 120.00, 135.50);

-- Field 2 (Farmer 1, Alluvial) - Wheat Rabi
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (2, 1, TO_DATE('2025-11-20', 'YYYY-MM-DD'), TO_DATE('2026-03-25', 'YYYY-MM-DD'), 90.00, 94.00);

-- Field 3 (Farmer 2, Red Soil) - Tomato Kharif
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (3, 3, TO_DATE('2026-06-10', 'YYYY-MM-DD'), TO_DATE('2026-09-15', 'YYYY-MM-DD'), 150.00, 142.00);

-- Field 4 (Farmer 2, Black Soil) - Onion Kharif
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (4, 2, TO_DATE('2026-06-25', 'YYYY-MM-DD'), TO_DATE('2026-10-05', 'YYYY-MM-DD'), 80.00, 85.00);

-- Field 5 (Farmer 3, Black Soil) - Soybean Kharif
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (5, 4, TO_DATE('2026-06-15', 'YYYY-MM-DD'), TO_DATE('2026-10-01', 'YYYY-MM-DD'), 110.00, 118.00);

-- Field 6 (Farmer 3, Clay Loam) - Grapes Perennial
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (6, 5, TO_DATE('2025-04-10', 'YYYY-MM-DD'), TO_DATE('2026-02-28', 'YYYY-MM-DD'), 75.00, 72.50);

-- Field 7 (Farmer 4, Alluvial) - Tomato Kharif
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (7, 3, TO_DATE('2026-06-20', 'YYYY-MM-DD'), TO_DATE('2026-09-28', 'YYYY-MM-DD'), 130.00, 125.00);

-- Field 8 (Farmer 5, Black Soil) - Wheat Rabi
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (8, 1, TO_DATE('2025-11-10', 'YYYY-MM-DD'), TO_DATE('2026-03-18', 'YYYY-MM-DD'), 85.00, 88.00);

-- Field 10 (Farmer 6, Alluvial) - Rice Kharif
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (10, 6, TO_DATE('2026-06-15', 'YYYY-MM-DD'), TO_DATE('2026-10-10', 'YYYY-MM-DD'), 95.00, 92.00);

-- Field 11 (Farmer 8, Clay Loam) - Grapes Perennial
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl)
VALUES (11, 5, TO_DATE('2025-05-01', 'YYYY-MM-DD'), TO_DATE('2026-03-05', 'YYYY-MM-DD'), 110.00, 115.00);

COMMIT;

-- ----------------------------------------------------------------------------
-- 7. SEED 30 DAYS OF DYNAMIC DAILY PRICE RECORDS
-- Generates 30 days of historical prices relative to TRUNC(SYSDATE).
-- Covers 6 crops across 5 mandis with realistic modal price ranges.
-- ----------------------------------------------------------------------------
DECLARE
    v_base_date DATE := TRUNC(SYSDATE);
    TYPE t_price_cfg IS RECORD (
        crop_id   NUMBER,
        market_id NUMBER,
        base_modal NUMBER,
        variation  NUMBER
    );
    TYPE t_cfg_list IS TABLE OF t_price_cfg INDEX BY PLS_INTEGER;
    v_configs t_cfg_list;
    v_cur_modal NUMBER;
    v_min_price NUMBER;
    v_max_price NUMBER;
BEGIN
    -- Configure realistic base price profiles
    -- Wheat: Lasalgaon (Rs. 2340), Nashik (Rs. 2275), Pune (Rs. 2190), Ahmednagar (Rs. 2220)
    v_configs(1).crop_id := 1; v_configs(1).market_id := 1; v_configs(1).base_modal := 2340; v_configs(1).variation := 25;
    v_configs(2).crop_id := 1; v_configs(2).market_id := 2; v_configs(2).base_modal := 2275; v_configs(2).variation := 20;
    v_configs(3).crop_id := 1; v_configs(3).market_id := 3; v_configs(3).base_modal := 2190; v_configs(3).variation := 30;
    v_configs(4).crop_id := 1; v_configs(4).market_id := 5; v_configs(4).base_modal := 2220; v_configs(4).variation := 20;

    -- Onion: Lasalgaon (Rs. 1950 - benchmark hub), Nashik (Rs. 1820), Pimpalgaon (Rs. 1890), Pune (Rs. 1750)
    v_configs(5).crop_id := 2; v_configs(5).market_id := 1; v_configs(5).base_modal := 1950; v_configs(5).variation := 45;
    v_configs(6).crop_id := 2; v_configs(6).market_id := 2; v_configs(6).base_modal := 1820; v_configs(6).variation := 35;
    v_configs(7).crop_id := 2; v_configs(7).market_id := 4; v_configs(7).base_modal := 1890; v_configs(7).variation := 40;
    v_configs(8).crop_id := 2; v_configs(8).market_id := 3; v_configs(8).base_modal := 1750; v_configs(8).variation := 30;

    -- Tomato: Pimpalgaon (Rs. 1580), Nashik (Rs. 1490), Pune (Rs. 1620)
    v_configs(9).crop_id  := 3; v_configs(9).market_id  := 4; v_configs(9).base_modal := 1580; v_configs(9).variation := 50;
    v_configs(10).crop_id := 3; v_configs(10).market_id := 2; v_configs(10).base_modal := 1490; v_configs(10).variation := 40;
    v_configs(11).crop_id := 3; v_configs(11).market_id := 3; v_configs(11).base_modal := 1620; v_configs(11).variation := 60;

    -- Soybean: Ahmednagar (Rs. 4450), Pune (Rs. 4380), Nashik (Rs. 4310)
    v_configs(12).crop_id := 4; v_configs(12).market_id := 5; v_configs(12).base_modal := 4450; v_configs(12).variation := 40;
    v_configs(13).crop_id := 4; v_configs(13).market_id := 3; v_configs(13).base_modal := 4380; v_configs(13).variation := 35;
    v_configs(14).crop_id := 4; v_configs(14).market_id := 2; v_configs(14).base_modal := 4310; v_configs(14).variation := 30;

    -- Grapes: Pimpalgaon (Rs. 6800), Nashik (Rs. 6500), Pune (Rs. 6300)
    v_configs(15).crop_id := 5; v_configs(15).market_id := 4; v_configs(15).base_modal := 6800; v_configs(15).variation := 80;
    v_configs(16).crop_id := 5; v_configs(16).market_id := 2; v_configs(16).base_modal := 6500; v_configs(16).variation := 75;
    v_configs(17).crop_id := 5; v_configs(17).market_id := 3; v_configs(17).base_modal := 6300; v_configs(17).variation := 70;

    -- Rice: Pune (Rs. 3150), Ahmednagar (Rs. 2980), Nashik (Rs. 2920)
    v_configs(18).crop_id := 6; v_configs(18).market_id := 3; v_configs(18).base_modal := 3150; v_configs(18).variation := 30;
    v_configs(19).crop_id := 6; v_configs(19).market_id := 5; v_configs(19).base_modal := 2980; v_configs(19).variation := 25;
    v_configs(20).crop_id := 6; v_configs(20).market_id := 2; v_configs(20).base_modal := 2920; v_configs(20).variation := 25;

    -- Loop over 30 days into the past (day 29 down to 0 = today)
    FOR d IN REVERSE 0 .. 29 LOOP
        FOR c IN 1 .. v_configs.COUNT LOOP
            -- Introduce natural sinusoidal / pseudorandom variation across days
            v_cur_modal := v_configs(c).base_modal +
                           ROUND(SIN((d + v_configs(c).market_id) * 0.7) * v_configs(c).variation);
            v_min_price := v_cur_modal - ROUND(v_configs(c).variation * 2.2);
            v_max_price := v_cur_modal + ROUND(v_configs(c).variation * 2.5);

            -- Ensure min <= modal <= max
            IF v_min_price >= v_cur_modal THEN v_min_price := v_cur_modal - 50; END IF;
            IF v_max_price <= v_cur_modal THEN v_max_price := v_cur_modal + 50; END IF;

            INSERT INTO PRICE_RECORD (
                market_id,
                crop_id,
                price_date,
                min_price,
                max_price,
                modal_price
            ) VALUES (
                v_configs(c).market_id,
                v_configs(c).crop_id,
                v_base_date - d,
                v_min_price,
                v_max_price,
                v_cur_modal
            );
        END LOOP;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully inserted 30 days of dynamic price history across markets.');
END;
/

-- ----------------------------------------------------------------------------
-- 8. TRIGGER STIMULATION: UNUSUAL PRICE SPIKE (Tests trg_price_alert)
-- Inserts a deliberate +28% surge on Tomato at Pune Mandi today.
-- Baseline 7-day average is ~1620; price of 2150 exceeds +20% threshold.
-- ----------------------------------------------------------------------------
INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
VALUES (3, 3, TRUNC(SYSDATE) + 1, 1950.00, 2300.00, 2150.00);

COMMIT;

-- ----------------------------------------------------------------------------
-- 9. SEED SALE TRANSACTIONS
-- Records completed transactions. total_amount is virtual (quantity * price).
-- ----------------------------------------------------------------------------
INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl)
VALUES (1, 1, 2, 85.00, TRUNC(SYSDATE) - 10, 1980.00); -- Ramesh sold 85 qtl Onion at Lasalgaon

INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl)
VALUES (1, 2, 1, 50.00, TRUNC(SYSDATE) - 15, 2280.00); -- Ramesh sold 50 qtl Wheat at Nashik APMC

INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl)
VALUES (2, 4, 3, 70.00, TRUNC(SYSDATE) - 5, 1590.00);  -- Suresh sold 70 qtl Tomato at Pimpalgaon

INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl)
VALUES (3, 3, 4, 100.00, TRUNC(SYSDATE) - 8, 4390.00); -- Vikas sold 100 qtl Soybean at Pune Mandi

INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl)
VALUES (4, 3, 3, 80.00, TRUNC(SYSDATE) - 4, 1610.00);  -- Santosh sold 80 qtl Tomato at Pune Mandi

INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl)
VALUES (5, 5, 1, 65.00, TRUNC(SYSDATE) - 12, 2210.00); -- Prakash sold 65 qtl Wheat at Ahmednagar

INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl)
VALUES (8, 4, 5, 90.00, TRUNC(SYSDATE) - 3, 6850.00);  -- Rajesh sold 90 qtl Grapes at Pimpalgaon

COMMIT;

-- ----------------------------------------------------------------------------
-- 10. SEED DEMO USERS (APP_USER for Role-Based Access Control)
-- Password Hashes: SHA-256 for local testing / bcrypt-compatible in Node.js.
-- Standard default test password for all demo accounts: 'Password@123'
-- SHA-256('Password@123') = ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f
-- ----------------------------------------------------------------------------
INSERT INTO APP_USER (username, password_hash, full_name, role, farmer_id, market_id)
VALUES ('admin', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
        'System Administrator', 'ADMIN', NULL, NULL);

INSERT INTO APP_USER (username, password_hash, full_name, role, farmer_id, market_id)
VALUES ('officer_lasalgaon', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
        'Vijay Kulkarni (Lasalgaon Officer)', 'OFFICER', NULL, 1);

INSERT INTO APP_USER (username, password_hash, full_name, role, farmer_id, market_id)
VALUES ('officer_pune', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
        'Anil Bhosle (Pune Mandi Officer)', 'OFFICER', NULL, 3);

INSERT INTO APP_USER (username, password_hash, full_name, role, farmer_id, market_id)
VALUES ('farmer_ramesh', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
        'Ramesh Patil', 'FARMER', 1, NULL);

INSERT INTO APP_USER (username, password_hash, full_name, role, farmer_id, market_id)
VALUES ('farmer_suresh', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
        'Suresh Deshmukh', 'FARMER', 2, NULL);

COMMIT;
