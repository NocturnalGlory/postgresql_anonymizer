Put on your Masks !
===============================================================================

The main idea of this extension is to offer **anonymization by design**.

The data masking rules should be written by the people who develop the 
application because they have the best knowledge of how the data model works.
Therefore masking rules must be implemented directly inside the database schema.

This allows to mask the data directly inside the PostgreSQL instance without 
using an external tool and thus limiting the exposure and the risks of data leak.

The data masking rules are declared simply by using [security labels]:

[security labels]: https://www.postgresql.org/docs/current/sql-security-label.html

<!-- demo/declare_masking_rules.sql -->

```sql
CREATE EXTENSION IF NOT EXISTS anon CASCADE;

SELECT anon.load();

CREATE TABLE player( id SERIAL, name TEXT, points INT);

INSERT INTO player VALUES  
  ( 1, 'Kareem Abdul-Jabbar',	38387),
  ( 5, 'Michael Jordan', 32292 );

SECURITY LABEL FOR anon ON COLUMN player.name 
  IS 'MASKED WITH FUNCTION anon.fake_last_name()';

SECURITY LABEL FOR anon ON COLUMN player.id
  IS 'MASKED WITH VALUE NULL';
```

Removing a masking rule
------------------------------------------------------------------------------

You can simply erase a masking rule like this: 

```sql
SECURITY LABEL FOR anon ON COLUMN player.name IS NULL
```

Declaring Rules with COMMENTs 
------------------------------------------------------------------------------

There is an alternative way for declaring masking rules, using the 
COMMENT syntax :

```sql
COMMENT ON COLUMN player.name 
IS 'MASKED WITH FUNCTION anon.fake_last_name()'
```

This is useful especially if you can't modify the instance confiraguration and 
load the extension with `session_preload_libraries`. In this situation, the 
security labels won't work and you have to declare rules with comments.

See also [Install in the Cloud].

[Install in the Cloud]: INSTALL.md#install-in-the-cloud 

Data Type Conversion
------------------------------------------------------------------------------

The various masking functions will return a certain data types. For instance:

* the faking functions (e.g.`fake_email()`) will return values in `TEXT` data 
  types
* the random functions will return `TEXT`, `INTEGER` 
   or `TIMESTAMP WITH TIMEZONE`
* etc.

If the column you want to mask is in another data type (for instance 
`VARCHAR(30)`) then you need to add an explicit cast directly in the masking 
rule declaration, like this:

```sql
=# SECURITY LABEL FOR anon ON COLUMN clients.family_name 
-# IS 'MASKED WITH FUNCTION anon.fake_last_name()::VARCHAR(30)';
```


Limitations
------------------------------------------------------------------------------

If your columns already have comments, simply append the `MASKED WITH FUNCTION` 
statement at the end of the comment.

