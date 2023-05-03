# What is Geo Faker?

Geo Faker is a project to create fake geospatial data in PostGIS.
The generated data is based on real OpenStreetMap region, using
the region of your choice.  The whole process is easy
thanks to the [PgOSM Flex](https://pgosm-flex.com/)
project, which provides the main functionality used by Geo Faker.


The Geo Faker project currently creates two tables with fake store
and fake customer data.  The use of OpenStreetMap data
as a starting point provides a sense of realism. The use of `random()`
and other methods to generate fake data avoid privacy concerns.


> Warning: This project is in early development!  Things will be changing quickly over the first few releases (e.g. before 0.5.0).



## Faked Data

The following images show Geo Faker at work using the data from
the entire United States as its input.  This first image shows
the store placements around the lower-48 states of the United States.

![Map of United States (lower 48) with the title "Geo Faker Stores - United States".  Purple dots representing fake stores are indicated across the entire country.  Copyright OpenStreetMap Contributors](geo-faker-0-1-1-stores-us.jpg)

The next image is zoomed in to show the faked store and customer
data in Wisconsin, with Madison, WI in the center of the image and
Milwaukee, WI on the right side. This image shows the current distribution
and range of the faked customer data is not ideal.  It is currently
hard coded to a (inexact) 5 kilometer (km) radius.
[Issue #6](https://github.com/rustprooflabs/geofaker/issues/6)
was opened to address that limitation.


![Map of Wisconsin in the U.S. with the title "Geo Faker Customers and Stores - Wisconsin".  Purple dots represent fake stores, light brown/gray dots represent fake customers.  Fake customers are placed within roughly 5 kilometers of their associated store. Copyright OpenStreetMap Contributors](geo-faker-0-1-1-stores-customers-wi.jpg)

The next map is zoomed in to one store in Madison, WI with only that
store's customers selected.


![Map of Wisconsin in the U.S. with the title "Geo Faker - One Store with Customers - Madison, Wisconsin".  One purple dots representing a single fake store surrounded by brown dots representing fake customers.  Fake customers are placed within roughly 5 kilometers of their associated store. Copyright OpenStreetMap Contributors](geo-faker-0-1-1-storescustomers-madsion-wi.jpg)


An even closer view at the street level shows that all of the points
are placed directly on roads.  The main reason for this was to force
truly random points into a more realistic set of locations.

One benefit from this decision is this makes Geo Faker data
easy to use for routing with `pgrouting`.


![alt coming soon](geo-faker-0-1-1-storescustomers-street-level.jpg)

## Size of data



The exact row counts will vary from run to run, even with the same inputs.
The details shown below illustrate roughly what is generated with the
entire U.S. as the input.

```sql
SELECT s_name, table_count, view_count, function_count,
        size_plus_indexes
    FROM dd.schemas WHERE s_name IN ('geofaker', 'osm')
;
```

```
┌──────────┬─────────────┬────────────┬────────────────┬───────────────────┐
│  s_name  │ table_count │ view_count │ function_count │ size_plus_indexes │
╞══════════╪═════════════╪════════════╪════════════════╪═══════════════════╡
│ geofaker │           2 │          0 │              3 │ 277 MB            │
│ osm      │          10 │          1 │              4 │ 18 GB             │
└──────────┴─────────────┴────────────┴────────────────┴───────────────────┘
```


```sql
SELECT s_name, t_name, rows, size_plus_indexes, description
    FROM dd.tables
    WHERE s_name IN ('geofaker')
;
```

```
┌──────────┬──────────┬─────────┬───────────────────┬───────────────────────────────────────────────────┐
│  s_name  │  t_name  │  rows   │ size_plus_indexes │                    description                    │
╞══════════╪══════════╪═════════╪═══════════════════╪═══════════════════════════════════════════════════╡
│ geofaker │ store    │    4331 │ 656 kB            │ Created by Geo Faker, a PgOSM Flex based project. │
│ geofaker │ customer │ 3424117 │ 276 MB            │ Created by Geo Faker, a PgOSM Flex based project. │
└──────────┴──────────┴─────────┴───────────────────┴───────────────────────────────────────────────────┘
```


Checking what was loaded in the `osm.pgosm_flex` table.

```sql
SELECT osm_date, region, layerset, pgosm_flex_version
    FROM osm.pgosm_flex
;
```

```
┌────────────┬──────────────────┬──────────┬────────────────────┐
│  osm_date  │      region      │ layerset │ pgosm_flex_version │
╞════════════╪══════════════════╪══════════╪════════════════════╡
│ 2023-04-30 │ north-america-us │ faker    │ 0.8.0-8fb2621      │
└────────────┴──────────────────┴──────────┴────────────────────┘
```
