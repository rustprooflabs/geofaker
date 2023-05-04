CALL geofaker.point_in_place_landuse();
/*
    Sets scale of distance for customers, and density of customer points 
*/
CALL geofaker.points_around_point(1.0, 1.0);


DROP TABLE IF EXISTS geofaker.store;
CREATE TABLE geofaker.store AS
SELECT *
    FROM faker_store_location
    ORDER BY store_id
;
COMMENT ON TABLE geofaker.store IS 'Created by Geo Faker, a PgOSM Flex based project.';

DROP TABLE IF EXISTS geofaker.customer;
CREATE TABLE geofaker.customer AS
SELECT *
    FROM faker_customer_location
    ORDER BY store_id, customer_id
;
COMMENT ON TABLE geofaker.customer IS 'Created by Geo Faker, a PgOSM Flex based project.';

