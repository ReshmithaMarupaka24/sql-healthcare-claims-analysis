-- Performance indexes (safe to re-run)
CREATE INDEX IF NOT EXISTS claims_member_id_idx      ON hi.claims (member_id);
CREATE INDEX IF NOT EXISTS claims_provider_id_idx    ON hi.claims (provider_id);
CREATE INDEX IF NOT EXISTS claims_plan_id_idx        ON hi.claims (plan_id);
CREATE INDEX IF NOT EXISTS claims_status_idx         ON hi.claims (status);
CREATE INDEX IF NOT EXISTS claims_type_idx           ON hi.claims (claim_type);
CREATE INDEX IF NOT EXISTS claims_svc_start_idx      ON hi.claims (service_start_date);
CREATE INDEX IF NOT EXISTS claims_paid_date_idx      ON hi.claims (paid_date);

CREATE INDEX IF NOT EXISTS claim_dx_code_idx         ON hi.claim_dx (dx_code);
CREATE INDEX IF NOT EXISTS claim_px_code_idx         ON hi.claim_px (px_code);
