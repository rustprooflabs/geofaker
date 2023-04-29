# Customize

This section builds on the [Quick Start](quick-start.md) section.

> Warning: This project is in early development!  Things will be changing over the first few releases (e.g. before 0.5.0).



## Each time is new data

Rerun, save second set.

```sql
CALL geo_faker.point_in_place_landuse();
CREATE TABLE my_fake_stores_v2 AS
SELECT *
    FROM faker_store_location
;
```

## Custom Places for Shops

The procedure `geo_faker.point_in_place_landuse()` allows overriding
the inclusion of `retail` and `commercial` landuse.
This is done by creating a custom `landuse_osm_types` table before
running the stored procedure.



```sql
DROP TABLE IF EXISTS landuse_osm_types;
CREATE TEMP TABLE IF NOT EXISTS landuse_osm_types AS
SELECT 'college' AS osm_type
UNION
SELECT 'recreation_ground' AS osm_type
UNION
SELECT 'vineyard' AS osm_type
;
```


## External Postgres connections

Geo Faker currently does not support running directly into an external database.
Technically it can be operated that way, but the instructions and helper scripts
are specific to using the in-Docker database.

Use `--pg-dump` to extract the generated data.

