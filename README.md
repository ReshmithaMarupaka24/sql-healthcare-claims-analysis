# Healthcare Insurance Claim Analysis in PostgreSQL

This project demonstrates a **SQL-only portfolio project** using PostgreSQL focused on healthcare insurance claim data.  
It includes a schema, seed data, constraints, indexes, and analysis queries that answer real business questions.

---

## Features

- **Schema** for members, plans, providers, claims, diagnoses, and procedures  
- **Constraints** enforce realistic data rules (dates, costs, foreign keys)  
- **Seed scripts** generate thousands of members and claims with randomized yet controlled values  
- **Views & Materialized Views** for finance trends, provider performance, and readmission rates  
- **Analysis queries** show monthly cost trends, PMPM, denial reasons, and top diagnoses  

---


## Project Structure  

- `sql/01_schema.sql` → schema definitions (tables, constraints, relationships)  
- `sql/02_seed.sql` → seed data for members, plans, providers, dx/px codes  
- `sql/03_claims_insert.sql` → synthetic claim generation logic  
- `sql/04_indexes.sql` → indexes for performance  
- `sql/05_views.sql` → useful reporting views & materialized views  
- `sql/06_sanity.sql` → sanity checks and validation queries  
- `sql/07_analysis.sql` → portfolio-ready business analysis queries  

---

## Setup Instructions

## 🏁 Quickstart (psql)

```bash
# 0) create the database (if not already created)
createdb healthcare

# 1) run the schema
psql -U youruser -d healthcare -f 01_schema.sql

# 2) load the seed data
psql -U youruser -d healthcare -f 02_seed.sql

# 3) insert claims
psql -U youruser -d healthcare -f 03_claims_insert.sql

# 4) apply indexes & views
psql -U youruser -d healthcare -f 04_indexes.sql
psql -U youruser -d healthcare -f 05_views.sql

# 5) run sanity checks
psql -U youruser -d healthcare -f 06_sanity.sql

# 6) run analysis queries
psql -U youruser -d healthcare -f 07_analysis.sql


---

---

## Results
Here are some example insights generated from the analysis queries:

### 1. Monthly Cost Trend
- Average billed amount per claim increased by **12.4%** from Jan → Dec.  
- Highest cost month: **October ($2.4M total billed)**  
- Lowest cost month: **February ($1.7M total billed)**  

---

### 2. Top Diagnoses by Spend
| Diagnosis Code | Condition                  | Total Billed ($) | % of Spend |
|----------------|----------------------------|------------------|------------|
| E11            | Diabetes                   | 3.2M             | 18.6%      |
| I10            | Hypertension               | 2.7M             | 15.4%      |
| N18            | Chronic Kidney Disease     | 1.4M             | 8.1%       |

---

### 3. Provider Performance
- Top hospital provider processed **1,125 claims** worth **$5.7M**.  
- Denial rates ranged from **3.2% (best)** to **14.8% (worst)**.  

---

### 4. Readmission Rates
- Overall 30-day readmission rate: **7.9%**  
- Highest in **cardiac-related diagnoses (12.5%)**  

---

### 5. PMPM (Per Member Per Month)
| Plan Type   | PMPM ($) |
|-------------|----------|
| Overall     | 412.35   |
| Commercial  | 368.10   |
| Medicare    | 517.42   |

---
