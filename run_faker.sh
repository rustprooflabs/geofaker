#!/bin/bash
echo 'Deploying geofaker schema via Sqitch...'
cd /app/faker/db
sqitch db:pg://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost/pgosm deploy

echo 'Running GeoFaker generation...'
psql -d postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost/pgosm \
    -f /app/run_faker.sql

echo 'Running pg_dump...'
pg_dump -d postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost/pgosm \
    -n geofaker -f /app/output/geofaker_stores_customers.sql
