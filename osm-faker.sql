SELECT id, imported, osm_date, pgosm_flex_version,
        osm2pgsql_mode
    FROM osm.pgosm_flex 
;

SELECT version();


-- Basic selection, provide attributes used to rank locations
DROP TABLE IF EXISTS places_for_shops_1;
CREATE TEMP TABLE places_for_shops_1 AS
WITH base AS (
SELECT osm_id, name, osm_type, admin_level, nest_level,
        -- Rounding is assuming SRID 3857, or another unit in Meters or Feet.
        ROUND(ST_Area(geom)::NUMERIC, 0) AS geom_area, geom
    FROM osm.place_polygon_nested
    WHERE innermost
        AND name <> ''
        AND admin_level < 99
), with_space AS (
SELECT b.osm_id, COUNT(lp.osm_id) AS near_areas,
        COALESCE(SUM(ST_Area(lp.geom)), 0) AS near_space,
        COUNT(c.osm_id) AS contained_areas,
        COALESCE(SUM(ST_Area(c.geom)), 0) AS contained_space
    FROM base b
    LEFT JOIN osm.landuse_polygon lp
        ON ST_Intersects(b.geom, lp.geom)
            AND lp.osm_type IN ('retail', 'commercial')
    LEFT JOIN osm.landuse_polygon c
        ON ST_Contains(b.geom, c.geom)
            AND c.osm_type IN ('retail', 'commercial')
    GROUP BY b.osm_id
)
SELECT b.*, ws.contained_areas, ws.contained_space,
        ws.near_areas, ws.near_space
    FROM base b
    INNER JOIN with_space ws ON b.osm_id = ws.osm_id
;


CREATE INDEX gix_places_for_shops ON places_for_shops_1 USING GIST (geom);


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

SELECT *
    FROM places_for_shops
    ORDER BY name
;


/*
 * The following scoring logic creates scores for each place depending
 * on how it's contained and nearby commercial areas compare to the area's
 * median values.
 * 
 * The final selection compares this score to random values. This means some
 * lower scored places will be selected when random is even lower, while
 * some higher scored places will be selected when random is even higher.
 */
drop table if exists place_scores;
CREATE TEMP TABLE place_scores AS
WITH breakpoints AS (
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
    WHERE p.near_areas > 0
;


DROP TABLE IF EXISTS selected;
CREATE TEMP TABLE selected AS
WITH a AS (
SELECT p.osm_id,
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

DROP SCHEMA faker CASCADE;
CREATE SCHEMA faker;
-- Selected areas to put Stores into.
CREATE TABLE faker.place_polygon AS
SELECT p.*
    FROM selected s
    INNER JOIN places_for_shops p ON s.osm_id = p.osm_id
    ORDER BY p.name
;

CREATE INDEX gix_faker_place_polygon
    ON faker.place_polygon USING GIST (geom)
;


SELECT *
    FROM faker.place_polygon
;


-----------------------------------------
-- Identify roads where a building could be
-- Not using actual buildings / addresses because:
---- a) privacy
---- b) coverage
DROP TABLE IF EXISTS selected_roads ;
CREATE TEMP TABLE selected_roads AS
WITH road_ranks AS (
SELECT p.osm_id AS place_osm_id, p.name AS place_name,
        CASE WHEN r.osm_type IN ('primary', 'secondary', 'tertiary')
                THEN 0.50
            WHEN r.osm_type IN ('residential', 'motorway', 'trunk')
                THEN .25
            ELSE .05
            END AS road_type_score,
        r.osm_id AS road_osm_id
    FROM faker.place_polygon p
    INNER JOIN osm.landuse_polygon c
        ON ST_Contains(p.geom, c.geom)
            AND c.osm_type IN ('retail', 'commercial')
    INNER JOIN osm.road_line r
        ON c.geom && r.geom
            AND r.route_motor
            AND r.osm_type NOT IN ('service')
            AND r.osm_type NOT LIKE '%link'
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


CREATE TABLE faker.store_location AS
SELECT a.place_osm_id, a.place_name, a.road_osm_id,
        r.osm_type, r.name, r.ref,
        ST_LineInterpolatePoint(ST_LineMerge(r.geom), random()) AS geom
    FROM selected_roads a
    INNER JOIN osm.road_line r ON a.road_osm_id = r.osm_id
;


SELECT *
    FROM faker.store_location
;



