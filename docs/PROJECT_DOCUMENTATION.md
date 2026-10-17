# Farmer-to-Market Crop Yield & Pricing Database
## Advanced Database Management Systems (ADBMS) — Comprehensive Project Report

**Academic Year:** 2026–2027  
**Project Team:**
- Shivam Chaudhari (Roll No: E213)
- Bhavya Sharma (Roll No: E223)
- Akshat Jain (Roll No: E257)

**Department:** Computer Engineering / Information Technology  
**Word Document Artifact:** `Farmer_to_Market_ADBMS_Project_Report.docx`

---

## 1. Abstract & Problem Statement

### 1.1 Motivation
Agricultural markets (APMCs / Mandis) in India handle millions of quintals of daily crop arrivals. However, smallholder farmers often suffer from severe information asymmetry:
1. **Scattered Yield Records:** Sowing, harvesting, and yield metrics are maintained in disparate paper registers per field and are never consolidated.
2. **Price Volatility & Opacity:** Mandi prices fluctuate daily across adjacent regional markets; farmers decide where and when to sell based largely on hearsay or word-of-mouth.
3. **Disconnected Weather Feeds:** Critical rainfall and temperature observations recorded by regional weather sensors are never systematically linked with harvest outcomes or price forecasting.

### 1.2 Project Objectives
This project designs and implements an **Advanced Database Management System (ADBMS)** that connects farm fields, seasonal crop yields, multi-mandi daily prices, automated price alert triggers, and weather logs into a unified queryable surface.

Key capabilities demonstrated:
- Recommending the best market for any crop over recent history using explicit PL/SQL cursors.
- Projecting farmer gross revenue using deterministic stored functions.
- Detecting unusual market price swings (> 20% deviation) using non-mutating compound database triggers.
- Demonstrating **Extended Entity-Relationship (EER)** crop specialization (Cereal, Vegetable, Fruit).
- Ensuring **Third Normal Form (3NF)** relational normalization across all transaction paths.
- Demonstrating **Polyglot Persistence** (Oracle RDBMS for transactional data + MongoDB for sensor JSON logs).
- Simulating **Logical Horizontal Fragmentation** and global reconstruction across regional mandi nodes.

---

## 2. System Architecture & Polyglot Model

```
+-----------------------------------------------------------------------------------+
|                            USER DASHBOARDS & CLIENT APIS                           |
|                    (Farmers, Mandi Officers, Agricultural Admin)                  |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                        FEDERATED MIDDLEWARE SERVICE LAYER                          |
|                     (Node.js / Express REST API Polyglot Router)                   |
+-----------------------------------------------------------------------------------+
                  /                                                 \
                 v                                                   v
+-----------------------------------------+         +-------------------------------+
|          CENTRAL ORACLE RDBMS           |         |       MONGODB DOCUMENT STORE   |
|-----------------------------------------|         |-------------------------------|
|  - Structured Master Data (3NF)         |         |  - WEATHER_LOG (JSON Docs)    |
|  - FARMER, FIELD, CROP                  |         |  - Flexible sensor attributes |
|  - CEREAL / VEG / FRUIT Specialization  |         |  - High frequency ingestion   |
|  - YIELD_RECORD, PRICE_RECORD           |         |  - Queried by district + date |
|  - Triggers, Procedures, Cursors        |         +-------------------------------+
|  - ACID Transactional Sale Records      |
+-----------------------------------------+
                 ^
                 | (Replication / Union)
+-----------------------------------------------------------------------------------+
|               DISTRIBUTED MANDI NODES (LOGICAL HORIZONTAL FRAGMENTS)               |
|      [Node A: Nashik]       |      [Node B: Pune]       |   [Node C: Ahmednagar]   |
+-----------------------------------------------------------------------------------+
```

### 2.1 Polyglot Persistence Rationale
- **Oracle Database (Relational)**: Selected for core transactional entities requiring strict schema enforcement, ACID guarantees, foreign key referential integrity, and complex PL/SQL analytical business logic.
- **MongoDB (NoSQL Document Store)**: Selected for weather observations (`temperature_c`, `rainfall_mm`, `humidity_pct`, `wind_speed_kmh`). Sensor formats vary across weather stations; a document store accommodates optional fields without schema migration overhead.

---

## 3. Extended Entity-Relationship (EER) Model & Schema Design

### 3.1 EER Specialization (1:1 Disjoint Subclasses)
Generic crop tables lead to sparse storage with excessive `NULL` values. The project implements an EER specialization with `CROP` as the superclass and three disjoint subclasses:
1. **`CEREAL_CROP`** (`crop_id PK/FK`, `avg_duration_days`): Maturity duration (60–365 days) for grains (Wheat, Rice).
2. **`VEGETABLE_CROP`** (`crop_id PK/FK`, `perishability_days`): Perishability and shelf-life (1–180 days) for perishables (Onion, Tomato).
3. **`FRUIT_CROP`** (`crop_id PK/FK`, `harvest_cycle_years`): Multi-year harvest cycles (0.1–50.0 years) for orchards (Grapes).

### 3.2 Relational Data Dictionary (3NF)

| Table Name | Primary Key | Foreign Keys | Key Attributes & Constraints |
|---|---|---|---|
| **FARMER** | `farmer_id` (Identity) | None | `name`, `phone` (UNIQUE), `village`, `district`, `land_area_acres` (> 0) |
| **FIELD** | `field_id` (Identity) | `farmer_id` | `location`, `soil_type` (Black/Alluvial/Red/Loam), `area_acres` (> 0) |
| **CROP** | `crop_id` (Identity) | None | `crop_name` (UNIQUE), `category` (Cereal/Veg/Fruit), `season` |
| **CEREAL_CROP** | `crop_id` (PK, FK) | `crop_id` | `avg_duration_days` (CHECK between 60 and 365) |
| **VEGETABLE_CROP** | `crop_id` (PK, FK) | `crop_id` | `perishability_days` (CHECK between 1 and 180) |
| **FRUIT_CROP** | `crop_id` (PK, FK) | `crop_id` | `harvest_cycle_years` (CHECK between 0.1 and 50.0) |
| **MARKET** | `market_id` (Identity) | None | `market_name`, `district`, `state`. UNIQUE on `(market_name, district)` |
| **YIELD_RECORD** | `yield_id` (Identity) | `field_id`, `crop_id` | `sowing_date`, `harvest_date`, `expected_yield_qtl`, `actual_yield_qtl` |
| **PRICE_RECORD** | `price_id` (Identity) | `market_id`, `crop_id` | `price_date`, `min_price`, `max_price`, `modal_price` (`min <= modal <= max`) |
| **SALE_TRANSACTION** | `sale_id` (Identity) | `farmer_id`, `market_id`, `crop_id` | `quantity_qtl`, `price_per_qtl`, `total_amount` (VIRTUAL column) |
| **PRICE_ALERT** | `alert_id` (Identity) | `crop_id`, `market_id` | `alert_date`, `deviation_pct`, `alert_message` (Trigger generated) |
| **APP_USER** | `user_id` (Identity) | `farmer_id`, `market_id` | `username` (UNIQUE), `password_hash`, `role` (`ADMIN`/`OFFICER`/`FARMER`) |

### 3.3 Proof of Normalization (3NF)
- **1NF**: Atomic values in all attributes; no repeating price or yield columns within `FARMER` or `CROP`.
- **2NF**: In 1NF and no partial dependencies exist. All non-prime attributes depend on the entire primary key.
- **3NF**: In 2NF and no transitive dependencies exist ($X \rightarrow Y$ and $Y \rightarrow Z$). Market district attributes reside exclusively in `MARKET`, preventing transitive dependency within `PRICE_RECORD`.

---

## 4. Advanced PL/SQL Constructs

### 4.1 Trigger 1: `trg_validate_harvest`
- **Type**: Row-level `BEFORE INSERT OR UPDATE` trigger on `YIELD_RECORD`.
- **Purpose**: Rejects any entry where `harvest_date <= sowing_date`.
- **Error Code**: Raises Oracle application error `-20001` with explicit date details.

### 4.2 Trigger 2: `trg_price_alert` (Compound Trigger)
- **Technical Challenge**: In standard Oracle PL/SQL, querying `PRICE_RECORD` inside an `AFTER INSERT ON PRICE_RECORD FOR EACH ROW` trigger raises **`ORA-04091: table is mutating`**.
- **Solution**: Implemented an **Oracle Compound Trigger** (`COMPOUND TRIGGER`):
  1. `AFTER EACH ROW`: Buffers candidate row attributes in memory (`crop_id`, `market_id`, `price_date`, `modal_price`).
  2. `AFTER STATEMENT`: Table locks are released. Queries the 7-day prior baseline average (`price_date < inserted_date`) without mutating table errors and without baseline distortion. If $|\text{deviation}| > 20\%$, auto-logs a record into `PRICE_ALERT`.

### 4.3 Stored Procedure: `proc_best_market`
- **Type**: Stored procedure with **Explicit Cursor** (`c_prices`).
- **Operation**: Demonstrates complete cursor lifecycle: `DECLARE`, `OPEN`, `FETCH`, `%FOUND` check, and `CLOSE`.
- **Output**: Returns the top mandi offering the highest 30-day average modal price for a specified crop, with safe fallback when no data exists.

### 4.4 Stored Function: `fn_expected_revenue`
- **Formula**: $\text{Projected Revenue} = (\text{Latest Harvested Yield in qtl}) \times (\text{Recent Modal Price in Rs/qtl})$
- **Robustness**: Enclosed in exception blocks returning `0` on `NO_DATA_FOUND`, allowing safe incorporation into large analytical `SELECT` statements.

### 4.5 Virtual Column in `SALE_TRANSACTION`
- `total_amount NUMBER(12, 2) GENERATED ALWAYS AS (ROUND(quantity_qtl * price_per_qtl, 2)) VIRTUAL`
- Eliminates manual trigger maintenance and guarantees 100% mathematical consistency without consuming redundant physical storage.

---

## 5. Analytical Views & Distributed Fragmentation Simulation

1. **`vw_crop_yield_summary`**: Joins farmers, fields, crops, and yields. Computes cultivation duration, yield variance (`actual - expected`), and performance status (`Exceeded Expected`, `Met Expected`, `Below Expected`).
2. **`vw_market_price_trends`**: 30-day statistical price movements (min, max, modal, spread) per crop and market.
3. **`vw_top_three_markets`**: Ranks top 3 mandis per crop using analytic window function `DENSE_RANK() OVER (PARTITION BY crop_id ORDER BY AVG(modal_price) DESC)`.
4. **`vw_price_alert_feed`**: Real-time volatility monitor classifying alerts into `CRITICAL`, `HIGH`, `PRICE_SURGE`, and `PRICE_CRASH`.
5. **`vw_farmer_revenue_summary`**: Farmer financial realization summary.
6. **Distributed Data Simulation**:
   - `vw_mandi_frag_nashik`: Horizontal slice for Nashik APMCs.
   - `vw_mandi_frag_pune`: Horizontal slice for Pune Mandis.
   - `vw_mandi_frag_ahmednagar`: Horizontal slice for Ahmednagar APMCs.
   - `vw_mandi_consolidated_federation`: Global reconstruction via `UNION ALL`, satisfying the ADBMS Reconstruction Completeness Rule.

---

## 6. Verification & Automated Test Suite Results

The automated test script (`database/08_test_cases.sql`) logs results into `TEST_RUN_LOG`:

| Test Name | Category | Status | Verification Details |
|---|---|---|---|
| **Valid Farmer & Field Insert** | DML Integrity | `PASS` | Succeeded with generated identity keys. |
| **Invalid Foreign Key** | Referential Integrity | `PASS` | Rejected non-existent farmer ID with `ORA-02291`. |
| **Trigger: trg_validate_harvest** | PL/SQL Trigger | `PASS` | Blocked harvest before sowing with error `-20001`. |
| **Negative Yield Rejection** | Domain Integrity | `PASS` | Blocked `actual_yield_qtl < 0` with `ORA-02290`. |
| **Invalid Price Constraint** | Domain Integrity | `PASS` | Blocked `min_price > max_price` with `ORA-02290`. |
| **Trigger: trg_price_alert** | PL/SQL Trigger | `PASS` | Volatile price spike (> 20%) auto-logged to `PRICE_ALERT`. |
| **Procedure: proc_best_market** | Explicit Cursor | `PASS` | Explicit cursor returned top market with 30-day average. |
| **Function: fn_expected_revenue** | PL/SQL Function | `PASS` | Calculated `(Yield * Modal Price)` and handled missing data safely. |
| **Virtual Column: total_amount** | Schema Design | `PASS` | Auto-computed `(quantity * price)` mathematically without trigger. |
| **Boundary: Missing Data** | Exception Handling | `PASS` | Handled non-existent crop gracefully without unhandled exception. |
| **RBAC Role Check Constraint** | Domain Integrity | `PASS` | Invalid user role `SUPER_ADMIN` rejected with `ORA-02290`. |

---

## 7. Slide Mapping Guide (For Faculty Presentation)

| PPT Slide | Topic | Source Code Location |
|---|---|---|
| **Slide 4** | System Architecture | Architecture Overview & Polyglot Model |
| **Slide 6** | Core Relational Schema | `database/01_create_tables.sql` (Lines 24–140) |
| **Slide 6** | EER Specialization | `database/01_create_tables.sql` (Lines 60–100) |
| **Slide 7** | Market & Transaction Tables | `database/01_create_tables.sql` (Lines 140–210) |
| **Slide 8** | Harvest Date Trigger | `database/03_create_triggers.sql` (Lines 18–37) |
| **Slide 8** | Price Alert Trigger | `database/03_create_triggers.sql` (Lines 40–150) |
| **Slide 9** | Best Market Stored Procedure | `database/04_create_procedures_functions.sql` (Lines 24–75) |
| **Slide 9** | Expected Revenue Stored Function | `database/04_create_procedures_functions.sql` (Lines 78–140) |
| **Slide 10** | Polyglot & Distributed Data | `database/05_create_views.sql` (Lines 140–210) |
| **Slide 11** | Sample Query: Top 3 Markets | `database/07_demo_queries.sql` (Lines 20–35) |

---

## 8. Summary of Files Created

1. `Farmer_to_Market_ADBMS_Project_Report.docx`: Complete Microsoft Word report ready to present.
2. `HOW_TO_USE.md`: Step-by-step simple instructions guide.
3. `database/01_create_tables.sql`: 3NF normalized tables & EER specialization.
4. `database/02_constraints_indexes.sql`: B-Tree and covering indexes.
5. `database/03_create_triggers.sql`: Triggers with compound mutating table solution.
6. `database/04_create_procedures_functions.sql`: Stored procedures, functions, explicit cursor demo.
7. `database/05_create_views.sql`: Analytical views & distributed horizontal fragments.
8. `database/06_sample_data.sql`: 8 farmers, 11 fields, 6 crops, 5 markets, 30 days of dynamic prices.
9. `database/07_demo_queries.sql`: Presentation queries (Slide 11 Wheat query).
10. `database/08_test_cases.sql`: 11-point automated test suite with report logging.
11. `database/run_all.sql`: Master runner script.
12. `.env.example` & `.gitignore`: Clean configuration templates.
