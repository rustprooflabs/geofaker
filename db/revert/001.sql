-- Revert pgosm-flex-faker:001 from pg

BEGIN;

DROP SCHEMA geo_faker CASCADE;

COMMIT;
