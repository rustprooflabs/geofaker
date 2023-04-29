# Quick Start to Geo Faker

This section covers how to get started with the Faker version of PgOSM Flex,
also known as Geo Faker.


> Warning: This project is in early development!  Things will be changing over the first few releases (e.g. before 0.5.0).

The basic process to using Geo Faker are:

* Run PgOSM Flex with custom layerset
* Load Geo Faker objects
* Run stored procedures
* Move temp table data to real tables


## Load OpenStreetMap Data

Load the region/subregion you want using the PgOSM Flex Docker image.
These instructions are modified from
[PgOSM Flex's Quick Start](https://pgosm-flex.com/quick-start.html)
section. The following loads the data into a PostGIS enabled database in a `geofaker`
Docker container available on port 5433.


```bash
mkdir ~/pgosm-data
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=mysecretpassword

docker pull rustprooflabs/geofaker:latest

docker run --name geofaker -d --rm \
    -v ~/pgosm-data:/app/output \
    -v /etc/localtime:/etc/localtime:ro \
    -e POSTGRES_USER=$POSTGRES_USER \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -p 5433:5432 -d rustprooflabs/geofaker

docker exec -it \
    geofaker python3 docker/pgosm_flex.py \
    --ram=8 \
    --region=north-america/us \
    --subregion=nebraska \
    --layerset=faker
```


## Load and Run Faker Objects

After the data completes processing, load the Geo Faker database structures
in the `geofaker` schema.  This deploys the functions and procedures needed,
runs the processing, and runs `pg_dump` saving the faked
data into `~/pgosm-data/geofaker_stores_customers.sql`.


```bash
docker exec -it geofaker /bin/bash run_faker.sh
```

Load the saved data into a database of your choice.

```bash
psql -d pgosm_faker -f ~/pgosm-data/geofaker_stores_customers.sql 
```

