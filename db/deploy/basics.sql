-- Deploy pgosm-flex-faker:extensions to pg

BEGIN;

CREATE SCHEMA IF NOT EXISTS geofaker;
CREATE EXTENSION IF NOT EXISTS pgfaker;

COMMIT;
