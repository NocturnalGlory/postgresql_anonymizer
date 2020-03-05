Anonymous Dumps
===============================================================================

Due to the core design of this extension, you cannot use `pg_dump` with a masked 
user. If you want to export the entire database with the anonymized data, you 
must use the `pg_dump_anon` command.


pg_dump_anon
------------------------------------------------------------------------------

The `pg_dump_anon` wrapper is designed to export the masked data. You can use 
it like the regular `pg_dump` command.

```bash
$ pg_dump_anon -h localhost -U bob mydb > anonymous_dump.sql
```

It uses the same connections parameters that `pg_dump` :

```bash
$ pg_dump_anon --help

Usage: pg_dump_anon [OPTION]... [DBNAME]

General options:
  -f, --file=FILENAME           output file
  --help                        display this message

Options controlling the output content:
  -n, --schema=PATTERN          dump the specified schema(s) only
  -N, --exclude-schema=PATTERN  do NOT dump the specified schema(s)
  -t, --table=PATTERN           dump the specified table(s) only
  -T, --exclude-table=PATTERN   do NOT dump the specified table(s)
  --exclude-table-data=PATTERN  do NOT dump data for the specified table(s)

Connection options:
  -d, --dbname=DBNAME           database to dump
  -h, --host=HOSTNAME           database server host or socket directory
  -p, --port=PORT               database server port number
  -U, --username=NAME           connect as specified database user
  -w, --no-password             never prompt for password
  -W, --password                force password prompt (should happen automatically)

If no database name is supplied, then the PGDATABASE environment
variable value is used.

```


* The [PostgreSQL environement variables] ($PGHOST, PGUSER, etc.) are supported. 
* The [.pgpass] file is also supported.
* The `plain` format is the only supported format. The other formats (`custom`, `dir`
  and `tar`) are not supported

[PostgreSQL environement variables]: https://www.postgresql.org/docs/current/libpq-envars.html
[.pgpass]: https://www.postgresql.org/docs/current/libpq-pgpass.html



DEPRECATED: DO NOT USE anon.dump()
------------------------------------------------------------------------------

The version 0.3 of PostgreSQL Anonymizer introduced a function called 
`anon.dump()`. This function is extremely slow. Since version 0.6, it has 
been deprecated and it is not supported anymore.

The function is kept as is for backward compatibility. It will be probably be
remove from one ogf the forthcoming versions.

Again: do not use this function ! To dump the masked data, use the 
`pg_dump_anon` command line tool as described above.
