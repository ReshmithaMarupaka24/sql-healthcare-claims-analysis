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

1. **Create the database**
```sql
CREATE DATABASE healthcare;
