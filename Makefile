EXTENSION = anon
VERSION=0.0.3
#DATA = anon/anon--0.0.3.sql
DATA = anon/*
REGRESS=unit
MODULEDIR=extension/anon
REGRESS_OPTS = --inputdir=tests

.PHONY: extension
extension: 
	mkdir -p anon 
	cat anon.sql > anon/anon--$(VERSION).sql
	cp data/default/* anon/

PG_DUMP?=docker exec postgresqlanonymizer_PostgreSQL_1 pg_dump -U postgres --insert --no-owner 
SED1=sed 's/public.//' 
SED2=sed 's/SELECT.*search_path.*//' 
SED3=sed 's/^SET idle_in_transaction_session_timeout.*//'
SED4=sed 's/^SET row_security.*//'

sql/tables/%.sql:
	$(PG_DUMP) --table $* | $(SED1) | $(SED2) | $(SED3) | $(SED4) > $@


PSQL?=PGPASSWORD=CHANGEME psql -U postgres -h 0.0.0.0 -p54322
PGRGRSS=docker exec postgresqlanonymizer_PostgreSQL_1 /usr/lib/postgresql/10/lib/pgxs/src/test/regress/pg_regress --outputdir=tests/ --inputdir=./ --bindir='/usr/lib/postgresql/10/bin'  --inputdir=tests --dbname=contrib_regression --user=postgres unit

##
## Docker
##

docker_image: Dockerfile
	docker build -t registry.gitlab.com/daamien/postgresql_anonymizer .

docker_push:
	docker push registry.gitlab.com/daamien/postgresql_anonymizer

docker_bash:
	docker exec -it postgresqlanonymizer_PostgreSQL_1 bash

COMPOSE=docker-compose

docker_init:
	$(COMPOSE) down
	$(COMPOSE) up -d
	@echo "The Postgres server may take a few seconds to start. Please wait."


.PHONY: expected
expected : tests/expected/unit.out

tests/expected/unit.out:
	$(PGRGRSS)
	cp tests/results/unit.out tests/expected/unit.out

##
## Load data from CSV files into SQL tables
##

.PHONY: load
load:
	$(PSQL) -f data/load.sql

##
## Tests
##
test_unit: tests/sql/unit.sql
test_demo: tests/sql/demo.sql
test_create: tests/sql/create.sql
test_drop: tests/sql/drop.sql

tests/sql/%.sql:
	$(PSQL)	-f $@


##
## CI
##

.PHONY: ci_local
ci_local:
	gitlab-ci-multi-runner exec docker make

##
## PGXN
##

ZIPBALL:=$(EXTENSION)-$(VERSION).zip

.PHONY: pgxn

$(ZIPBALL): pgxn

pgxn:
	mkdir -p _pgxn
	# required by CI : https://gitlab.com/gitlab-com/support-forum/issues/1351
	git clone --bare https://gitlab.com/daamien/postgresql_anonymizer.git
	git -C postgresql_anonymizer.git archive --format zip --prefix=$(EXTENSION)_$(VERSION)/ --output ../$(ZIPBALL) master
	# open the package
	unzip $(ZIPBALL) $(EXTENSION)_$(VERSION)/
	# copy artefact into the package
	cp -pr anon ./$(EXTENSION)_$(VERSION)/
	# rebuild the package
	zip -r $(ZIPBALL) ./$(EXTENSION)_$(VERSION)/
	# clean up
	rm -fr ./$(EXTENSION)_$(VERSION) ./postgresql_anonymizer.git/


##
## Mandatory PGXS stuff
##
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
