-- Deploy pgosm-flex-faker:001 to pg

BEGIN;

CREATE SCHEMA pgosm_flex_faker;


CREATE FUNCTION pgosm_flex_faker.location_in_place_landuse()
 RETURNS BOOLEAN
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pgosm_flex_faker, pg_temp'
AS $$

	-- Do something

	SELECT True;

$$
;


COMMIT;
