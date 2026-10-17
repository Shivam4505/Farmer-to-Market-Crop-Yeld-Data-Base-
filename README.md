# Farmer-to-Market Crop Yield & Pricing Database

> **Advanced Database Management Systems (ADBMS) Project**  
> **Team:** Shivam Chaudhari (E213) • Bhavya Sharma (E223) • Akshat Jain (E257)  
> **Live Application:** [http://localhost:5001](http://localhost:5001)

---

## 🌾 Project Overview

In India, farmers frequently sell their produce based on word-of-mouth without timely visibility into modal prices across regional APMC Mandis. Simultaneously, crop cultivation cycles, soil health indicators, and weather variations remain siloed across fragmented records.

This project delivers an enterprise-grade **Farmer-to-Market Crop Yield & Pricing Database** engineered with:
1. **Normalized Relational Architecture (3NF)**: Structured data storage across farmers, fields, crops, harvests, markets, transactions, and price records.
2. **PostgreSQL & Oracle Support**: Complete SQL DDL, integrity constraints, composite & functional indexes, PL/pgSQL & PL/SQL procedures, and triggers.
3. **Automated Price Alerts**: Trigger-based spike alerts (>20% price fluctuations) and automated audit logging.
4. **Polyglot Persistence**: Relational storage for transactions and market telemetry combined with NoSQL (MongoDB / JSONB) schema for flexible weather telemetry.
5. **Modern Web Dashboard**: Multi-role React (Vite) interface powered by a Node.js Express REST API providing real-time APMC price tracking, best mandi recommendations, revenue calculators, and transaction management.

---

## 🚀 Quick Start

### 1. Prerequisites
- **Node.js** (v18+)
- **PostgreSQL** (v14+) running on `localhost:5432` with database `farmer_market_db`

### 2. Database Setup (PostgreSQL)
Run the automated complete setup script in PostgreSQL / pgAdmin:
```bash
# Using psql:
psql -U postgres -d farmer_market_db -f pgadmin_complete_setup.sql
```
*(Or execute the scripts sequentially inside `/database_postgres`)*

### 3. Run the Unified Application
Run the one-click startup script from the project root:
```bash
./start.sh
```
The application will be live at:
👉 **[http://localhost:5001](http://localhost:5001)**

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology | Description |
|---|---|---|
| **Frontend** | React 18, Vite, Lucide Icons, Vanilla CSS | Interactive role-based dashboard (Farmer, Mandi Official, Analyst) |
| **Backend API** | Node.js, Express, `pg` (node-postgres) | RESTful API endpoints for analytics, recommendations, and CRUD |
| **Relational DB** | PostgreSQL 16 & Oracle Database | 3NF relational schema, B-Tree indexes, stored procedures, triggers |
| **NoSQL Telemetry** | MongoDB / Postgres JSONB | Polyglot unstructured weather and IoT sensor readings |

---

## 📁 Repository Structure

```text
├── README.md                      # Project documentation and setup guide
├── DASHBOARD_GUIDE.md             # In-depth guide to dashboard features & workflows
├── HOW_TO_USE.md                  # Step-by-step walkthrough for evaluation & viva
├── start.sh                       # One-click startup script (starts DB checks + server)
├── pgadmin_complete_setup.sql     # Complete all-in-one PostgreSQL setup script
├── .gitignore                     # Git ignore rules for node_modules, .env, OS files
│
├── backend/                       # Node.js + Express REST API
│   ├── server.js                  # API routes, business logic, static frontend serving
│   ├── db.js                      # PostgreSQL connection pool configuration
│   └── package.json               # Backend dependencies
│
├── frontend/                      # React + Vite Multi-Role Web Dashboard
│   ├── src/                       # App.jsx, index.css, modern UI components
│   ├── dist/                      # Pre-built production frontend bundle
│   └── package.json               # Frontend dependencies & build scripts
│
├── database_postgres/             # Modular PostgreSQL DDL & PL/pgSQL Scripts
│   ├── 01_create_tables.sql       # Tables, primary keys, foreign keys, cascade rules
│   ├── 02_constraints_indexes.sql # Performance B-Tree indexes & uniqueness constraints
│   ├── 03_create_triggers.sql     # Price spike alert & audit triggers
│   ├── 04_create_procedures_functions.sql # Best market recommendation & revenue functions
│   ├── 05_create_views.sql        # High-performance analytics & summary views
│   ├── 06_sample_data.sql         # Seed data (farmers, mandis, crops, 30 days of prices)
│   ├── 07_demo_queries.sql        # Showcase analytics & viva queries
│   └── 08_test_cases.sql          # Automated test suite with PASS/FAIL verification
│
├── database/                      # Oracle SQL & PL/SQL equivalents
├── docs/                          # Comprehensive reports, documentation, and viva prep
│   ├── PROJECT_DOCUMENTATION.md   # Complete technical specifications & ER diagrams
│   ├── VIVA_QUESTIONS.md          # 40+ curated viva questions & detailed answers
│   └── Farmer_to_Market_ADBMS_Project_Report.docx # Formatted project report
└── PPTs/                          # Final presentation slide decks (.pptx)
```

---

## 📊 Core Features & Advanced DBMS Concepts

- **3NF Relational Integrity:** Enforces entity, referential, and domain constraints across 9 tables.
- **Dynamic Market Price Intelligence:** Real-time query to identify the highest-paying APMC market for any crop and district (`/api/best-market`).
- **Automated Price Spike Trigger (`trg_price_alert`):** Detects price deviations $>20\%$ against recent modal history and flags alert records for review.
- **Audit Logging Trigger (`trg_price_audit`):** Maintains full temporal change histories (INSERT, UPDATE, DELETE) with timestamps.
- **Stored Functions & Analytics Views:** Window functions (`ROW_NUMBER()`, `RANK()`), partition aggregations, and performance-tuned views (`vw_latest_prices`, `vw_market_daily_summary`).
- **Comprehensive Test Suite:** 11-point automated verification script covering referential integrity, check constraints, trigger execution, and procedural accuracy.

---

## 👨‍💻 Team & Credits

- **Shivam Chaudhari** (E213)
- **Bhavya Sharma** (E223)
- **Akshat Jain** (E257)

*Department of Computer Engineering — Advanced Database Management Systems Project*
