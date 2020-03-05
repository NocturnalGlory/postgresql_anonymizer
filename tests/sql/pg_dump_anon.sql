-- this test must be run on a database named 'contrib_regression'
CREATE EXTENSION IF NOT EXISTS anon CASCADE;

-- INIT

SELECT anon.load();

CREATE SCHEMA test_pg_dump_anon;

CREATE TABLE test_pg_dump_anon.no_masks AS SELECT 1 ;

CREATE TABLE test_pg_dump_anon.cards (
  id integer NOT NULL,
  board_id integer NOT NULL,
  data TEXT
);

INSERT INTO test_pg_dump_anon.cards VALUES
(1, 1, 'Paint house'),
(2, 1, 'Clean'),
(3, 1, 'Cook'),
(4, 1, 'Vacuum'),
(999999,0, E'(,Very"Weird\'\'value\t trying\n to\,break '' CSV\)export)');

CREATE TABLE test_pg_dump_anon.customer (
  id SERIAL,
  name TEXT,
  "CreditCard" TEXT
);

INSERT INTO test_pg_dump_anon.customer
VALUES (1,'Schwarzenegger','1234567812345678');

SECURITY LABEL FOR anon ON COLUMN test_pg_dump_anon.customer.name
IS E'MASKED WITH FUNCTION md5(''0'') ';

SECURITY LABEL FOR anon ON COLUMN test_pg_dump_anon.customer."CreditCard"
IS E'MASKED WITH FUNCTION md5(''0'') ';

CREATE TABLE test_pg_dump_anon."COMPANY" (
  rn SERIAL,
  "IBAN" TEXT,
  BRAND TEXT
);

INSERT INTO test_pg_dump_anon."COMPANY"
VALUES (1991,'12345677890','Cyberdyne Systems');

SECURITY LABEL FOR anon ON COLUMN test_pg_dump_anon."COMPANY"."IBAN"
IS E'MASKED WITH FUNCTION md5(''0'') ';

SECURITY LABEL FOR anon ON COLUMN test_pg_dump_anon."COMPANY".brand
IS E'MASKED WITH FUNCTION md5(''0'')';

CREATE SCHEMA "FoO";

CREATE TABLE "FoO".customer (
  id SERIAL,
  firstname TEXT,
  last_name TEXT,
  "CreditCard" TEXT
);
INSERT INTO "FoO".customer
VALUES (0,'bob', 'doe', '1234-5678-1234-5678');

CREATE TABLE "FoO".vendor (
  employee_id INTEGER UNIQUE,
  "Firstname" TEXT,
  lastname TEXT,
  phone_number TEXT,
  birth DATE
);
INSERT INTO "FoO".vendor
VALUES (1,'John', 'Hamm', NULL, '0001-01-01');


CREATE TABLE "FoO".vendeur (
  identifiant INTEGER UNIQUE,
  "Prenom" TEXT,
  nom TEXT,
  telephone TEXT,
  date_naissance DATE
);

INSERT INTO "FoO".vendeur
VALUES (1,'Jean', 'Bon', NULL, '0001-01-01');

--
-- A. Dump and Restore and Dump again and compare
--

-- A1. Dump into a file
\! pg_dump_anon --dbname=contrib_regression > tests/tmp/_pg_dump_anon_A1.sql

-- A2. Clean up the database
DROP SCHEMA test_pg_dump_anon CASCADE;
DROP SCHEMA "FoO" CASCADE;

-- A3. Restore with the dump file
-- output will vary a lot between PG versions
-- So have to disable it to pass this test
\! psql -f tests/tmp/_pg_dump_anon_A1.sql contrib_regression >/dev/null

-- A4. Dump again into a second file
-- /!\ This time the masking rules are not applied !
\! pg_dump_anon -d contrib_regression > tests/tmp/_pg_dump_anon_A4.sql


-- A5. Check that both dump files are identical
-- ignore the plpgsql error on PG10 and PG9.6
\! diff tests/tmp/_pg_dump_anon_A1.sql tests/tmp/_pg_dump_anon_A4.sql


--
-- B. Exclude some schemas
-- All this tests should not return anything
--

\! pg_dump_anon contrib_regression --exclude-schema='"FoO"' -N z | grep 'FoO'

\! pg_dump_anon contrib_regression --schema=pub* -n test_pg_dump_anon |grep 'FoO'

--
-- C. Exclude some tables
-- All these command lines should produce the same output
--
\! pg_dump_anon contrib_regression --table=test_pg_dump_anon.* | grep "vendor"

\! pg_dump_anon contrib_regression -t test_pg_dump_anon.no_masks | grep 'vendor'

\! pg_dump_anon contrib_regression -t test_pg_dump_anon."c*" | grep 'vendor'

\! pg_dump_anon contrib_regression -t test_pg_dump_anon."c*" | grep 'vendor'

\! pg_dump_anon contrib_regression --exclude-table='"FoO".*' | grep 'vendor'

\! pg_dump_anon contrib_regression -T '"FoO".v?nd*r' | grep 'vendor'

--
-- D. Exclude data
--
\! pg_dump_anon contrib_regression --exclude-data=v?nd?r | grep 'Hamm'

--
-- E. Remove Anon extension
-- All these command lines should produce the same output
--
\! pg_dump_anon contrib_regression | grep 'ddlx'


--  CLEAN
DROP SCHEMA test_pg_dump_anon CASCADE;
DROP SCHEMA "FoO" CASCADE;
DROP EXTENSION anon CASCADE;

