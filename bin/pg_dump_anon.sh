#!/bin/bash


# TODO intercept the --help arg

# TODO filter out the pg_dump args that are no supported by psql
PSQL="psql $@ --quiet --tuples-only --no-align"

# TODO stop if the extension is not installed in the database

## Return the table name based on the relid
get_table_name() {
$PSQL << EOSQL
  SET search_path = '';
  SELECT $1::REGCLASS;
EOSQL
}

## Return the masking filters based on the relid
get_mask_filters(){
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

## Dump the DDL
pg_dump --schema-only "$@"

## Dump the Masking Views instead of the real data
list_user_tables | while read -a record ; do
  print_copy_statement ${record[0]}
done

