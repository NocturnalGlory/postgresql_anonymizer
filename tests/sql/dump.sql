-- this test must be run on a database named 'contrib_regression'
CREATE EXTENSION IF NOT EXISTS anon CASCADE;

-- INIT

SELECT anon.load();

CREATE TABLE cards (
  id integer NOT NULL,
  board_id integer NOT NULL,
  data TEXT 
);

INSERT INTO cards VALUES (1, 1, 'Paint house');
INSERT INTO cards VALUES (2, 1, 'Clean');
INSERT INTO cards VALUES (3, 1, 'Cook');
INSERT INTO cards VALUES (4, 1, 'Vacuum');
INSERT INTO cards VALUES (999999,0, E'(,Very"Weird\'\'value\t trying\n to\,break '' CSV\)export)');

CREATE TABLE customer (
	id SERIAL,
	name TEXT,
	"CreditCard" TEXT
);

INSERT INTO customer
VALUES (1,'Schwarzenegger','1234567812345678');

COMMENT ON COLUMN customer.name 
IS E'MASKED WITH FUNCTION md5(''0'') ';

COMMENT ON COLUMN customer."CreditCard" 
IS E'MASKED WITH FUNCTION md5(''0'') ';

CREATE TABLE "COMPANY" (
	rn SERIAL,
	"IBAN" TEXT,
	BRAND TEXT
);

INSERT INTO "COMPANY"
VALUES (1991,'12345677890','Cyberdyne Systems');

COMMENT ON COLUMN "COMPANY"."IBAN" 
IS E'MASKED WITH FUNCTION md5(''0'') ';

COMMENT ON COLUMN "COMPANY".brand 
IS E'MASKED WITH FUNCTION md5(''0'')';

-- 0. basic test : call the dump function
SELECT count(d) FROM anon.dump() AS d;

-- 1. Dump into a file
\! psql -q -t -A -c 'SELECT anon.dump()' contrib_regression > _dump1.sql

-- 2. Clean the database and Restore with the dump file
DROP TABLE cards CASCADE;
DROP TABLE customer CASCADE;
DROP TABLE "COMPANY" CASCADE;

-- output will vary a lot between PG versions
-- So have to disable it to pass this test
\! psql -f _dump1.sql contrib_regression >/dev/null

-- 3. Dump again into a second file
\! psql -t -A -c 'SELECT anon.dump()' contrib_regression > _dump2.sql


-- 4. Check that both dump files are identical
\! diff _dump1.sql _dump2.sql

--  CLEAN

DROP TABLE "COMPANY" CASCADE;
DROP TABLE customer CASCADE;
DROP TABLE cards CASCADE;

DROP EXTENSION anon CASCADE;
