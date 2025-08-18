-- Generate and insert synthetic claims with balanced cost shares
BEGIN;

WITH base AS (
  SELECT
    m.member_id,
    m.plan_id,
    (SELECT provider_id FROM hi.providers ORDER BY random() LIMIT 1) AS provider_id,
    (ARRAY['inpatient','outpatient','professional','pharmacy'])[1+floor(random()*4)] AS claim_type,
    (date '2024-01-01' + (random()*560)::int) AS svc_start
  FROM hi.members m
),
expanded AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start,
    (svc_start + CASE WHEN claim_type='inpatient' THEN (1+floor(random()*7))::int ELSE (floor(random()*2))::int END) AS svc_end,
    round((50 + random()*20000)::numeric, 2) AS billed
  FROM base
  WHERE random() < 0.4
),
calc AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start, svc_end, billed,
    round((billed * (0.4 + random()*0.4))::numeric, 2) AS allowed_raw
  FROM expanded
),
costs AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start, svc_end, billed, allowed_raw,
    round((billed * (0.3 + random()*0.4) - (10 + random()*200))::numeric, 2) AS paid_guess,
    round((10 + random()*200)::numeric, 2) AS ded_guess,
    round((5 + random()*50)::numeric, 2) AS copay_guess
  FROM calc
),
balanced AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start, svc_end, billed,
    GREATEST(allowed_raw, 0.01)::numeric(12,2) AS allowed,
    LEAST(GREATEST(paid_guess,0), allowed_raw)::numeric(12,2) AS paid_clamped,
    ded_guess, copay_guess
  FROM costs
),
split AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start, svc_end, billed,
    allowed, paid_clamped, ded_guess, copay_guess,
    (allowed - paid_clamped)::numeric(12,2) AS oop_pool,
    round(GREATEST((allowed - paid_clamped) - (ded_guess + copay_guess), 0)::numeric, 2) AS coins_raw
  FROM balanced
),
finalized AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start, svc_end, billed, allowed, paid_clamped,
    CASE
      WHEN (ded_guess + copay_guess + coins_raw) <= oop_pool THEN ded_guess
      ELSE round((oop_pool * (ded_guess / NULLIF(ded_guess + copay_guess + coins_raw,0)))::numeric, 2)
    END AS ded_final,
    CASE
      WHEN (ded_guess + copay_guess + coins_raw) <= oop_pool THEN copay_guess
      ELSE round((oop_pool * (copay_guess / NULLIF(ded_guess + copay_guess + coins_raw,0)))::numeric, 2)
    END AS copay_final,
    oop_pool
  FROM split
),
balanced_exact AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start, svc_end, billed, allowed, paid_clamped,
    ded_final, copay_final,
    round((oop_pool - (ded_final + copay_final))::numeric, 2) AS coins_final
  FROM finalized
),
with_flags AS (
  SELECT
    member_id, plan_id, provider_id, claim_type, svc_start, svc_end, billed,
    allowed, paid_clamped, ded_final, copay_final, coins_final,
    (random() < 0.12) AS deny_flag
  FROM balanced_exact
)
INSERT INTO hi.claims(
  member_id, provider_id, plan_id, claim_type, place_of_service,
  admit_date, discharge_date, service_start_date, service_end_date,
  billed_amount, allowed_amount, paid_amount,
  member_deductible, member_copay, member_coinsurance,
  denial_code, status, paid_date
)
SELECT
  wf.member_id,
  wf.provider_id,
  wf.plan_id,
  wf.claim_type,
  CASE wf.claim_type WHEN 'inpatient' THEN '21' ELSE '11' END,
  CASE WHEN wf.claim_type='inpatient' THEN wf.svc_start ELSE NULL END,
  CASE WHEN wf.claim_type='inpatient' THEN wf.svc_end   ELSE NULL END,
  wf.svc_start,
  wf.svc_end,
  wf.billed,
  wf.allowed,
  CASE WHEN wf.deny_flag THEN NULL ELSE wf.paid_clamped END,
  CASE WHEN wf.deny_flag THEN 0 ELSE wf.ded_final END,
  CASE WHEN wf.deny_flag THEN 0 ELSE wf.copay_final END,
  CASE WHEN wf.deny_flag THEN 0 ELSE wf.coins_final END,
  CASE WHEN wf.deny_flag THEN (ARRAY['CO-50','CO-97','PR-204','OA-18'])[1+floor(random()*4)] ELSE NULL END,
  CASE WHEN wf.deny_flag THEN 'denied' ELSE 'adjudicated' END,
  CASE WHEN wf.deny_flag THEN NULL ELSE wf.svc_end + (1+floor(random()*30))::int END
FROM with_flags wf;

COMMIT;
