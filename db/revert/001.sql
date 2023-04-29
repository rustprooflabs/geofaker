-- Revert pgosm-flex-faker:001 from pg

BEGIN;

DROP SCHEMA geofaker CASCADE;

COMMIT;
