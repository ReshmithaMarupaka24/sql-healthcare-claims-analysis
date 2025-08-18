-- Quick health checks

-- Row counts
SELECT 'plans' tbl, COUNT(*) FROM hi.plans
UNION ALL SELECT 'providers', COUNT(*) FROM hi.providers
UNION ALL SELECT 'members', COUNT(*) FROM hi.members
UNION ALL SELECT 'claims', COUNT(*) FROM hi.claims
UNION ALL SELECT 'claim_dx', COUNT(*) FROM hi.claim_dx
UNION ALL SELECT 'claim_px', COUNT(*) FROM hi.claim_px;

-- Cost-share balance (should be 0)
SELECT COUNT(*) AS bad_sum_rows
FROM hi.claims
WHERE paid_amount IS NOT NULL
  AND ABS(allowed_amount - paid_amount - member_deductible - member_copay - member_coinsurance) > 0.01;

-- No negative amounts (should be 0)
SELECT COUNT(*) AS bad_amounts
FROM hi.claims
WHERE billed_amount < 0 OR allowed_amount < 0
   OR COALESCE(paid_amount,0) < 0
   OR member_deductible < 0 OR member_copay < 0 OR member_coinsurance < 0;

-- Date logic (should be 0)
SELECT COUNT(*) AS bad_dates
FROM hi.claims
WHERE service_start_date > service_end_date
   OR (paid_date IS NOT NULL AND paid_date < service_end_date)
   OR (claim_type='inpatient' AND (admit_date IS NULL OR discharge_date IS NULL OR admit_date > discharge_date));
