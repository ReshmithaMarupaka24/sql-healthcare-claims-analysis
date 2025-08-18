-- Portfolio queries

-- 1) Monthly finance trend
SELECT * FROM hi.v_claims_month ORDER BY month;

-- 2) PMPM allowed amount
WITH mbr AS (
  SELECT date_trunc('month', gs)::date AS month, COUNT(DISTINCT member_id) AS members
  FROM hi.members m
  CROSS JOIN generate_series(m.enrollment_start, m.enrollment_end, interval '1 month') gs
  GROUP BY 1
),
fin AS (
  SELECT date_trunc('month', service_start_date)::date AS month, SUM(allowed_amount) AS allowed
  FROM hi.claims GROUP BY 1
)
SELECT f.month, ROUND((f.allowed / NULLIF(m.members,0))::numeric,2) AS pmpm_allowed
FROM fin f
LEFT JOIN mbr m USING (month)
ORDER BY f.month;

-- 3) Denial rate by reason
SELECT denial_code, COUNT(*) AS claims
FROM hi.claims
WHERE status='denied'
GROUP BY denial_code
ORDER BY claims DESC;

-- 4) Top 10 diagnoses by allowed spend
SELECT d.dx_code, d.description, SUM(c.allowed_amount) AS allowed
FROM hi.claims c
JOIN hi.claim_dx x ON x.claim_id=c.claim_id AND x.dx_rank=1
JOIN hi.dx_codes d ON d.dx_code=x.dx_code
GROUP BY 1,2
ORDER BY allowed DESC
LIMIT 10;

-- 5) 30-day readmission rate
SELECT SUM(readmit_30d) AS readmits_30d,
       COUNT(*) AS discharges,
       ROUND((100.0 * SUM(readmit_30d) / NULLIF(COUNT(*),0))::numeric, 2) AS readmit_rate_pct
FROM hi.v_inpatient_readmissions;

-- 6) Provider performance (top 20 by denial rate)
REFRESH MATERIALIZED VIEW CONCURRENTLY hi.mv_provider_perf;
SELECT p.provider_name, p.specialty, m.*
FROM hi.mv_provider_perf m
JOIN hi.providers p USING (provider_id)
ORDER BY deny_rate_pct DESC
LIMIT 20;

-- 7) Member OOP by plan tier
SELECT pl.metal_tier,
       ROUND(AVG(member_deductible + member_copay + member_coinsurance)::numeric, 2) AS avg_member_oop_per_claim
FROM hi.claims c
JOIN hi.plans pl ON pl.plan_id=c.plan_id
GROUP BY pl.metal_tier
ORDER BY 1;

-- 8) High-cost members (top 1% by allowed)
WITH spend AS (
  SELECT member_id, SUM(allowed_amount) AS allowed
  FROM hi.claims GROUP BY member_id
),
cut AS (
  SELECT percentile_cont(0.99) WITHIN GROUP (ORDER BY allowed) AS p99 FROM spend
)
SELECT s.member_id, s.allowed
FROM spend s, cut
WHERE s.allowed >= cut.p99
ORDER BY s.allowed DESC;
