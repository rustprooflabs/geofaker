# Customize

This section builds on the [Quick Start](quick-start.md) section.
Customizing the runtime operation of Geo Faker currently involves
manually connecting to the Geo Faker database and changing things.
In the near (ish?) future customization should become easier,
see [issue #9](https://github.com/rustprooflabs/geofaker/issues/9).


> Warning: This project is in early development!  Things will be changing over the first few releases (e.g. before 0.5.0).

## Range and Density of Customer points

The customer points currently have two main tunable options:

* `_distance_scale` default 1.5
* `_density_scale` default 1.0

After running the main process, you can re-run the steps creating the `geofaker.customer`
points using the following code.  This example doubles the density scale (from 1.5 to 3)
and reduces density from 1.0 to 0.25.

> See `app/run_faker.sql` for what runs by default.


```sql
CALL geofaker.points_around_point(_distance_scale:=3,
                                  _density_scale:=0.25);

DROP TABLE IF EXISTS geofaker.customer;
CREATE TABLE geofaker.customer AS
SELECT *
    FROM faker_customer_location
    ORDER BY store_id, customer_id
;
COMMENT ON TABLE geofaker.customer IS 'Created by Geo Faker, a PgOSM Flex based project.';
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

Geo Faker can load data into an external database, though the steps are currently
more manual than then in-Docker. Start by setting
[Postgres permissions](https://pgosm-flex.com/postgres-permissions.html) in the
target database.  Then setup an environment variable and run the Docker container
with the additional parameters [shown here](https://pgosm-flex.com/postgres-external.html).


Run the initial PgOSM Flex part of the process to load the OpenStreetMap data.

```bash
source ~/.pgosm-faker-local

docker run --name geofaker -d --rm \
    -v ~/pgosm-data:/app/output \
    -v /etc/localtime:/etc/localtime:ro \
    -e POSTGRES_USER=$POSTGRES_USER \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -e POSTGRES_HOST=$POSTGRES_HOST \
    -e POSTGRES_DB=$POSTGRES_DB \
    -e POSTGRES_PORT=$POSTGRES_PORT \
    -p 5439:5432 -d rustprooflabs/geofaker

docker exec -it \
    geofaker python3 docker/pgosm_flex.py \
    --ram=8 \
    --region=north-america/us \
    --subregion=colorado \
    --layerset=faker
```

From the `geofaker` directory, change into the `db` folder to deploy the Sqitch
schema needed for Geo Faker.


```bash
cd ~/git/geofaker/db
sqitch db:pg://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB deploy
```

You can run the SQL steps exactly from the script.  Or customize them first.


```bash
psql -d postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB \
    -f ~/git/geofaker/run_faker.sql
```



