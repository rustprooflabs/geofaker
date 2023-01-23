# PostGIS Geo Faker

The project creates fake store and customer data with geospatial
components based on OpenStreetMap.  The use of OpenStreetMap data
as a starting point provides a sense of realism. The use of `random()`
and to generate fake data avoids privacy concerns.

## Load OpenStreetMap Data

Load the region/subregion you want using the PgOSM Flex Docker image.
The [Quick Start section](https://github.com/rustprooflabs/pgosm-flex#quick-start)
loads the data into a PostGIS enabled database in the Docker container,
available on port 5433.

> Update instructions to use custom layerset.  Only need place, road, and land use.




