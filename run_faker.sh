#!/bin/bash
echo 'Deploying geofaker schema via Sqitch...'
cd /app/faker/db
sqitch db:pg://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:5432/pgosm deploy

echo 'Running GeoFaker generation...'
psql -d postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost/pgosm \
    -f /app/run_faker.sql
