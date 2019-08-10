
-- STEP 1 : Basic Example 

CREATE TABLE customer(
	id SERIAL,
	full_name TEXT,
	birth DATE,
	employer TEXT,
	zipcode TEXT,
	fk_shop INTEGER
);

INSERT INTO customer
VALUES 
(911,'Chuck Norris','1940/03/10','Texas Rangers', '75001',12),
(312,'David Hasselhoff','1952/07/17','Baywatch', '90001',423)
;

SELECT * FROM customer;

-- STEP 2: Load the extension 

CREATE EXTENSION IF NOT EXISTS anon CASCADE;

SELECT anon.load();

-- STEP 3: Declare the masking rules

COMMENT ON COLUMN customer.full_name 
IS 'MASKED WITH FUNCTION anon.fake_first_name() || '' '' || anon.fake_last_name()';

COMMENT ON COLUMN customer.birth   
IS 'MASKED WITH FUNCTION anon.random_date_between(''01/01/1920''::DATE,now())::DATE';

COMMENT ON COLUMN customer.employer
IS 'MASKED WITH FUNCTION anon.fake_company()';

COMMENT ON COLUMN customer.zipcode
IS 'MASKED WITH FUNCTION anon.random_zip()';

-- STEP 4: Replace Sensitive Data 

SELECT anon.anonymize_database();

SELECT * FROM customer;
