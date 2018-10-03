
BEGIN;

CREATE UNLOGGED TABLE t1 (
	id SERIAL,
	credit_card TEXT
);

CREATE UNLOGGED TABLE t2 (
    id SERIAL,
    credit_card TEXT
);

INSERT INTO t1("credit_card")
VALUES
('5467909664060024'),
('2346657632423434'),
('5897577324346790')
;

CREATE RULE "_RETURN" AS
ON SELECT TO t2
DO INSTEAD
	WITH anon AS (TABLE t1)
   	SELECT
		id,
		'xxx' AS credit_card
	FROM  anon
;

SELECT * FROM t2;