-- Deploy pgosm-flex-faker:point-in-place-landuse to pg
-- requires: basics

BEGIN;


CREATE PROCEDURE geofaker.point_in_place_landuse()
LANGUAGE plpgsql
AS $$
BEGIN

	-- Define a custom `landuse_osm_types` table before executing to customize areas
	CREATE TEMP TABLE IF NOT EXISTS landuse_osm_types AS
	SELECT 'retail' AS osm_type
	UNION
	SELECT 'commercial' AS osm_type
	;


	-- Basic selection, provide attributes used to rank locations
	DROP TABLE IF EXISTS places_for_shops_1;
	CREATE TEMP TABLE places_for_shops_1 AS
	WITH base AS (
	SELECT osm_id, name, osm_type, admin_level, nest_level,
			-- Rounding is assuming SRID 3857, or another unit in Meters or Feet.
			ROUND(public.ST_Area(geom)::NUMERIC, 0) AS geom_area,
			geom
		FROM osm.place_polygon_nested
		-- Using innermost places to reduce likelihood over overlap
		WHERE innermost
			-- originally had following more strict checks, considering leaving
			-- them off to make more flexible
			/*AND name <> ''
			AND admin_level < 99*/
	), with_space AS (
	-- Within each Place, find how many places are "near" (intersects)
	-- or contain the types of places (commercial, retail, residential, etc)
	-- defined in landuse_osm_types  
	SELECT b.osm_id,
			COUNT(lp.osm_id) AS near_areas,
			COALESCE(SUM(public.ST_Area(lp.geom)), 0) AS near_space,
			COUNT(c.osm_id) AS contained_areas,
			COALESCE(SUM(public.ST_Area(c.geom)), 0) AS contained_space
		FROM base b
		LEFT JOIN osm.landuse_polygon lp
			ON public.ST_Intersects(b.geom, lp.geom)
				AND lp.osm_type IN (SELECT osm_type FROM landuse_osm_types)
		LEFT JOIN osm.landuse_polygon c
			ON public.ST_Contains(b.geom, c.geom)
				AND c.osm_type IN (SELECT osm_type FROM landuse_osm_types)
		GROUP BY b.osm_id
	)
	SELECT b.*, ws.contained_areas, ws.contained_space,
			ws.near_areas, ws.near_space
		FROM base b
		INNER JOIN with_space ws ON b.osm_id = ws.osm_id
	;


	DROP TABLE IF EXISTS places_for_shops;
	CREATE TEMP TABLE places_for_shops AS
	SELECT osm_id, name, osm_type, admin_level, contained_areas, contained_space,
			near_areas, near_space, geom_area,
			contained_space / geom_area AS space_contained_ratio_higher_is_better,
			near_space / geom_area AS space_near_ratio_higher_is_better,
			geom
		FROM places_for_shops_1
		ORDER BY space_contained_ratio_higher_is_better DESC,
				space_near_ratio_higher_is_better DESC
	;


	/*
	* The following scoring logic creates scores for each place depending
	* on how it's contained and nearby landuse data compare to the area's
	* percentile values.
	*/
	DROP TABLE IF EXISTS place_scores;
	CREATE TEMP TABLE place_scores AS
	WITH breakpoints AS (
	-- Calculate percentiles of space available across all available place inputs
	-- This should let each region adjust for the input data
	SELECT percentile_cont(0.25)
				within group (order by contained_space asc)
				as contained_space_25_perc,
			percentile_cont(0.50)
				within group (order by contained_space asc)
				as contained_space_50_perc,
			percentile_cont(0.90)
				within group (order by near_space asc)
				as near_space_90_perc
		FROM places_for_shops
		WHERE near_areas > 0
	)
	SELECT p.osm_id,
			-- Actual ranking is arbitrary, they key is understanding that scores
			-- under a random value in the next step (where random between 0.0 and 1.0)
			-- so increasing the max score here results in some areas almost always
			-- being picked
			CASE WHEN b.contained_space_50_perc < p.contained_space
					THEN .55
				WHEN b.contained_space_25_perc < p.contained_space
					THEN .35
				ELSE .01
			END AS contained_space_score,
			CASE WHEN b.near_space_90_perc < p.near_space
					THEN .1
				ELSE .01
			END AS near_space_score
		FROM places_for_shops p
		INNER JOIN breakpoints b ON True
		-- Excludes places that aren't even nearby (intersects) an appropriate
		-- place type
		WHERE p.near_areas > 0
	;

	DROP TABLE IF EXISTS selected;
	CREATE TEMP TABLE selected AS
	WITH a AS (
	SELECT p.osm_id,
			-- Range of total_score:  .02 - .65
			s.contained_space_score + s.near_space_score
				AS total_score,
			random() as rnd
		FROM places_for_shops p
		INNER JOIN place_scores s
			ON p.osm_id = s.osm_id
	)
	SELECT a.osm_id
		FROM a  
		WHERE a.total_score > a.rnd
	;

	-- Selected areas to put points into.
	DROP TABLE IF EXISTS faker_place_polygon; 
	CREATE TEMP TABLE faker_place_polygon AS
	SELECT p.*
		FROM selected s
		INNER JOIN places_for_shops p ON s.osm_id = p.osm_id
		ORDER BY p.name
	;

	CREATE INDEX gix_faker_place_polygon
		ON faker_place_polygon USING GIST (geom)
	;

	/*
		Ranking roads by osm_type with goal of scoring roads with lower speed
		limits higher.  Uses helper table loaded by PgOSM Flex.

		Uses window function for rank steps, then normalize to 0-1 range.
		Finally, squishes range into 0.05 - 0.90 to prevent guarantees of
		never or always included.
	*/ 
	DROP TABLE IF EXISTS road_osm_type_rank;
	CREATE TEMP TABLE road_osm_type_rank AS
	WITH rank_lower_speed_better AS (
	SELECT osm_type, maxspeed_mph,
			RANK() OVER  (ORDER BY maxspeed_mph desc) AS rnk_raw
		FROM pgosm.road
		WHERE route_motor
			AND osm_type NOT LIKE '%link'
	), aggs_for_normalization AS (
	SELECT MIN(rnk_raw) AS min_rnk, MAX(rnk_raw) AS max_rnk
		FROM rank_lower_speed_better
	), normal_rnk AS (
	SELECT r.osm_type, r.maxspeed_mph,
			(rnk_raw * 1.0 - min_rnk) / (max_rnk - min_rnk)
				AS normalized_rnk
		FROM rank_lower_speed_better r
		JOIN aggs_for_normalization ON True
	)
	SELECT osm_type, maxspeed_mph,
			CASE WHEN normalized_rnk < 0.05 THEN 0.05
				WHEN normalized_rnk > 0.9 THEN .9
				ELSE normalized_rnk
				END AS normalized_rnk
		FROM normal_rnk
	;

	/*
	Identify roads where a building could be
	Not using actual buildings / addresses because:
	    a) privacy
	    b) coverage

	Main limitation of this is the point chosen on the road could extend far
	outside of the landuse.
	As I'm writing these initial versions I don't care, consider splitting road
	lines on the place boundaries to limit in the future if desired.
	*/
	DROP TABLE IF EXISTS selected_roads ;
	CREATE TEMP TABLE selected_roads AS
	WITH road_ranks AS (
	SELECT p.osm_id AS place_osm_id, p.osm_type AS place_osm_type,
			p.name AS place_name,
			rr.normalized_rnk AS road_type_score,
			r.osm_id AS road_osm_id
		FROM faker_place_polygon p
		INNER JOIN osm.landuse_polygon c
			ON public.ST_Contains(p.geom, c.geom)
				AND c.osm_type IN (SELECT osm_type FROM landuse_osm_types)
		INNER JOIN osm.road_line r
			ON c.geom && r.geom
				AND r.route_motor
				AND r.osm_type NOT IN ('service')
				AND r.osm_type NOT LIKE '%link'
		INNER JOIN road_osm_type_rank rr
			ON r.osm_type = rr.osm_type
	), ranked AS (
	SELECT *,
			ROW_NUMBER() OVER (
				PARTITION BY place_osm_id
				ORDER BY road_type_score DESC, random()) AS rnk
		FROM road_ranks
	)
	SELECT *
		FROM ranked
		WHERE rnk = 1
		;


	DROP TABLE IF EXISTS faker_store_location;
	CREATE TEMP TABLE faker_store_location AS
	SELECT ROW_NUMBER() OVER () AS store_id, a.place_name AS city,
			r.name AS street_name, r.ref AS road_ref,
            pgfaker.company(), pgfaker.slogan(), pgfaker.phone(),
			public.ST_LineInterpolatePoint(public.ST_LineMerge(r.geom), random()) AS geom
		FROM selected_roads a
		INNER JOIN osm.road_line r ON a.road_osm_id = r.osm_id
	;


END
$$
;

COMMENT ON PROCEDURE geofaker.point_in_place_landuse IS 'Uses osm.landuse_polygon and osm.road_line to simulate probable locations for commercial store locations.  Can be customized for custom landuse types by manually defining landuse_osm_types temp table.'
;


COMMIT;
