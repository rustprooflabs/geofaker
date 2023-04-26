# Quick Start to PgOSM Flex Faker

This section covers how to get started with the Faker version of PgOSM Flex.


## Load OpenStreetMap Data

Load the region/subregion you want using the PgOSM Flex Docker image.
These instructions are modified from [PgOSM Flex's Quick Start](https://pgosm-flex.com/quick-start.html) section. The following
loads the data into a PostGIS enabled database in a `pgosm-flex-faker`
Docker container available on port 5433.


```bash
mkdir ~/pgosm-data
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=mysecretpassword

docker pull rustprooflabs/pgosm-flex-faker:latest

docker run --name pgosm-faker -d --rm \
    -v ~/pgosm-data:/app/output \
    -v ~/git/pgosm-flex-faker/:/custom-layerset \
    -v /etc/localtime:/etc/localtime:ro \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -p 5433:5432 -d rustprooflabs/pgosm-flex-faker

docker exec -it \
    pgosm-faker python3 docker/pgosm_flex.py \
    --ram=8 \
    --region=north-america/us \
    --subregion=nebraska \
    --layerset=faker_layerset \
    --layerset-path=/custom-layerset/
```


## Load Faker Objects

After the data completes processing, load the PgOSM Flex Faker database structures.
This is done using Sqitch.


```bash
cd pgosm-flex-faker/db
sqitch db:pg://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5433/pgosm deploy
```

Connect to the database and call this stored procedure.  The generated data
is left in a temp table, each run of the stored procedure will produce new,
random results.

## Run Faker generation

The stored procedure `pgosm_flex_faker.point_in_place_landuse()` places points
along roads that are within (or nearby) specific `landuse` areas.  The generated
data is available after calling the stored procedure in a temporary table
named `faker_store_location`.
The generated data is scoped to named places currently, though that will
likely become adjustable in the future.


```sql
CALL pgosm_flex_faker.point_in_place_landuse();
SELECT COUNT(*) FROM faker_store_location;
```


The following query saves the data in a new, non-temporary table named
`my_fake_stores`.



```sql
CREATE TABLE my_fake_stores AS
SELECT *
    FROM faker_store_location
;
```
