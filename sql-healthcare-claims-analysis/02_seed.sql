-- Seed codes, plans, providers, members
BEGIN;

-- Optional: reset (safe to comment out if you don't want to wipe)
TRUNCATE hi.claim_px, hi.claim_dx, hi.claims, hi.members, hi.providers, hi.px_codes, hi.dx_codes
RESTART IDENTITY CASCADE;
TRUNCATE hi.plans RESTART IDENTITY CASCADE;

-- Diagnosis codes
INSERT INTO hi.dx_codes(dx_code, description)
SELECT 'E11.'||lpad(g::text,1,'0'), 'Type 2 diabetes with complication '||g
FROM generate_series(0,9) g
UNION ALL
SELECT 'I10','Essential hypertension'
UNION ALL
SELECT 'J18.9','Pneumonia, unspecified organism';

-- Procedure codes
INSERT INTO hi.px_codes(px_code, description) VALUES
('99213','Office/outpatient visit est'),
('93000','Electrocardiogram'),
('70450','CT Head wo contrast'),
('71020','Chest x-ray'),
('90791','Psych diagnostic eval');

-- Plans
INSERT INTO hi.plans(plan_name, metal_tier, deductible, oop_max) VALUES
('HMO Saver','Silver',2500,8000),
('PPO Choice','Gold',1000,6000),
('EPO Plus','Bronze',3500,9000);

-- Providers
INSERT INTO hi.providers(npi, provider_name, specialty, state)
SELECT lpad((1000000000+g)::text,10,'0'),
       'Provider '||g,
       (ARRAY['Internal Medicine','Cardiology','Orthopedics','Psychiatry','Radiology'])[1+floor(random()*5)],
       (ARRAY['TX','CA','FL','NY','WA'])[1+floor(random()*5)]
FROM generate_series(1,300) g;

-- Members (always pick an existing plan_id)
INSERT INTO hi.members(first_name,last_name,dob,gender,zip3,plan_id,enrollment_start,enrollment_end)
SELECT
  'Member'||g, 'Test',
  date '1940-01-01' + (random()*30000)::int,
  (ARRAY['F','M','O'])[1+floor(random()*3)],
  lpad((100+floor(random()*900))::text,3,'0'),
  (SELECT plan_id FROM hi.plans ORDER BY random() LIMIT 1),
  date '2022-01-01',
  date '2025-12-31'
FROM generate_series(1,20000) g;

COMMIT;
