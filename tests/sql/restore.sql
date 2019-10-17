

CREATE DATABASE contrib_regression_test_restore;

\! psql contrib_regression_test_restore -c 'CREATE EXTENSION anon CASCADE;'
\! psql contrib_regression_test_restore -c 'SELECT anon.start_dynamic_masking();'
\! pg_dump -Fc contrib_regression_test_restore > contrib_regression_test_restore.pgsql

DROP DATABASE contrib_regression_test_restore;

\! pg_restore -d postgres --role=postgres -C contrib_regression_test_restore.pgsql

DROP DATABASE contrib_regression_test_restore;
