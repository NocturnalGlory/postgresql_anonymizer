#!/bin/bash
#
#    pg_dump_anon
#    A basic wrapper to export anonymized data with pg_dump and psql
#
#    This is work in progress. Use with care.
#
#

usage()
{
  echo "Usage: $(basename $0) [OPTION]... [DBNAME]"
  echo
  echo "Connection options:"
  echo
  echo "-d, --dbname=DBNAME      database to dump"
  echo "-h, --host=HOSTNAME      database server host or socket directory"
  echo "-p, --port=PORT          database server port number"
  echo "-U, --username=NAME      connect as specified database user"
  echo "-w, --no-password        never prompt for password"
  echo "-W, --password           force password prompt (should happen automatically)"
  echo "--role=ROLENAME          do SET ROLE before dump"
}


# TODO filter out the pg_dump args that are no supported by psql
PSQL="psql $@ --quiet --tuples-only --no-align"

get_anon_version() {
$PSQL << EOSQL
  SELECT extversion FROM pg_catalog.pg_extension WHERE extname='anon';
EOSQL
}

## Return the table name based on the relid
get_table_name() {
$PSQL << EOSQL
  SET search_path = '';
  SELECT $1::REGCLASS;
EOSQL
}

## Return the masking filters based on the relid
get_mask_filters() {
$PSQL << EOSQL
  SELECT anon.mask_filters($1);
EOSQL
}


## generate the "COPY ... FROM STDIN" statement for a given table
print_copy_statement () {
  table_name=$(get_table_name $1)
  filters=$(get_mask_filters $1)
  echo COPY $table_name FROM STDIN WITH CSV';'
  $PSQL -c "\copy (SELECT $filters FROM $table_name) TO STDOUT WITH CSV"
  echo \\.
  echo
}

## Return the relid of each user table
list_user_tables() {
$PSQL << EOSQL
  SELECT relid
  FROM pg_stat_user_tables
  WHERE schemaname NOT IN ( 'anon' , anon.mask_schema() )
  ORDER BY  relid::regclass -- sort by name to force the dump order
EOSQL
}

##
## M A I N
##

## Checks options
options=$(getopt -o ? --long help -- "$@")
eval set -- "$options"
#while true; do
#    case "$1" in
#    --help)
#        usage
#        exit 0
#        ;;
#    esac
#    shift
#done

## Stop if the extension is not installed in the database
version=$(get_anon_version)
if [ -z "$version" ]
then
  echo 'Anon extension is not installed in this database.'
  exit 1
fi

## Header

## Dump the DDL
pg_dump --schema-only "$@"

## Dump the Masking Views instead of the real data
list_user_tables | while read -a record ; do
  print_copy_statement ${record[0]}
done

