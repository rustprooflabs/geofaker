-- Revert pgosm-flex-faker:001 from pg

BEGIN;

DROP SCHEMA pgosm_flex_faker CASCADE;

COMMIT;
