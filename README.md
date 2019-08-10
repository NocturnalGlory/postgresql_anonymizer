
![PostgreSQL Anonymizer](images/png_RVB/PostgreSQL-Anonymizer_H_couleur.png)

Anonymization & Data Masking for PostgreSQL
===============================================================================

`postgresql_anonymizer` is an extension to mask or replace
[personally identifiable information] (PII) or commercially sensitive data from
a PostgreSQL database.

The projet is aiming toward a **declarative approach** of anonymization. This
means we're trying to extend PostgreSQL Data Definition Language (DDL) in
order to specify the anonymization strategy inside the table definition itself.

Once the maskings rules are defined, you can access the anonymized data in 3  
different ways :

* [Anonymous Dumps] : Simply export the masked data into an SQL file
* [In-Place Anonymization] : Remove the PII according to the rules
* [Dynamic Masking] : Hide PII only for the masked users

In addition, various masking techniques are available : randomization, faking,
partial scrambling, shufflin, noise or even your own custom function !

Read the [Concepts] section for more details and [NEWS.md] for information
about the latest version.

[NEWS.md]: NEWS.md
[INSTALL.md]: docs/INSTALL.md
[Concepts]: #Concepts
[personally identifiable information]: https://en.wikipedia.org/wiki/Personally_identifiable_information

[Anonymous Dumps]: #Anonymous-Dumps
[In-Place Anonymization]: #In-Place-Anonymization
[Dynamic Masking]: #Dynamic-Masking


Declaring The Masking Rules
------------------------------------------------------------------------------

The main idea of this extension is to offer **anonymization by design**.

The data masking rules should be written by the people who develop the 
application because they have the best knowledge of how the data model works.
Therefore masking rules must be implemented directly inside the database schema.

This allows to mask the data directly inside the PostgreSQL instance without 
using an external tool and thus limiting the exposure and the risks of data leak.

The data masking rules are declared simply by using the `COMMENT` syntax :

```sql
=# CREATE EXTENSION IF NOT EXISTS anon CASCADE;

=# SELECT anon.load();

=# CREATE TABLE player( id SERIAL, name TEXT, score INT);

=# COMMENT ON COLUMN player.name IS 'MASKED WITH FUNCTION anon.fake_last_name()';
```

If your columns already have comments, simply append the `MASKED WITH FUNCTION` 
statement at the end of the comment.


In-Place Anonymization
------------------------------------------------------------------------------

You can permanetly remove the PII from a database with `anon.anymize_database()`.
This will destroy the original data. Use with care.

```sql
=# SELECT * FROM customer;
 id  |   full_name      |   birth    |    employer   | zipcode | fk_shop
-----+------------------+------------+---------------+---------+---------
 911 | Chuck Norris     | 1940-03-10 | Texas Rangers | 75001   | 12
 112 | David Hasselhoff | 1952-07-17 | Baywatch      | 90001   | 423


=# CREATE EXTENSION IF NOT EXISTS anon CASCADE;
=# SELECT anon.load();

=# COMMENT ON COLUMN customer.full_name 
-# IS 'MASKED WITH FUNCTION anon.fake_first_name() || '' '' || anon.fake_last_name()';

=# COMMENT ON COLUMN customer.birth   
-# IS 'MASKED WITH FUNCTION anon.random_date_between(''01/01/1920''::DATE,now())';

=# COMMENT ON COLUMN customer.employer
-# IS 'MASKED WITH FUNCTION anon.fake_company()';

=# COMMENT ON COLUMN customer.zipcode
-# IS 'MASKED WITH FUNCTION anon.random_zip()';

=# SELECT anon.anonymize_database();

=# SELECT * FROM customer;
 id  |     full_name     |   birth    |     employer     | zipcode | fk_shop
-----+-------------------+------------+------------------+---------+---------
 911 | michel Duffus     | 1970-03-24 | Body Expressions | 63824   | 12
 112 | andromache Tulip  | 1921-03-24 | Dot Darcy  

```

You can also use `anonymize_table()` and `anonymize_column()` to remove data from
a subset of the database.




Dynamic Masking
------------------------------------------------------------------------------

You can hide the PII from a role by declaring it as a "MASKED". Other roles
will still access the original data.  

**Example**:

```sql
=# SELECT * FROM people;
  id  |      name      |   phone
------+----------------+------------
 T800 | Schwarzenegger | 0609110911
(1 row)
```

STEP 1 : Activate the masking engine

```sql
=# CREATE EXTENSION IF NOT EXISTS anon CASCADE;
=# SELECT anon.start_dynamic_masking();
```

STEP 2 : Declare a masked user

```sql
=# CREATE ROLE skynet LOGIN;
=# COMMENT ON ROLE skynet IS 'MASKED';
```

STEP 3 : Declare the masking rules

```sql
=# COMMENT ON COLUMN people.name IS 'MASKED WITH FUNCTION anon.fake_last_name()';

=# COMMENT ON COLUMN people.phone IS 'MASKED WITH FUNCTION anon.partial(phone,2,$$******$$,2)';
```

STEP 4 : Connect with the masked user

```sql
=# \! psql test -U skynet -c 'SELECT * FROM people;'
  id  |   name   |   phone
------+----------+------------
 T800 | Nunziata | 06******11
(1 row)
```


Anonymous Dumps
------------------------------------------------------------------------------

Due to the core design of this extension, you cannot use `pg_dump` with a masked 
user. If you want to export the entire database with the anonymized data, you 
must use the `anon.dump()` function :

```console
$ psql [...] -qtA -c 'SELECT anon.dump()' your_dabatase > dump.sql
```

NB: The `-qtA` flags are required.


Warning
------------------------------------------------------------------------------

*This is projet is at an early stage of development and should used carefully.*

We need your feedback and ideas ! Let us know what you think of this tool,how it
fits your needs and what features are missing.

You can either [open an issue] or send a message at <contact@dalibo.com>.

[open an issue]: https://gitlab.com/daamien/postgresql_anonymizer/issues


Requirements
--------------------------------------------------------------------------------

This extension is officially supported on PostgreSQL 9.6 and later.
It should also work on PostgreSQL 9.5 with a bit of hacking.
See [NOTES.md](docs/NOTES.md) for more details.

It requires two extensions :

* [tsm_system_rows] which is delivered by the `postgresql-contrib` package of 
  the main linux distributions

* [ddlx] a very cool DDL extrator

[tsm_system_rows]: https://www.postgresql.org/docs/current/tsm-system-rows.html
[ddlx]: https://github.com/lacanoid/pgddl

Install
-------------------------------------------------------------------------------

Simply run :

```console
sudo pgxn install ddlx
sudo pgxn install postgresql_anonymizer
```

or see [INSTALL.md] for more detailed instructions or if you want to deploy it
on Amazon RDS or some other DBAAS service. 


Various Masking Strategies
------------------------------------------------------------------------------

Load the extension in your database like this:

```sql
CREATE EXTENSION IF NOT EXISTS anon CASCADE;
SELECT anon.load();
```

The `load()` function will charge a default dataset of random data ( lists
names, cities, etc. ). If you want to use your own dataset, you can load
custom CSV files with `load('/path/to/custom_cvs_files/')`

**You now have access to the following functions :**


### Noise

* anon.add_noise_on_numeric_column(table, column,ratio) if ratio = 0.33, all values
  of the column will be randomly shifted with a ratio of +/- 33%

* anon.add_noise_on_datetime_column(table, column,interval) if interval = '2 days', 
  all values of the column will be randomly shifted by +/- 2 days

### Shuffling 

* anon.shuffle_column(table, column) will rearrange all values in a given column


### Random values

* anon.random_date() returns a date
* anon.random_date_between(d1,d2) returns a date between `d1` and `d2`
* anon.random_int_between(i1,i2) returns an integer between `i1` and `i2`
* anon.random_string(n) returns a TEXT value containing `n` letters
* anon.random_zip() returns a 5-digit code
* anon.random_phone(p) return a 8-digit phone with `p` as a prefix

### Fake data

* anon.fake_first_name() returns a generic first name
* anon.fake_last_name() returns a generic last name
* anon.fake_email() returns a valid email address
* anon.fake_city() returns an existing city
* anon.fake_city_in_country(c) returns a city in country `c`
* anon.fake_region() returns an existing region
* anon.fake_region_in_country(c) returns a region in country `c`
* anon.fake_country() returns a country
* anon.fake_company() returns a generic company name
* anon.fake_iban() returns a valid IBAN
* anon.fake_siret() returns a valid SIRET
* anon.fake_siren() returns a valid SIREN

### Data types 

The faking functions will return values in `TEXT` data types. The random 
functions will return `TEXT`, `INTEGER` or `TIMESTAMP WITH TIMEZONE`. If the 
column you want to mask is in another data type (for instance `VARCHAR(30)`, 
then you need to add an explicit cast directly in the `COMMENT` declaration,
like this:

```sql
=# COMMENT ON COLUMN clients.family_name 
-# IS 'MASKED WITH FUNCTION anon.fake_last_name()::VARCHAR(30)';
```


Upgrade
------------------------------------------------------------------------------

Currently there's no way to upgrade easily from a version to another.
The operation `ALTER EXTENSION ... UPDATE ...` is not supported.

You need to drop and recreate the extension after every upgrade.



Limitations
------------------------------------------------------------------------------

* The masking are declared using the comments on columns. If you data model
  already contains comments on some columns, you must append the masking 
  rule after the original comment

* The dynamic masking system only works with one schema (by default `public`). 
  When you start the masking engine with `start_dynamic_masking()`, you can 
  specify the schema that will be masked with `SELECT start_dynamic_masking('sales');`. 
  **However** in-place anonymization with `anon.anonymize()`and anonymous
  export with `anon.dump()` will work fine will multiple schemas.



Performance
------------------------------------------------------------------------------

So far, we've done very few performance tests. Depending on the size of your
data set and number of columns your need to anonymize, you might end up with a
very slow process.

Here's some ideas :

### Sampling

If your need to anonymize data for testing purpose, chances are that a smaller
subset of your database will be enough. In that case, you can easily speed up
the anonymization by downsizing the volume of data. There are mulitple way to
extract a sample of database :

* [TABLESAMPLE](https://www.postgresql.org/docs/current/static/sql-select.html)
* [pg_sample](https://github.com/mla/pg_sample)



### Materialized Views

Dynamic masking is not always required ! In some cases, it is more efficient
to build [Materialized Views] instead.

For instance:

```SQL
CREATE MATERIALIZED VIEW masked_customer AS
SELECT
    id,
    anon.random_last_name() AS name,
    anon.random_date_between('01/01/1920'::DATE,now()) AS birth,
    fk_last_order,
    store_id
FROM customer;
```

[Materialized Views]: https://www.postgresql.org/docs/current/static/sql-creatematerializedview.html




Links
--------------------------------------------------------------------------------

* [Dynamic Data Masking With MS SQL Server](https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking)

* [Citus : Using search_path and views to hide columns for reporting with Postgres](https://www.citusdata.com/blog/2018/07/03/masking-columns-in-postgresql/)

* [MariaDB : Masking with maxscale](https://mariadb.com/kb/en/mariadb-enterprise/mariadb-maxscale-21-masking/)

* [Ultimate Guide to Data Anonymization](https://piwik.pro/blog/the-ultimate-guide-to-data-anonymization-in-analytics/)

* [UK ICO Anonymisation Code of Practice](https://ico.org.uk/media/1061/anonymisation-code.pdf)

* [L. Sweeney, Simple Demographics Often Identify People Uniquely, 2000](https://dataprivacylab.org/projects/identifiability/paper1.pdf)

* [How Google anonymizes data](https://policies.google.com/technologies/anonymization?hl=en)

* [IAPP's Guide To Anonymisation](https://iapp.org/media/pdf/resource_center/Guide_to_Anonymisation.pdf)

* [Differential_Privacy](https://en.wikipedia.org/wiki/Differential_Privacy)

* [K-Anonymity](https://en.wikipedia.org/wiki/K-anonymity)
