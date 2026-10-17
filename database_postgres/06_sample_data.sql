-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — PostgreSQL Sample Data Seeding
-- Script: database_postgres/06_sample_data.sql
-- ============================================================================

-- Seed 8 Farmers
INSERT INTO FARMER (name, phone, village, district, land_area_acres) VALUES
('Ramesh Patil', '9822011223', 'Vinchur', 'Nashik', 12.50),
('Suresh Deshmukh', '9822022334', 'Dindori', 'Nashik', 8.00),
('Vikas Shinde', '9822033445', 'Baramati', 'Pune', 15.00),
('Santosh Jadhav', '9822044556', 'Narayangaon', 'Pune', 6.50),
('Prakash Kadam', '9822055667', 'Rahuri', 'Ahmednagar', 10.00),
('Ganesh Pawar', '9822066778', 'Sangamner', 'Ahmednagar', 7.50),
('Sunita More', '9822077889', 'Pachora', 'Jalgaon', 5.00),
('Rajesh Thorat', '9822088990', 'Niphad', 'Nashik', 9.00)
ON CONFLICT (phone) DO NOTHING;

-- Seed 11 Fields
INSERT INTO FIELD (farmer_id, location, soil_type, area_acres) VALUES
(1, 'Vinchur North Plot A', 'Black Soil', 6.50),
(1, 'Vinchur Canal Parcel B', 'Alluvial', 6.00),
(2, 'Dindori Hill slope', 'Red Soil', 4.50),
(2, 'Dindori Valley Basin', 'Black Soil', 3.50),
(3, 'Baramati Canal Road', 'Black Soil', 10.00),
(3, 'Baramati South Orchard', 'Clay Loam', 5.00),
(4, 'Narayangaon Bypass', 'Alluvial', 6.50),
(5, 'Rahuri Farm Sector 1', 'Black Soil', 5.50),
(5, 'Rahuri Farm Sector 2', 'Sandy Loam', 4.50),
(6, 'Sangamner Riverbank', 'Alluvial', 7.50),
(8, 'Niphad Vineyard Block 1', 'Clay Loam', 9.00);

-- Seed 6 Crops
INSERT INTO CROP (crop_id, crop_name, category, season) VALUES
(1, 'Wheat', 'Cereal', 'Rabi'),
(2, 'Onion', 'Vegetable', 'Rabi'),
(3, 'Tomato', 'Vegetable', 'Kharif'),
(4, 'Soybean', 'Oilseed', 'Kharif'),
(5, 'Grapes', 'Fruit', 'Perennial'),
(6, 'Rice', 'Cereal', 'Kharif')
ON CONFLICT (crop_name) DO NOTHING;

-- Seed Crop Specializations (1:1 Disjoint EER Subclasses)
INSERT INTO CEREAL_CROP (crop_id, avg_duration_days) VALUES (1, 120), (4, 105), (6, 135)
ON CONFLICT (crop_id) DO NOTHING;

INSERT INTO VEGETABLE_CROP (crop_id, perishability_days) VALUES (2, 60), (3, 14)
ON CONFLICT (crop_id) DO NOTHING;

INSERT INTO FRUIT_CROP (crop_id, harvest_cycle_years) VALUES (5, 1.0)
ON CONFLICT (crop_id) DO NOTHING;

-- Seed 5 Mandis
INSERT INTO MARKET (market_id, market_name, district, state) VALUES
(1, 'Lasalgaon APMC', 'Nashik', 'Maharashtra'),
(2, 'Nashik APMC', 'Nashik', 'Maharashtra'),
(3, 'Pune Mandi (Gultekdi)', 'Pune', 'Maharashtra'),
(4, 'Pimpalgaon Baswant APMC', 'Nashik', 'Maharashtra'),
(5, 'Ahmednagar APMC', 'Ahmednagar', 'Maharashtra')
ON CONFLICT (market_name, district) DO NOTHING;

-- Seed Seasonal Yield Records
INSERT INTO YIELD_RECORD (field_id, crop_id, sowing_date, harvest_date, expected_yield_qtl, actual_yield_qtl) VALUES
(1, 2, '2025-11-15', '2026-03-20', 120.00, 135.50),
(2, 1, '2025-11-20', '2026-03-25', 90.00, 94.00),
(3, 3, '2026-06-10', '2026-09-15', 150.00, 142.00),
(4, 2, '2026-06-25', '2026-10-05', 80.00, 85.00),
(5, 4, '2026-06-15', '2026-10-01', 110.00, 118.00),
(6, 5, '2025-04-10', '2026-02-28', 75.00, 72.50),
(7, 3, '2026-06-20', '2026-09-28', 130.00, 125.00),
(8, 1, '2025-11-10', '2026-03-18', 85.00, 88.00),
(10, 5, '2025-05-01', '2026-03-05', 110.00, 115.00);

-- Seed 30 Days of Dynamic Daily Prices across Mandis
DO $$
DECLARE
    d INTEGER;
BEGIN
    FOR d IN 0..29 LOOP
        -- Wheat: Lasalgaon (Rs. 2340), Nashik (Rs. 2275), Pune (Rs. 2190), Ahmednagar (Rs. 2220)
        INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
        VALUES (1, 1, CURRENT_DATE - d, 2200 + (d % 3)*15, 2450 + (d % 3)*15, 2340 + (d % 4)*10),
               (2, 1, CURRENT_DATE - d, 2150 + (d % 3)*10, 2380 + (d % 3)*10, 2275 + (d % 3)*10),
               (3, 1, CURRENT_DATE - d, 2050 + (d % 4)*15, 2290 + (d % 4)*15, 2190 + (d % 4)*10),
               (5, 1, CURRENT_DATE - d, 2100 + (d % 3)*10, 2320 + (d % 3)*10, 2220 + (d % 3)*10)
        ON CONFLICT (market_id, crop_id, price_date) DO NOTHING;

        -- Onion: Lasalgaon (Rs. 1950), Nashik (Rs. 1820), Pimpalgaon (Rs. 1890), Pune (Rs. 1750)
        INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
        VALUES (1, 2, CURRENT_DATE - d, 1800 + (d % 5)*20, 2100 + (d % 5)*20, 1950 + (d % 5)*15),
               (2, 2, CURRENT_DATE - d, 1700 + (d % 4)*15, 1950 + (d % 4)*15, 1820 + (d % 4)*15),
               (4, 2, CURRENT_DATE - d, 1750 + (d % 4)*20, 2020 + (d % 4)*20, 1890 + (d % 4)*15),
               (3, 2, CURRENT_DATE - d, 1620 + (d % 3)*15, 1880 + (d % 3)*15, 1750 + (d % 3)*10)
        ON CONFLICT (market_id, crop_id, price_date) DO NOTHING;

        -- Tomato: Pimpalgaon (Rs. 1580), Nashik (Rs. 1490), Pune (Rs. 1620)
        INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
        VALUES (4, 3, CURRENT_DATE - d, 1420 + (d % 4)*25, 1720 + (d % 4)*25, 1580 + (d % 4)*20),
               (2, 3, CURRENT_DATE - d, 1350 + (d % 3)*20, 1620 + (d % 3)*20, 1490 + (d % 3)*15),
               (3, 3, CURRENT_DATE - d, 1480 + (d % 5)*25, 1780 + (d % 5)*25, 1620 + (d % 5)*20)
        ON CONFLICT (market_id, crop_id, price_date) DO NOTHING;

        -- Soybean: Ahmednagar (Rs. 4450), Pune (Rs. 4380)
        INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
        VALUES (5, 4, CURRENT_DATE - d, 4300 + (d % 3)*20, 4600 + (d % 3)*20, 4450 + (d % 3)*15),
               (3, 4, CURRENT_DATE - d, 4220 + (d % 4)*15, 4520 + (d % 4)*15, 4380 + (d % 4)*15)
        ON CONFLICT (market_id, crop_id, price_date) DO NOTHING;

        -- Grapes: Pimpalgaon (Rs. 6800), Nashik (Rs. 6500)
        INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
        VALUES (4, 5, CURRENT_DATE - d, 6500 + (d % 4)*40, 7100 + (d % 4)*40, 6800 + (d % 4)*30),
               (2, 5, CURRENT_DATE - d, 6200 + (d % 3)*35, 6800 + (d % 3)*35, 6500 + (d % 3)*30)
        ON CONFLICT (market_id, crop_id, price_date) DO NOTHING;

        -- Rice: Pune (Rs. 3150), Ahmednagar (Rs. 2980)
        INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
        VALUES (3, 6, CURRENT_DATE - d, 3000 + (d % 3)*20, 3300 + (d % 3)*20, 3150 + (d % 3)*15),
               (5, 6, CURRENT_DATE - d, 2850 + (d % 2)*15, 3120 + (d % 2)*15, 2980 + (d % 2)*15)
        ON CONFLICT (market_id, crop_id, price_date) DO NOTHING;
    END LOOP;
END;
$$;

-- Trigger Test Spike: +28% Price Spike on Tomato at Pune Mandi
INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
VALUES (3, 3, CURRENT_DATE + 1, 1950.00, 2300.00, 2150.00)
ON CONFLICT (market_id, crop_id, price_date) DO NOTHING;

-- Seed Sale Transactions
INSERT INTO SALE_TRANSACTION (farmer_id, market_id, crop_id, quantity_qtl, sale_date, price_per_qtl) VALUES
(1, 1, 2, 85.00, CURRENT_DATE - 10, 1980.00),
(1, 2, 1, 50.00, CURRENT_DATE - 15, 2280.00),
(2, 4, 3, 70.00, CURRENT_DATE - 5, 1590.00),
(3, 3, 4, 100.00, CURRENT_DATE - 8, 4390.00),
(4, 3, 3, 80.00, CURRENT_DATE - 4, 1610.00),
(5, 5, 1, 65.00, CURRENT_DATE - 12, 2210.00),
(8, 4, 5, 90.00, CURRENT_DATE - 3, 6850.00);

-- Seed Demo Users (Password: Password@123)
INSERT INTO APP_USER (username, password_hash, full_name, role, farmer_id, market_id) VALUES
('admin', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'System Administrator', 'ADMIN', NULL, NULL),
('officer_lasalgaon', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Vijay Kulkarni (Lasalgaon Officer)', 'OFFICER', NULL, 1),
('officer_pune', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Anil Bhosle (Pune Mandi Officer)', 'OFFICER', NULL, 3),
('farmer_ramesh', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Ramesh Patil', 'FARMER', 1, NULL),
('farmer_suresh', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Suresh Deshmukh', 'FARMER', 2, NULL)
ON CONFLICT (username) DO NOTHING;

-- Seed Seller Market Assignments (Authorized Mandis)
INSERT INTO SELLER_MARKET_ASSIGNMENT (user_id, market_id) VALUES
(2, 1), -- officer_lasalgaon -> Lasalgaon APMC
(3, 3), -- officer_pune -> Pune Mandi (Gultekdi)
(1, 1), -- admin -> all mandis
(1, 2),
(1, 3),
(1, 4),
(1, 5)
ON CONFLICT (user_id, market_id) DO NOTHING;

