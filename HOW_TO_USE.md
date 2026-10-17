# Project User Guide: Farmer-to-Market Crop Yield & Pricing Database
**ADBMS Mini Project — Step-by-Step Instructions**

Welcome! This guide explains how to use, run, and understand this project in plain, simple English. Whether you are running the SQL scripts for the first time or preparing for your college viva presentation, this document covers everything you need.

---

## 1. What is this Project About?

In India, farmers often sell their crops based on word-of-mouth without knowing the current market prices in nearby mandis (APMC markets). At the same time, crop yield and weather data are kept in disconnected registers or notebooks.

This project solves that problem by building an **Advanced Database Management System (ADBMS)** that connects:
1. **Farmers & Fields**: Who is growing what and where.
2. **Crop Yield Lifecycle**: Sowing date, harvest date, expected vs. actual yield.
3. **Mandi Prices**: Daily min, max, and modal (most frequent) prices across multiple markets.
4. **Automated Price Alerts**: Instant database alerts when prices swing by more than 20%.
5. **Smart Decision Support**:
   - *"Which market gives the best price for Wheat today?"*
   - *"What is a farmer's expected revenue?"*
   - *"What are the top 3 markets for any crop?"*
6. **Polyglot Persistence**: Oracle Database for structured records + MongoDB for flexible weather logs.

---

## 2. Directory Structure & What Each File Does

Here is what is in your folder right now:

```text
ADBMS Project/
├── ANTIGRAVITY_PROJECT_INSTRUCTIONS.md   # Official project requirements
├── Farmer_to_Market_Crop_Yield_Pricing_Database.pptx  # Project presentation (12 slides)
├── HOW_TO_USE.md                        # This instruction document
├── .env.example                         # Template for database passwords & ports
├── .gitignore                           # Ignores sensitive files (.env, node_modules)
└── database/                            # Oracle SQL & PL/SQL scripts
    ├── 01_create_tables.sql             # Tables, primary keys, foreign keys, 3NF schema
    ├── 02_constraints_indexes.sql       # Performance B-Tree indexes and uniqueness
    ├── 03_create_triggers.sql           # Harvest date check & price spike alert triggers
    ├── 04_create_procedures_functions.sql # Stored procedure, function, cursor demo
    ├── 05_create_views.sql              # Summary views & distributed node simulation
    ├── 06_sample_data.sql               # 8 farmers, 11 fields, 6 crops, 30 days of prices
    ├── 07_demo_queries.sql              # Presentation queries (Slide 11 Wheat query)
    ├── 08_test_cases.sql                # Automated 11-point test suite with PASS/FAIL report
    └── run_all.sql                      # Master runner script (runs 01 to 08 in 1 click)
```

---

## 3. How to Run the Database (3 Easy Ways)

You can run these scripts using any standard Oracle environment.

### Method A: Using Oracle SQL Developer (Recommended for Students)

1. Open **Oracle SQL Developer**.
2. Connect to your Oracle database (e.g., `localhost:1521/FREEPDB1` or `XEPDB1` or `XE`).
3. Click **File -> Open...** and open `database/run_all.sql`.
4. Click the **Run Script** button (the icon that looks like a sheet of paper with a green play arrow, or press **F5**).
5. Everything from Table Creation to Automated Test Cases will execute sequentially!

*Alternatively*, if you want to run files one by one:
1. `01_create_tables.sql` -> creates the tables
2. `02_constraints_indexes.sql` -> creates the indexes
3. `03_create_triggers.sql` -> compiles the triggers
4. `04_create_procedures_functions.sql` -> compiles procedures and functions
5. `05_create_views.sql` -> creates the views
6. `06_sample_data.sql` -> inserts farmers, crops, 30 days of prices
7. `07_demo_queries.sql` -> runs sample queries
8. `08_test_cases.sql` -> runs test suite

---

### Method B: Using SQL*Plus or Command Line Terminal

1. Open your terminal or command prompt.
2. Navigate to the project directory:
   ```bash
   cd "/Users/shiv/Downloads/ADBMS Project/database"
   ```
3. Connect to SQL*Plus:
   ```bash
   sqlplus username/password@localhost:1521/FREEPDB1
   ```
4. Run the master script:
   ```sql
   @run_all.sql
   ```

---

### Method C: Using Oracle APEX / Oracle Live SQL (Web Browser)

If you don't have Oracle installed locally on your laptop:
1. Open [Oracle Live SQL](https://livesql.oracle.com) or your college APEX workspace.
2. Copy and paste the contents of `01_create_tables.sql` into the SQL Worksheet and click **Run**.
3. Repeat for files `02` through `06`.
4. Run `07_demo_queries.sql` and `08_test_cases.sql` to view the outputs!

---

### Method D: Using pgAdmin 4 (PostgreSQL) — Instant 1-Click Setup

If you are using **PostgreSQL & pgAdmin 4**:
1. Open **pgAdmin 4** on your computer.
2. Expand your PostgreSQL server and open any database (e.g. `postgres` or create `farmer_market_db`).
3. Open the **Query Tool** (Click **Tools -> Query Tool** or press `Alt + Shift + Q`).
4. Click the **Open File** icon (folder icon on top toolbar) and select `pgadmin_complete_setup.sql`. *(Alternatively, copy all text from `pgadmin_complete_setup.sql` and paste it into the Query Tool).*
5. Click the **Execute** button (play triangle icon or press **F5**).
6. In 2 seconds, everything runs:
   - 12 Normalized tables & EER specialization created
   - All performance indexes built
   - PL/pgSQL triggers (`trg_validate_harvest`, `trg_price_alert`) compiled
   - PL/pgSQL procedures (`proc_best_market`, cursor demo) and revenue function compiled
   - 9 Analytical views created
   - 8 Farmers, 11 Fields, 6 Crops, and 30 days of dynamic prices seeded
   - Slide 11 Wheat query and automated test suite executed!
7. Check the **"Data Output"** tab to see the Slide 11 query and test results, and check the **"Messages"** tab to see PL/pgSQL notifications!

---

## 4. How to Verify That Everything Works

When you run `database/08_test_cases.sql`, the script runs 11 automated checks and displays a table:

| Test Name | Category | Status | What it Proved |
|---|---|---|---|
| **Valid Farmer & Field Insert** | DML Integrity | `PASS` | Normal records insert cleanly. |
| **Invalid Foreign Key** | Referential Integrity | `PASS` | Rejects fake farmer ID with `ORA-02291`. |
| **Trigger: trg_validate_harvest** | PL/SQL Trigger | `PASS` | Harvest before sowing date was blocked with error `-20001`. |
| **Negative Yield Rejection** | Domain Integrity | `PASS` | Negative yield was blocked with `ORA-02290`. |
| **Invalid Price Constraint** | Domain Integrity | `PASS` | `min_price > max_price` was blocked with `ORA-02290`. |
| **Trigger: trg_price_alert** | PL/SQL Trigger | `PASS` | Price swing > 20% automatically logged an alert row. |
| **Procedure: proc_best_market** | Explicit Cursor | `PASS` | Returned Lasalgaon / Nashik as top mandi with 30-day average price. |
| **Function: fn_expected_revenue** | PL/SQL Function | `PASS` | Calculated `(Yield * Modal Price)` and handled missing data safely. |
| **Virtual Column: total_amount** | Schema Design | `PASS` | Computed `(quantity * price)` automatically without manual calculation. |
| **Boundary: Missing Data Handling** | Exception Handling | `PASS` | Handled non-existent crop gracefully without crashing. |
| **RBAC Role Check Constraint** | Domain Integrity | `PASS` | Invalid user roles (e.g. `SUPER_ADMIN`) rejected by check constraint. |

---

## 5. PowerPoint Slide Mapping (Viva Guide)

When presenting to your professor, use this cheat sheet to connect the slides to your code:

| Slide # | Slide Topic | Where to find it in the Code |
|---|---|---|
| **Slide 6** | Core Relational Schema (`FARMER`, `FIELD`, `CROP`, `YIELD_RECORD`) | [database/01_create_tables.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/01_create_tables.sql) (Lines 24–140) |
| **Slide 6** | EER Specialization (`CEREAL_CROP`, `VEGETABLE_CROP`, `FRUIT_CROP`) | [database/01_create_tables.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/01_create_tables.sql) (Lines 60–100) |
| **Slide 7** | Market & Transactions (`PRICE_RECORD`, `SALE_TRANSACTION`, `PRICE_ALERT`) | [database/01_create_tables.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/01_create_tables.sql) (Lines 140–210) |
| **Slide 8** | Harvest Date Trigger (`trg_validate_harvest`) | [database/03_create_triggers.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/03_create_triggers.sql) (Lines 18–37) |
| **Slide 8** | Price Alert Trigger (`trg_price_alert`) | [database/03_create_triggers.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/03_create_triggers.sql) (Lines 40–150) |
| **Slide 9** | Best Market Cursor Stored Procedure (`proc_best_market`) | [database/04_create_procedures_functions.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/04_create_procedures_functions.sql) (Lines 24–75) |
| **Slide 9** | Expected Revenue Function (`fn_expected_revenue`) | [database/04_create_procedures_functions.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/04_create_procedures_functions.sql) (Lines 78–140) |
| **Slide 10** | Distributed Data & Horizontal Fragmentation | [database/05_create_views.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/05_create_views.sql) (Lines 140–210) |
| **Slide 11** | Sample Query: Top 3 Markets for Wheat (30 Days) | [database/07_demo_queries.sql](file:///Users/shiv/Downloads/ADBMS%20Project%20/database/07_demo_queries.sql) (Lines 20–35) |

---

## 6. Key Viva Concepts Explained in Plain English

Here are simple answers to common questions your examiner or teacher might ask:

### Q1: Why is this schema in Third Normal Form (3NF)?
> *"A table is in 3NF if it is in 2NF and has no transitive dependencies (i.e., non-key attributes depend only on the primary key, and nothing else). For example, in our `FARMER` table, we do not store daily market prices. In our `CROP` table, we do not store farmer phone numbers. Each table represents one single real-world concept."*

### Q2: What is EER Specialization and why did you use it?
> *"Different crops have different biological characteristics that cannot fit into one generic table without wasting space or storing NULLs. For instance: Cereals have maturity duration in days (`avg_duration_days`), Vegetables spoil quickly and need shelf-life (`perishability_days`), and Fruits grow on trees with multi-year harvest cycles (`harvest_cycle_years`). We implemented an Extended Entity-Relationship (EER) 1:1 specialization with `CROP` as the superclass and `CEREAL_CROP`, `VEGETABLE_CROP`, and `FRUIT_CROP` as subclasses."*

### Q3: Why did you use a Compound Trigger for `trg_price_alert` instead of a regular trigger?
> *"If you write a normal row-level `AFTER INSERT` trigger on `PRICE_RECORD` and try to query `SELECT AVG(modal_price) FROM PRICE_RECORD`, Oracle throws error `ORA-04091: table is mutating`. A mutating table error happens because the table is in the middle of being changed. A **Compound Trigger** solves this cleanly by buffering the inserted rows during `AFTER EACH ROW` and then calculating the average during `AFTER STATEMENT`, when the table lock is released and the table is safe to query."*

### Q4: What is an Explicit Cursor and why use it in `proc_best_market`?
> *"An implicit cursor is created automatically by Oracle for single-row queries (`SELECT INTO`). An **explicit cursor** is declared manually by the programmer for queries that return multiple rows. It gives complete row-by-row control through 4 steps: `DECLARE`, `OPEN`, `FETCH`, and `CLOSE`. In `proc_best_market`, we use an explicit cursor to iterate through ranked markets and extract the top-performing mandi."*

### Q5: What is Polyglot Persistence?
> *"Polyglot persistence means using different database technologies for different types of data based on their strengths:
> - **Oracle (RDBMS)**: Best for structured, relational data requiring ACID transactions (farmers, sales, money, prices, and referential integrity).
> - **MongoDB (NoSQL Document Store)**: Best for semi-structured, variable weather data (temperature, rainfall, humidity, wind speed) that arrives in high-frequency JSON documents."*

### Q6: How is Distributed Database Fragmentation demonstrated?
> *"In a distributed mandi setup, mandis in Nashik record prices in Nashik, and mandis in Pune record prices in Pune. We demonstrate **horizontal fragmentation** by partitioning `PRICE_RECORD` by district (`vw_mandi_frag_nashik`, `vw_mandi_frag_pune`, `vw_mandi_frag_ahmednagar`). The central query layer uses `UNION ALL` (`vw_mandi_consolidated_federation`) to reconstruct the full dataset, satisfying the ADBMS Reconstruction Completeness Rule."*

---

## 7. What Comes Next in the Upcoming Stages?

The project is structured in quota-saving stages:
- **Stage 1 (Current - Complete)**: Oracle tables, triggers, procedures, views, 30-day dynamic sample data, and automated test cases.
- **Stage 2**: MongoDB weather document collection and database connectivity modules.
- **Stage 3**: Node.js & Express REST API with authentication (Farmer, Market Officer, Admin roles).
- **Stage 4**: Clean, responsive frontend with dashboards, charts, price comparison tables, and sales recording.
- **Stage 5**: Full end-to-end testing, project documentation report, and comprehensive viva Q&A pack.
