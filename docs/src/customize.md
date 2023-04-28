# Customize

This section builds on the [Quick Start](quick-start.md) section.

> Warning: This project is in early development!  Things will be changing over the first few releases (e.g. before 0.5.0).


## External Postgres connections

The quick start uses the built-in Postgres/PostGIS instance. See
the PgOSM Flex section on [Using external Postgres connections](https://pgosm-flex.com/postgres-external.html) to use your own Postgres instance.
This approach does load a lot of data to the target database which may not be
desired.  Consider using `pg_dump` to load only the target data to your
database of choice.

The Sqitch deployment step should use additional parameters not set in the quick start
instructions.

```bash
source ~/.pgosm-faker-local
cd pgosm-flex-faker/db
sqitch db:pg://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB deploy
```


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
