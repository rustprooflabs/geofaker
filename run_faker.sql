CALL geofaker.point_in_place_landuse();
CALL geofaker.points_around_point();


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



