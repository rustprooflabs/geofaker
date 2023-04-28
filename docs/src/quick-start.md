# Quick Start to Geo Faker

This section covers how to get started with the Faker version of PgOSM Flex,
also known as Geo Faker.


> Warning: This project is in early development!  Things will be changing over the first few releases (e.g. before 0.5.0).

The basic process to using Geo Faker are:

* Run PgOSM Flex with custom layerset
* Load PgOSM Flex Faker objects
* 

## Load OpenStreetMap Data

Load the region/subregion you want using the PgOSM Flex Docker image.
These instructions are modified from
[PgOSM Flex's Quick Start](https://pgosm-flex.com/quick-start.html)
section. The following loads the data into a PostGIS enabled database in a `geo-faker`
Docker container available on port 5433.


```bash
mkdir ~/pgosm-data
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=mysecretpassword

docker pull rustprooflabs/geo-faker:latest

docker run --name pgosm-faker -d --rm \
    -v ~/pgosm-data:/app/output \
    -v ~/git/geo-faker/:/custom-layerset \
    -v /etc/localtime:/etc/localtime:ro \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -p 5433:5432 -d rustprooflabs/geo-faker

docker exec -it \
    pgosm-faker python3 docker/pgosm_flex.py \
    --ram=8 \
    --region=north-america/us \
    --subregion=nebraska \
    --layerset=faker_layerset \
    --layerset-path=/custom-layerset/
```


## Load Faker Objects

After the data completes processing, load the PgOSM Flex Faker database structures
in the `geo_faker` schema.
This is done using Sqitch.


```bash
cd geo-faker/db
sqitch db:pg://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5433/pgosm deploy
```

Connect to the database and call this stored procedure.  The generated data
is left in a temp table, each run of the stored procedure will produce new,
random results.

## Run Faker generation

There are two stored procedures in the `geo_faker` schema that
generate the fake stores and customers.


The stored procedure `geo_faker.point_in_place_landuse()` places points
along roads that are within (or nearby) specific `landuse` areas.  The generated
data is available after calling the stored procedure in a temporary table
named `faker_store_location`.
The generated data is scoped to named places currently, though that will
likely become adjustable in the future.


The `geo_faker.point_in_place_landuse()` stored procedure requires
the `faker_store_location` temp table created by the first stored procedure.



```sql
CALL geo_faker.point_in_place_landuse();
CALL geo_faker.points_around_point();
```

The following query saves the data in a new, non-temporary table named
`my_fake_stores`.






```sql
CREATE TABLE my_fake_stores AS
SELECT *
    FROM faker_store_location
;

CREATE TABLE my_fake_customers AS
SELECT *
    FROM faker_customer_location
;
```



