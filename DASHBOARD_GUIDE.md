# Farmer Market Advisor — Multi-Role Web Dashboard Guide

> **Project Title:** Farmer-to-Market Crop Yield & Pricing Database  
> **Course:** Advanced Database Management Systems (ADBMS) Mini-Project  
> **Team:** Shivam Chaudhari (E213) • Bhavya Sharma (E223) • Akshat Jain (E257)  
> **Live Dashboard URL:** [http://localhost:5001](http://localhost:5001)

---

## 1. How to Run Both Backend and Frontend

The application supports two launch methods:

### Method A: All-in-One Single Server (Recommended)
The Node.js Express backend serves **both** the REST API and the compiled React production frontend on a single unified port:

```bash
# In the project root directory:
./start.sh
```
*Or manually:*
```bash
export PATH="/Users/shiv/.node/bin:$PATH"
cd backend
node server.js
```
👉 Open your browser at: **[http://localhost:5001](http://localhost:5001)**

---

### Method B: Separate Development Servers
If you want hot-reloading for code modifications:

1. **Terminal 1 (Backend API):**
   ```bash
   export PATH="/Users/shiv/.node/bin:$PATH"
   cd backend
   node server.js
   ```
   *(Backend starts on port 5001)*

2. **Terminal 2 (Frontend React Vite):**
   ```bash
   export PATH="/Users/shiv/.node/bin:$PATH"
   cd frontend
   npm run dev
   ```
   *(Vite starts on port 3000 and automatically proxies `/api` calls to port 5001)*

👉 Open your browser at: **[http://localhost:3000](http://localhost:3000)**

---

## 2. Demo User Credentials

All sample accounts use the same standard password:

| Persona | Role | Username | Password | Authorized Mandi |
|---|---|---|---|---|
| **Farmer (Ramesh)** | `FARMER` | `farmer_ramesh` | `Password@123` | Public Mandi Access |
| **Seller: Lasalgaon** | `OFFICER` | `officer_lasalgaon` | `Password@123` | Lasalgaon APMC only |
| **Seller: Pune** | `OFFICER` | `officer_pune` | `Password@123` | Pune Mandi (Gultekdi) only |
| **Admin** | `ADMIN` | `admin` | `Password@123` | All Mandis |

> [!TIP]
> **One-Click Persona Switcher:** The top bar includes convenient one-click buttons (`🧑‍🌾 Farmer`, `🏢 Seller: Lasalgaon APMC`, `🏢 Seller: Pune Mandi`, `👑 Admin`) so you can instantly switch roles during a live college viva demonstration without having to manually type passwords each time!

---

## 3. How to Use the Interface as a Seller / Market Officer

### Step 1: Switch to Seller Mode
1. Open [http://localhost:5001](http://localhost:5001).
2. Click **🏢 Seller: Lasalgaon APMC** on the top role bar (or click "Login" and sign in with `officer_lasalgaon` / `Password@123`).
3. Notice the top banner updates to show:
   - **Active Role:** Vijay Kulkarni (Lasalgaon Officer)
   - **Authorized Mandis:** Lasalgaon APMC (Nashik)

---

### Step 2: Publish a Daily Crop Price
1. Click the **"Publish Daily Price"** tab.
2. Fill in the daily market report:
   - **Assigned Mandi:** Notice the dropdown is locked strictly to *Lasalgaon APMC* (enforced by the database and backend).
   - **Crop Produce:** Select **Wheat** (or Onion / Tomato).
   - **Price Date:** Pick today's date.
   - **Minimum Price (₹/qtl):** e.g., `2500`
   - **Modal Benchmark Price (₹/qtl):** e.g., `2750`
   - **Maximum Price (₹/qtl):** e.g., `2900`
   - **Arrival Volume (qtl):** e.g., `120`
   - **Market Remarks:** e.g., *"Strong festival buying from flour mills"*
3. Click **"Publish & Save Price Record"**.

### What Happens in the Database During Submission:
1. **Security Check:** Backend verifies that `officer_lasalgaon` is authorized for Lasalgaon APMC (`SELLER_MARKET_ASSIGNMENT`). If an officer attempts to submit for an unassigned mandi, the database/backend rejects it with HTTP 403 Forbidden.
2. **Database Transaction:** A transaction (`BEGIN`) starts in PostgreSQL.
3. **Session Audit Context:** PostgreSQL executes `SELECT set_config('app.user_name', 'officer_lasalgaon', true)`.
4. **Range Constraints:** `chk_price_order` (`min <= max`) and `chk_modal_range` (`min <= modal <= max`) are verified.
5. **Upsert:** `PRICE_RECORD` is inserted or updated without duplicate conflicts on `(market_id, crop_id, price_date)`.
6. **Audit Trigger (`trg_price_audit`):** Automatically writes a row to `PRICE_AUDIT` capturing action `INSERT`/`UPDATE`, the previous modal price, new modal price, timestamp, and user `officer_lasalgaon`.
7. **Price Alert Trigger (`trg_price_alert`):** If the new modal price deviates by >20% from the 7-day prior average, an automatic alert is logged in `PRICE_ALERT`.
8. **Commit:** The transaction commits (`COMMIT`), and a green confirmation appears on screen.

---

### Step 3: View the Audit Trail
1. Click the **"Price Audit Trail"** tab on the seller dashboard.
2. Observe the historical record showing:
   - Action: `INSERT` or `UPDATE`
   - Mandi: Lasalgaon APMC
   - Crop: Wheat
   - Old Modal Price vs. New Modal Price
   - Changed By: `officer_lasalgaon`
   - Exact timestamp

---

### Step 4: Verify the Farmer's Live Recalculation
1. Click the green button: **"Switch to Farmer View & Verify Price"** (or click `🧑‍🌾 Farmer (Ramesh)` on the top bar).
2. On the Farmer Dashboard:
   - Select **Wheat** and enter **50 quintals**.
   - Click **"Find Best Market"**.
3. **Behold the Result:**
   - *Lasalgaon APMC* immediately shows the newly published price of **₹2,750/qtl**!
   - Estimated gross revenue recalculates instantly to **₹1,37,500**!
   - The revenue gain chip shows the farmer earning **+₹28,000 extra revenue** over Pune Mandi!

---

## 4. Live College Viva Demonstration Checklist

When presenting to your professor, follow these 4 steps:

1. **Explain the Architecture (1 minute):**
   > *"Our ADBMS project solves price information asymmetry for Indian farmers by connecting daily APMC mandi officers and farmers through a shared PostgreSQL database."*
2. **Show Role-Based Security (1 minute):**
   > *"Market officers have localized jurisdiction. The officer at Lasalgaon cannot alter prices for Pune Mandi. Backend authorization and database constraints reject unauthorized entries."*
3. **Publish a High Price as Seller (1.5 minutes):**
   > *"We log in as `officer_lasalgaon`, submit a new daily modal price of ₹2,750 for Wheat, and show that our PL/pgSQL trigger `trg_price_audit` captures the mutation with session user context."*
4. **Show Real-Time Farmer Decision Support (1.5 minutes):**
   > *"We switch to Farmer mode. The farmer enters 50 quintals of wheat. The system recalculates the best mandi, highlighting Lasalgaon APMC with an estimated gross revenue of ₹1,37,500 and a ₹28,000 gain over the lowest mandi."*
