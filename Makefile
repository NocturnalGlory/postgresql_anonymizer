###############################################################################
#
# Makefile
#
###############################################################################

##
## V A R I A B L E S
##

# This Makefile has many input variables,
# see link below for the standard vars offered by PGXS
# https://www.postgresql.org/docs/current/extend-pgxs.html

# The input variable below are optional

# PSQL : psql client ( default = local psql )
# PGDUMP : pg_dump tool  ( default = docker )
# REGRESS : run a specific test ( e.g. `REGRESS=noise make installcheck` )
# PG_TEST_EXTRA : extra tests to be run by `installcheck` ( default = none )

##
## C O N F I G
##
MODULES = anon
EXTENSION = anon
EXTENSION_VERSION=$(shell grep default_version $(EXTENSION).control | sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/")
DATA = anon/*
# Use this var to add more tests
#PG_TEST_EXTRA ?= ""
REGRESS_TESTS = load destruction noise shuffle random faking partial
REGRESS_TESTS+= anonymize dump restore
REGRESS_TESTS+= hasmask masked_roles masking
REGRESS_TESTS+= generalization k_anonymity
REGRESS_TESTS+= injection conflict_seclabel_vs_comment syntax_checks
REGRESS_TESTS+= issue117
REGRESS_TESTS+=$(PG_TEST_EXTRA)
# This can be overridden by an env variable
REGRESS?=$(REGRESS_TESTS)
MODULEDIR=extension/anon
REGRESS_OPTS = --inputdir=tests

OBJS = anon.o

##
## Mandatory PGXS stuff
##
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

all: extension


##
## H E L P
##

#	@echo "Available targets for $(MODULE) $(EXTENSION_VERSION):"

default:: help

help::  #: display this message.
	@echo
	@echo "Available targets for $(EXTENSION) $(EXTENSION_VERSION):"
	@echo
	@gawk 'match($$0, /([^:]*):.+#'': (.*)/, m) { printf "    %-16s%s\n", m[1], m[2]}' $(MAKEFILE_LIST) | sort
	@echo




##
## B U I L D
##


.PHONY: extension
extension: #: build the extension
	mkdir -p anon
	cp anon.sql anon/anon--$(EXTENSION_VERSION).sql
	cp data/default/* anon/

PG_DUMP?=docker exec postgresqlanonymizer_PostgreSQL_1 pg_dump -U postgres --insert --no-owner
SED1=sed 's/public.//'
SED2=sed 's/SELECT.*search_path.*//'
SED3=sed 's/^SET idle_in_transaction_session_timeout.*//'
SED4=sed 's/^SET row_security.*//'
SEDI=$(shell sed --version >/dev/null 2>&1 && echo 'sed -i --' || echo 'sed -i ""')


sql/tables/%.sql:
	$(PG_DUMP) --table $* | $(SED1) | $(SED2) | $(SED3) | $(SED4) > $@


PSQL?=PGPASSWORD=CHANGEME psql -U postgres -h 0.0.0.0 -p54322
PGRGRSS=docker exec postgresqlanonymizer_PostgreSQL_1 /usr/lib/postgresql/10/lib/pgxs/src/test/regress/pg_regress --outputdir=tests/ --inputdir=./ --bindir='/usr/lib/postgresql/10/bin'  --inputdir=tests --dbname=contrib_regression --user=postgres unit

##
## D O C K E R
##

docker_image: docker/Dockerfile #: build the docker image
	docker build -t registry.gitlab.com/dalibo/postgresql_anonymizer . --file $^

docker_push: #: push the docker image to the registry
	docker push registry.gitlab.com/dalibo/postgresql_anonymizer

docker_bash: #: enter the docker image (useful for testing)
	docker exec -it docker_PostgreSQL_1 bash

COMPOSE=docker-compose --file docker/docker-compose.yml

docker_init: #: start a docker container
	$(COMPOSE) down
	$(COMPOSE) up -d
	@echo "The Postgres server may take a few seconds to start. Please wait."


.PHONY: expected
expected : tests/expected/unit.out

tests/expected/unit.out:
	$(PGRGRSS)
	cp tests/results/unit.out tests/expected/unit.out

##
## S T A N D A L O N E
##

STD_ARTEFACTS=anon_standalone_PG96.sql
STD_ARTEFACTS+=anon_standalone_PG10.sql
STD_ARTEFACTS+=anon_standalone_PG11.sql
STD_ARTEFACTS+=anon_standalone_PG12.sql

anon_standalone_PG96.sql: VERSION = 9.6.0
anon_standalone_PG10.sql: VERSION = 10.0
anon_standalone_PG11.sql: VERSION = 11.0
anon_standalone_PG12.sql: VERSION = 12.0

standalone: $(STD_ARTEFACTS) # build the standalone scripts

$(STD_ARTEFACTS): anon.sql | _pgddl
	echo 'CREATE EXTENSION IF NOT EXISTS tsm_system_rows;\n' > $@
	VERSION=$(VERSION) _pgddl/bin/pgsqlpp _pgddl/ddlx.sql >> $@
	echo 'CREATE SCHEMA anon;\n' >> $@
	sed 's/@extschema@/anon/g' anon.sql >> $@
	$(SEDI) 's/^SELECT pg_catalog.pg_extension_config_dump(.*//' $@
	echo "\copy anon.city FROM 'data/default/city.csv';\n" >> $@
	echo "\copy anon.company FROM 'data/default/company.csv';\n" >> $@
	echo "\copy anon.email FROM 'data/default/email.csv';\n" >> $@
	echo "\copy anon.first_name FROM 'data/default/first_name.csv';\n" >> $@
	echo "\copy anon.iban FROM 'data/default/iban.csv';\n" >> $@
	echo "\copy anon.last_name FROM 'data/default/last_name.csv';\n" >> $@
	echo "\copy anon.siret FROM 'data/default/siret.csv';\n" >> $@

_pgddl: # fetch the pgddl extension
	-git clone https://github.com/lacanoid/pgddl.git $@

clean_standalone:
	rm -fr $(STD_ARTEFACTS)
	rm -fr _pgddl

##
## L O A D
##

.PHONY: load
load: #: Load data from CSV files into SQL tables
	$(PSQL) -f data/load.sql

##
## D E M O   &   T E S T S
##

#.PHONY: demo_masking demo_perf demo_random demo_partial

demo_in := $(wildcard demo/*.sql)
demo_out = $(demo_in:.sql=.out)

.PHONY: demo
demo:: $(demo_out) demo_blackbox #: launch the demo scripts

demo/%.out: demo/%.sql
	$(PSQL) -c 'CREATE DATABASE demo;'
	$(PSQL) --echo-all demo < $^ > $@ 2>&1
	$(PSQL) -c 'DROP DATABASE demo;'
	cat $@

demo_blackbox:
	./demo/blackbox.sh

clean_demo:
	rm $(demo_out)

tests/sql/%.sql:
	$(PSQL)	-f $@


##
## C I
##

.PHONY: ci_local
ci_local:
	gitlab-ci-multi-runner exec docker make

##
## P G X N
##

ZIPBALL:=$(EXTENSION)-$(EXTENSION_VERSION).zip

.PHONY: pgxn

$(ZIPBALL): pgxn

pgxn: #: build the PGXN package
	# required by CI : https://gitlab.com/gitlab-com/support-forum/issues/1351
	git clone --bare https://gitlab.com/dalibo/postgresql_anonymizer.git
	git -C postgresql_anonymizer.git archive --format zip --prefix=$(EXTENSION)_$(EXTENSION_VERSION)/ --output ../$(ZIPBALL) master
	# open the package
	unzip $(ZIPBALL)
	# remove the zipball because we will rebuild it from scratch
	rm -fr $(ZIPBALL)
	# copy artefact into the package
	cp -pr anon ./$(EXTENSION)_$(EXTENSION_VERSION)/
	# remove folders and files that are useless in the PGXN package
	rm -fr ./$(EXTENSION)_$(EXTENSION_VERSION)/images
	rm -fr ./$(EXTENSION)_$(EXTENSION_VERSION)/docker
	rm -fr ./$(EXTENSION)_$(EXTENSION_VERSION)/docs
	# rebuild the package
	zip -r $(ZIPBALL) ./$(EXTENSION)_$(EXTENSION_VERSION)/
	# clean up
	rm -fr ./$(EXTENSION)_$(EXTENSION_VERSION) ./postgresql_anonymizer.git/


