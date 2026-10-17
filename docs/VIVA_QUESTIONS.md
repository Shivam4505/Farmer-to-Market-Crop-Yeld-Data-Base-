# ADBMS Mini Project — Viva Voce Questions & Answers
## Farmer-to-Market Crop Yield & Pricing Database

This guide contains **25 essential viva questions** with simple, clear answers tailored specifically to your project code and architecture.

---

### Core ADBMS & Normalization

#### Q1: What is the primary objective of this project?
**Answer:** To connect disconnected agricultural data (farmers, fields, seasonal crop yields, daily mandi prices, and weather logs) into an Advanced DBMS. It empowers farmers to discover the highest-paying markets, estimates their crop revenues, and alerts officials to abnormal price volatility (> 20%).

#### Q2: What makes this an "Advanced" DBMS project rather than a basic DBMS project?
**Answer:** 
1. **Extended Entity-Relationship (EER) Specialization**: 1:1 disjoint subclasses (`CEREAL_CROP`, `VEGETABLE_CROP`, `FRUIT_CROP`).
2. **Compound Database Triggers**: Overcoming Oracle's mutating-table problem (`ORA-04091`).
3. **Explicit Cursor Management**: Custom iteration and ranking in PL/SQL stored procedures.
4. **Analytic Window Functions**: Using `DENSE_RANK() OVER (PARTITION BY ...)` for multi-market ranking.
5. **Polyglot Persistence**: Combining relational Oracle transactions with MongoDB semi-structured JSON weather documents.
6. **Distributed Database Concepts**: Simulating horizontal data fragmentation and reconstruction completeness via federated views.

#### Q3: Why is your database schema normalized up to 3NF?
**Answer:** Third Normal Form eliminates insertion, deletion, and update anomalies:
- **1NF**: Every field holds atomic, indivisible values; no repeating price or yield columns inside the farmer table.
- **2NF**: No partial dependencies; all non-key columns depend on the entire primary key.
- **3NF**: No transitive dependencies ($X \rightarrow Y$ and $Y \rightarrow Z$). Market district details reside exclusively in `MARKET`, rather than duplicating district names in every `PRICE_RECORD` row.

#### Q4: Why did you implement EER Specialization for Crops?
**Answer:** Different agricultural crops have specialized biological attributes. Cereals need maturity duration (`avg_duration_days`), Vegetables need perishability days (`perishability_days`), and Fruits have multi-year harvest cycles (`harvest_cycle_years`). Storing them in separate 1:1 subclass tables linked by `crop_id` eliminates redundant `NULL` values and enforces domain-specific integrity constraints.

#### Q5: What is the purpose of the virtual column in `SALE_TRANSACTION`?
**Answer:** `total_amount` is defined as `GENERATED ALWAYS AS (ROUND(quantity_qtl * price_per_qtl, 2)) VIRTUAL`. It computes the total sale value on-the-fly, ensuring 100% mathematical accuracy, eliminating disk storage redundancy, and removing the need for an update trigger.

---

### PL/SQL Triggers, Procedures & Functions

#### Q6: Explain what `trg_validate_harvest` does.
**Answer:** It is a row-level `BEFORE INSERT OR UPDATE` trigger on `YIELD_RECORD`. It ensures that `harvest_date > sowing_date`. If someone tries to insert a harvest date on or before the sowing date, it intercepts the operation and raises Oracle application error `-20001` with a readable error message.

#### Q7: What is an Oracle mutating table error (`ORA-04091`)?
**Answer:** A mutating table error occurs when a row-level trigger on a table attempts to read (`SELECT`) or modify that same table while the statement is still in flight. Because the table is in an inconsistent state, Oracle blocks the query with error `ORA-04091`.

#### Q8: How did you solve the mutating table error in `trg_price_alert`?
**Answer:** By using an **Oracle Compound Trigger** (`COMPOUND TRIGGER`). It splits execution into timing points:
1. `AFTER EACH ROW`: Buffers newly inserted rows into an in-memory PL/SQL collection.
2. `AFTER STATEMENT`: Once the table lock is released, it safely queries `PRICE_RECORD` for the 7-day prior average without distortion (`price_date < inserted_price_date`). If deviation $> 20\%$, it inserts into `PRICE_ALERT`.

#### Q9: What is the difference between an Implicit Cursor and an Explicit Cursor?
**Answer:** 
- **Implicit Cursor**: Created automatically by Oracle for single-row queries (`SELECT INTO`) or DML (`INSERT`, `UPDATE`, `DELETE`).
- **Explicit Cursor**: Explicitly declared and controlled by the programmer for queries returning multiple rows. It uses 4 distinct lifecycle steps: `DECLARE`, `OPEN`, `FETCH`, and `CLOSE`.

#### Q10: How does `proc_best_market` use an explicit cursor?
**Answer:** It declares cursor `c_prices` to query markets and compute 30-day average modal prices descending for a specified crop. It opens the cursor, fetches the top-ranked market, checks `%FOUND`, assigns `OUT` parameters, and closes the cursor safely in both normal execution and exception handlers.

#### Q11: What does `fn_expected_revenue` compute?
**Answer:** It computes a farmer's projected revenue: $(\text{Most Recent Harvested Yield in qtl}) \times (\text{Recent Modal Price in Rs/qtl})$. It handles missing records with `EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 0;`.

#### Q12: Why is `fn_expected_revenue` a Function and `proc_best_market` a Procedure?
**Answer:** A stored function returns a single value via the `RETURN` keyword and can be directly embedded inside standard SQL `SELECT` queries (e.g., `SELECT farmer_id, fn_expected_revenue(farmer_id, crop_id) FROM ...`). A procedure is used when returning multiple values via `OUT` parameters or executing administrative transactions.

---

### Polyglot Persistence & Distributed Database Concepts

#### Q13: What is Polyglot Persistence?
**Answer:** Using different database engines for different data needs within the same application:
- **Oracle (Relational)**: Structured data needing ACID transactions, referential integrity, and complex joins (sales, farmers, crops, prices).
- **MongoDB (NoSQL Document Store)**: Semi-structured JSON documents for high-frequency weather observations where sensor attributes vary.

#### Q14: How does MongoDB store weather data in this project?
**Answer:** In a collection named `weather_logs`. Each document contains:
```json
{
  "district": "Nashik",
  "log_date": "2026-09-10",
  "temperature_c": 29.4,
  "rainfall_mm": 12.5,
  "humidity_pct": 68
}
```
Indexes on `district` and `log_date` enable fast range lookups.

#### Q15: How does the application merge Oracle and MongoDB data?
**Answer:** In the federated middleware layer (Node.js/Express service). When a user requests a "Weather vs. Crop Yield Report", the API queries Oracle for crop yields in a district, queries MongoDB for rainfall/temperature over that cultivation window, and merges the two datasets into one combined JSON response.

#### Q16: What is Horizontal Fragmentation in Distributed DBMS?
**Answer:** Dividing a table into horizontal subsets of rows based on a condition (predicate). In our system, `PRICE_RECORD` is fragmented by district:
- Nashik fragment: `WHERE district = 'Nashik'`
- Pune fragment: `WHERE district = 'Pune'`
- Ahmednagar fragment: `WHERE district = 'Ahmednagar'`

#### Q17: What is the Reconstruction Completeness Rule in Distributed DBMS?
**Answer:** A global relation must be completely reconstructible from its fragments without loss of data. We demonstrate this via `vw_mandi_consolidated_federation`, which performs a `UNION ALL` across all district fragments.

---

### Performance, Security & Testing

#### Q18: Why did you create indexes on foreign keys in Oracle?
**Answer:** In Oracle, unindexed foreign keys cause table-level share locks on child tables whenever a parent table row is updated or deleted. Indexing foreign keys prevents locking bottlenecks and drastically accelerates table joins.

#### Q19: What is the composite index `idx_price_crop_date_modal` used for?
**Answer:** It is a covering index on `PRICE_RECORD(crop_id, price_date, modal_price)`. It allows the database to evaluate 7-day rolling averages and 30-day top market rankings directly from the index structure without reading table data blocks from disk.

#### Q20: How is Role-Based Access Control (RBAC) enforced?
**Answer:** The `APP_USER` table defines user roles (`ADMIN`, `OFFICER`, `FARMER`) protected by a `CHECK` constraint. In the backend, JWT tokens verify user roles:
- **Farmer**: Can only access their own profile, fields, and yields.
- **Market Officer**: Can only publish daily prices for their assigned market.
- **Admin**: Can view master reports and manage all records.

#### Q21: How are passwords stored securely?
**Answer:** Passwords are never stored in plain text. They are hashed using cryptographic one-way hashing (SHA-256 / bcrypt) with salts, preventing password exposure even if database tables are dumped.

#### Q22: What tests were conducted in `08_test_cases.sql`?
**Answer:** 11 automated test cases verifying:
1. Valid insertions
2. Foreign key rejections (`ORA-02291`)
3. Harvest date trigger rejections (`-20001`)
4. Negative yield constraint rejections (`ORA-02290`)
5. Price ordering constraint rejections (`min > max`)
6. Price alert trigger generation (> 20% deviation)
7. `proc_best_market` explicit cursor execution
8. `fn_expected_revenue` calculation & fallback
9. Virtual column calculation accuracy
10. Missing-data handling
11. Invalid user role constraint rejection

---

### Practical Viva Demonstration

#### Q23: How do you show Slide 11 query in Oracle?
**Answer:** In `07_demo_queries.sql`, we run:
```sql
SELECT m.market_name, ROUND(AVG(p.modal_price), 2) AS avg_price
FROM PRICE_RECORD p
JOIN MARKET m ON m.market_id = p.market_id
JOIN CROP c ON c.crop_id = p.crop_id
WHERE c.crop_name = 'Wheat' AND p.price_date >= (TRUNC(SYSDATE) - 30)
GROUP BY m.market_name
ORDER BY avg_price DESC
FETCH FIRST 3 ROWS ONLY;
```
It returns Lasalgaon APMC, Nashik APMC, and Ahmednagar APMC with their 30-day average prices.

#### Q24: What is the `DENSE_RANK()` analytic function in `vw_top_three_markets`?
**Answer:** `DENSE_RANK() OVER (PARTITION BY crop_id ORDER BY AVG(modal_price) DESC)` assigns contiguous ranks (1, 2, 3...) to mandis grouped by crop based on their average price, allowing the top 3 mandis for *every* crop to be retrieved in a single query.

#### Q25: If an examiner asks you to add a new price row and show the alert, what do you do?
**Answer:** Insert a price with a modal price 25% higher than the 7-day average:
```sql
INSERT INTO PRICE_RECORD (market_id, crop_id, price_date, min_price, max_price, modal_price)
VALUES (3, 3, TRUNC(SYSDATE), 1950, 2300, 2150);
```
Then query `SELECT * FROM PRICE_ALERT WHERE alert_date = TRUNC(SYSDATE);`. The record appears immediately, proving the compound trigger works live.
