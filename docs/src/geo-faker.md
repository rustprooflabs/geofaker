# What is Geo Faker?

Geo Faker is a project to create fake geospatial data in PostGIS.
The generated data is based on real OpenStreetMap region, using
the region of your choice.  The whole process is easy
thanks to the [PgOSM Flex](https://pgosm-flex.com/)
project, which provides the main functionality used by Geo Faker.


The the Geo Faker project currently creates two tables with fake store
and fake customer data.  The use of OpenStreetMap data
as a starting point provides a sense of realism. The use of `random()`
and other methods to generate fake data avoid privacy concerns.


> Warning: This project is in early development!  Things will be changing quickly over the first few releases (e.g. before 0.5.0).




----

Geo Faker stores generated around the United States.

![Map of United States (lower 48) with the title "Geo Faker Stores - United States".  Purple dots representing fake stores are indicated across the entire country](geo-faker-0-1-1-stores-us.jpg)



