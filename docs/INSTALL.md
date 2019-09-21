INSTALL
===============================================================================

Install With [PGXN](https://pgxn.org/) :
------------------------------------------------------------------------------

**This is the recommended way to install the extension**

1. Install the extension on the server with:

```console
sudo apt install pgxnclient (or pip install pgxn)
sudo pgxn install ddlx
sudo pgxn install postgresql_anonymizer
```

2. Add 'anon' in the `shared_preload_libraries` parameter of you `postgresql.conf` file. For example:

```
shared_preload_libraries = 'pg_stat_statements, anon'
```

3. Restart your instance. 



Install From source
------------------------------------------------------------------------------

0. First you need to install the postgresql development libraries. On most
distribution, this is available through a package called `postgresql-devel`
or `postgresql-server-dev`.

1. Build the project like any other PostgreSQL extension:

```console
make extension
sudo make install
```

2. Add 'anon' in the `shared_preload_libraries` parameter of you `postgresql.conf` file. For example:

```
shared_preload_libraries = 'pg_stat_statements, anon'
```

3. Restart your instance. 


Install in the cloud
------------------------------------------------------------------------------

Generally Database As A Service operators ( such as Amazon RDS ) do not allow their
clients to load any extension. Instead they support only a limited subset of
extensions, such as PostGIS or pgcrypto. You can ask them if they plan to support
this one in the near future, but I wouldn't bet my life on it 😃

However this tool is set of plpgsql functions, which means should you be able to
install it directly without declaring an extension.

Here's a few steps to try it out:

```console
$ git clone https://gitlab.com/dalibo/postgresql_anonymizer.git
$ make standalone
$ psql ..... -f anon_standalone_PG11.sql
```

_NB_ : Replace `PG11` with the version of Postgres offered by your DBaaS operator.


When you activate the masking engine, you need to disable `autoload`:

```sql
SELECT anon.start_dynamic_masking( autoload := FALSE );
```


> **However** if privacy and anonymity are a concern to you, hosting your data on 
> someone else's computer is probably not a clever idea....
