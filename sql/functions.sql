
--
-- Generic Types
--

CREATE OR REPLACE FUNCTION random_string(l integer)
RETURNS text AS $$ SELECT array_to_string(
			array(
				select substr('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',((random()*(36-1)+1)::integer),1) 
				from generate_series(1,l)
			),''
		  ); $$           
LANGUAGE SQL; 

-- Zip code 
CREATE OR REPLACE FUNCTION random_zip()                                                                                            
RETURNS text AS $$ SELECT array_to_string(                                                                                                             
            array(                                                                                                                                     
                select substr('0123456789',((random()*(10-1)+1)::integer),1)                                                 
                from generate_series(1,5)                                                                                                              
            ),''                                                                                                                                       
          ); $$                                                                                                                                        
LANGUAGE SQL; 


-- date

CREATE OR REPLACE FUNCTION random_date_between(date_start timestamp WITH TIME ZONE, date_end timestamp WITH TIME ZONE)
RETURNS timestamp WITH TIME ZONE AS $$
    SELECT (random()*(date_end-date_start))::interval+date_start;                                                                          
$$                                                                                                                                                     
LANGUAGE SQL; 

CREATE OR REPLACE FUNCTION random_date()
RETURNS timestamp with time zone AS $$
	SELECT @extschema@.random_date_between('01/01/1900'::DATE,now());
$$
LANGUAGE SQL;


-- integer

CREATE OR REPLACE FUNCTION random_int_between(int_start INTEGER, int_stop INTEGER)
RETURNS INTEGER AS $$
	SELECT CAST ( random()*(int_stop-int_start)+int_start AS INTEGER );
$$
LANGUAGE SQL;                                                                                                                                          

--
-- Personal data : First Name, Last Name, etc.
--

CREATE OR REPLACE FUNCTION random_first_name()
RETURNS TEXT AS $$
	SELECT first_name FROM @extschema@.first_names ORDER BY random() LIMIT 1; 
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION random_last_name()                                                                                                         
RETURNS TEXT AS $$                                                                                                                                     
    SELECT name FROM @extschema@.last_name ORDER BY random() LIMIT 1;                                                                          
$$                                                                                                                                                     
LANGUAGE SQL;    

CREATE OR REPLACE FUNCTION random_email()
RETURNS TEXT AS $$
	SELECT address FROM @extschema@.email ORDER BY random() LIMIT 1;
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION random_city_in_country(country_name TEXT)
RETURNS TEXT AS $$
	SELECT name FROM @extschema@.city WHERE country=country_name ORDER BY random() LIMIT 1;
$$
LANGUAGE SQL; 

CREATE OR REPLACE FUNCTION random_city()                                                                                   
RETURNS TEXT AS $$                                                                                                                                     
    SELECT name FROM @extschema@.city ORDER BY random() LIMIT 1;
$$                                                                                                                                                     
LANGUAGE SQL;                                                                                                                                          
               
CREATE OR REPLACE FUNCTION random_region_in_country(country_name TEXT) 
RETURNS TEXT AS $$                                                                                                                                     
    SELECT subcountry FROM @extschema@.city WHERE country=country_name ORDER BY random() LIMIT 1;
$$                                                                                                                                                     
LANGUAGE SQL;                                                                                                                                          
                                                                                                                                                       
CREATE OR REPLACE FUNCTION random_region()
RETURNS TEXT AS $$                                                                                                                                     
    SELECT subcountry FROM @extschema@.city ORDER BY random() LIMIT 1;
$$                                                                                                                                                     
LANGUAGE SQL;   

CREATE OR REPLACE FUNCTION random_country()                                                                                                               
RETURNS TEXT AS $$                                                                                                                                     
    SELECT country FROM @extschema@.city ORDER BY random() LIMIT 1;
$$                                                                                                                                                     
LANGUAGE SQL;   


CREATE OR REPLACE FUNCTION random_phone( phone_prefix TEXT DEFAULT '0' )
RETURNS TEXT AS $$
	SELECT phone_prefix || CAST(@extschema@.random_int_between(100000000,999999999) AS TEXT) AS "phone";
$$
LANGUAGE SQL;


--
-- Company data : Name, SIRET, IBAN, etc.
--

CREATE OR REPLACE FUNCTION random_company()                                                                                                         
RETURNS TEXT AS $$                                                                                                                                     
    SELECT name FROM @extschema@.companies ORDER BY random() LIMIT 1;                                                                          
$$                                                                                                                                                     
LANGUAGE SQL; 
