-- Schema + tables + constraints
CREATE SCHEMA IF NOT EXISTS hi;

CREATE TABLE IF NOT EXISTS hi.plans (
  plan_id SERIAL PRIMARY KEY,
  plan_name TEXT NOT NULL,
  metal_tier TEXT CHECK (metal_tier IN ('Bronze','Silver','Gold','Platinum')),
  deductible NUMERIC(10,2) NOT NULL CHECK (deductible >= 0),
  oop_max NUMERIC(10,2) NOT NULL CHECK (oop_max >= 0)
);

CREATE TABLE IF NOT EXISTS hi.members (
  member_id SERIAL PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  dob DATE NOT NULL,
  gender CHAR(1) CHECK (gender IN ('F','M','O')),
  zip3 CHAR(3),
  plan_id INT NOT NULL REFERENCES hi.plans(plan_id),
  enrollment_start DATE NOT NULL,
  enrollment_end DATE NOT NULL,
  CHECK (enrollment_start <= enrollment_end)
);

CREATE TABLE IF NOT EXISTS hi.providers (
  provider_id SERIAL PRIMARY KEY,
  npi CHAR(10) UNIQUE,
  provider_name TEXT NOT NULL,
  specialty TEXT NOT NULL,
  state CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS hi.dx_codes (
  dx_code TEXT PRIMARY KEY,
  description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS hi.px_codes (
  px_code TEXT PRIMARY KEY,
  description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS hi.claims (
  claim_id BIGSERIAL PRIMARY KEY,
  member_id INT NOT NULL REFERENCES hi.members(member_id),
  provider_id INT NOT NULL REFERENCES hi.providers(provider_id),
  plan_id INT NOT NULL REFERENCES hi.plans(plan_id),
  claim_type TEXT NOT NULL CHECK (claim_type IN ('inpatient','outpatient','professional','pharmacy')),
  place_of_service TEXT,
  admit_date DATE,
  discharge_date DATE,
  service_start_date DATE NOT NULL,
  service_end_date DATE NOT NULL,
  billed_amount NUMERIC(12,2) NOT NULL CHECK (billed_amount >= 0),
  allowed_amount NUMERIC(12,2) NOT NULL CHECK (allowed_amount >= 0),
  paid_amount NUMERIC(12,2) CHECK (paid_amount >= 0),
  member_deductible NUMERIC(12,2) DEFAULT 0 CHECK (member_deductible >= 0),
  member_copay NUMERIC(12,2) DEFAULT 0 CHECK (member_copay >= 0),
  member_coinsurance NUMERIC(12,2) DEFAULT 0 CHECK (member_coinsurance >= 0),
  denial_code TEXT,
  status TEXT NOT NULL CHECK (status IN ('submitted','adjudicated','denied','adjusted')),
  paid_date DATE,
  CHECK (service_start_date <= service_end_date),
  CHECK (paid_date IS NULL OR paid_date >= service_end_date),
  CHECK (
    claim_type <> 'inpatient'
    OR (admit_date IS NOT NULL AND discharge_date IS NOT NULL AND admit_date <= discharge_date)
  ),
  CHECK (allowed_amount <= billed_amount),
  CHECK (paid_amount IS NULL OR paid_amount <= allowed_amount),
  CHECK (
    paid_amount IS NULL OR 
    abs(allowed_amount - paid_amount - member_deductible - member_copay - member_coinsurance) <= 0.01
  )
);

CREATE TABLE IF NOT EXISTS hi.claim_dx (
  claim_id BIGINT REFERENCES hi.claims(claim_id) ON DELETE CASCADE,
  dx_code TEXT REFERENCES hi.dx_codes(dx_code),
  dx_rank SMALLINT NOT NULL CHECK (dx_rank >= 1),
  PRIMARY KEY (claim_id, dx_rank)
);

CREATE TABLE IF NOT EXISTS hi.claim_px (
  claim_id BIGINT REFERENCES hi.claims(claim_id) ON DELETE CASCADE,
  px_code TEXT REFERENCES hi.px_codes(px_code),
  PRIMARY KEY (claim_id, px_code)
);
