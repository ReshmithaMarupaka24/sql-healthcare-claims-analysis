-- Views and materialized view
-- Month-grain financials
CREATE OR REPLACE VIEW hi.v_claims_month AS
SELECT date_trunc('month', service_start_date)::date AS month,
       plan_id, claim_type,
       COUNT(*) AS claims,
       SUM(billed_amount) AS billed,
       SUM(allowed_amount) AS allowed,
       SUM(COALESCE(paid_amount,0)) AS paid,
       SUM(member_deductible + member_copay + member_coinsurance) AS member_oop
FROM hi.claims
GROUP BY 1,2,3;

-- Inpatient readmissions within 30 days
CREATE OR REPLACE VIEW hi.v_inpatient_readmissions AS
WITH ip AS (
  SELECT member_id, claim_id, admit_date, discharge_date
  FROM hi.claims
  WHERE claim_type='inpatient' AND discharge_date IS NOT NULL
),
seq AS (
  SELECT member_id, claim_id, admit_date, discharge_date,
         LEAD(admit_date) OVER (PARTITION BY member_id ORDER BY admit_date) AS next_admit
  FROM ip
)
SELECT *,
       CASE WHEN next_admit IS NOT NULL AND next_admit <= discharge_date + INTERVAL '30 days' THEN 1 ELSE 0 END AS readmit_30d
FROM seq;

-- Provider performance rollup
DROP MATERIALIZED VIEW IF EXISTS hi.mv_provider_perf;
CREATE MATERIALIZED VIEW hi.mv_provider_perf AS
SELECT provider_id,
       COUNT(*) AS claims,
       SUM(allowed_amount) AS allowed,
       SUM(COALESCE(paid_amount,0)) AS paid,
       AVG(allowed_amount) AS avg_allowed,
       100.0 * SUM(CASE WHEN status='denied' THEN 1 ELSE 0 END)::numeric / NULLIF(COUNT(*),0) AS deny_rate_pct
FROM hi.claims
GROUP BY provider_id;

-- Unique index needed for CONCURRENT refresh
CREATE UNIQUE INDEX IF NOT EXISTS mv_provider_perf_uidx ON hi.mv_provider_perf(provider_id);

-- Helper function to refresh concurrently
CREATE OR REPLACE FUNCTION hi.refresh_provider_perf()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY hi.mv_provider_perf;
END $$;

-- Optional initial refresh (non-concurrent is fine if locks are okay)
-- REFRESH MATERIALIZED VIEW hi.mv_provider_perf;
