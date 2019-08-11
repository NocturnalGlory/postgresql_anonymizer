Various Masking Strategies
==============================================================================

The extension provides functions to implement 4 main anonymization strategies:

* Adding Noise
* Shuffling
* Randomization
* Faking

Depending on your data, you may need to use different strategies on different
columns :

* For names and other 'direct identifiers' , faking is often usefull
* Shuffling is convienient for foreign keys
* Adding noise is interesting for numeric values and dates
* etc.



Adding Noise
------------------------------------------------------------------------------

* anon.add_noise_on_numeric_column(table, column,ratio) if ratio = 0.33, all 
  values of the column will be randomly shifted with a ratio of +/- 33%

* anon.add_noise_on_datetime_column(table, column,interval) if interval = '2 days', 
  all values of the column will be randomly shifted by +/- 2 days


Shuffling 
------------------------------------------------------------------------------

* anon.shuffle_column(shuffle_table, shuffle_column, primary_key) will rearrange 
  all values in a given column. You need to provide a primary key of the table.
  This is usefull for foreign keys because referential integrity will be kept.


Randomization
------------------------------------------------------------------------------

* anon.random_date() returns a date
* anon.random_date_between(d1,d2) returns a date between `d1` and `d2`
* anon.random_int_between(i1,i2) returns an integer between `i1` and `i2`
* anon.random_string(n) returns a TEXT value containing `n` letters
* anon.random_zip() returns a 5-digit code
* anon.random_phone(p) return a 8-digit phone with `p` as a prefix

Faking
------------------------------------------------------------------------------

In order to use the faking functions, you have to `load()` the extension 
in your database first:

```sql
SELECT anon.load();
```
The `load()` function will charge a default dataset of random data ( lists
names, cities, etc. ). If you want to use your own dataset, you can load
custom CSV files with `load('/path/to/custom_cvs_files/')`

Once the fake data is loaded you have access to 12 faking functions:

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



Data Types Conversion
------------------------------------------------------------------------------

The faking functions will return values in `TEXT` data types. The random 
functions will return `TEXT`, `INTEGER` or `TIMESTAMP WITH TIMEZONE`. 

If the column you want to mask is in another data type (for instance `VARCHAR(30)`, 
then you need to add an explicit cast directly in the `COMMENT` declaration,
like this:

```sql
=# COMMENT ON COLUMN clients.family_name 
-# IS 'MASKED WITH FUNCTION anon.fake_last_name()::VARCHAR(30)';
```