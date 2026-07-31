.. _database_connections:

Database connections
====================

XLTable connects directly to analytical databases and executes SQL queries
on their side. All database connections are defined centrally in the
``settings.json`` file and reused across OLAP cubes.

Currently supported connection types (each one has a ready-to-run sample
dataset — see the **Sample data** section):

- ClickHouse (starting from version 22.5)
- BigQuery
- Snowflake
- Trino
- StarRocks
- Databricks
- Greenplum
- DuckDB

For each database type, the corresponding configuration section must be
defined in ``settings.json``.

.. note::

   To connect to the database, a single service account with **read-only** access is sufficient.
   XLTable uses this account for all queries; no write permissions are required.

All connection types accept an optional ``query_timeout`` parameter in
``CREDENTIAL_DB`` — the maximum execution time of a single database query in
seconds (default: 60). A query running longer than this is cancelled and an
error is returned to Excel instead of holding the connection indefinitely.

ClickHouse
----------

Example structure for ClickHouse connection:

.. code-block:: json

   "SERVER_DB": "ClickHouse",
    "CREDENTIAL_DB": {
        "user": "...",
        "password": "...",
        "host": "...",
        "port": "8443",
        "secure": true,
        "verify": true,
        "query_timeout": 60
    },

BigQuery
--------

Example structure for BigQuery connection with path to service account key file:

.. code-block:: json

    "SERVER_DB": "BigQuery",
    "CREDENTIAL_DB": {
        "key_path": "...",
        "query_timeout": 60
    },

Snowflake
---------

The recommended way to connect is **key-pair authentication**: Snowflake has
deprecated single-factor password sign-ins, so a service user should
authenticate with an RSA key pair. Generate a key pair and assign the public
key to the service user as described in the
`Snowflake key-pair authentication guide <https://docs.snowflake.com/en/user-guide/key-pair-auth>`_,
then reference the private key file in ``settings.json``:

.. code-block:: json

    "SERVER_DB": "Snowflake",
    "CREDENTIAL_DB": {
         "user": "...",
         "account": "...",
         "private_key_path": "/path/to/rsa_key.p8",
         "private_key_passphrase": "...",
         "warehouse": "...",
         "schema": "...",
         "query_timeout": 60
    },

``private_key_passphrase`` is only required if the private key file is
encrypted; omit it for an unencrypted key.

Alternatively, a `programmatic access token (PAT) <https://docs.snowflake.com/en/user-guide/programmatic-access-tokens>`_
or a legacy password can be passed in the ``password`` field (used only when
``private_key_path`` is not set):

.. code-block:: json

    "SERVER_DB": "Snowflake",
    "CREDENTIAL_DB": {
         "user": "...",
         "password": "...",
         "account": "...",
         "warehouse": "...",
         "schema": "...",
         "query_timeout": 60
    },

Trino
-----

Example structure for Trino connection:

.. code-block:: json

    "SERVER_DB": "Trino",
    "CREDENTIAL_DB": {
        "host": "...",
        "port": 8443,
        "user": "...",
        "password": "...",
        "catalog": "...",
        "http_scheme": "https",
        "verify": false,
        "query_timeout": 60
    },

StarRocks
---------

Example structure for StarRocks connection:

.. code-block:: json

    "SERVER_DB": "StarRocks",
    "CREDENTIAL_DB": {
        "host": "...",
        "port": 9030,
        "user": "...",
        "password": "...",
        "ssl_ca": "...",
        "ssl_disabled": false,
        "query_timeout": 60
    },

Databricks
----------

Example structure for Databricks connection:

.. code-block:: json

    "SERVER_DB": "Databricks",
    "CREDENTIAL_DB": {
        "server_hostname": "adb-xxxxxxxxxxxx.azuredatabricks.net",
        "http_path": "/sql/1.0/warehouses/xxxxxxxxxxxx",
        "access_token": "dapi...",
        "catalog": "...",
        "query_timeout": 60
    },

``server_hostname`` and ``http_path`` can be found in the Databricks workspace
under **SQL Warehouses → Connection details**.
``access_token`` is a personal access token generated in **User Settings → Developer → Access tokens**.
``catalog`` is optional; if omitted, ``hive_metastore`` is used.

Greenplum
---------

Example structure for Greenplum connection:

.. code-block:: json

    "SERVER_DB": "Greenplum",
    "CREDENTIAL_DB": {
        "host": "...",
        "port": 6432,
        "sslmode": "require",
        "dbname": "...",
        "user": "...",
        "password": "...",
        "target_session_attrs": "read-write",
        "query_timeout": 60
    },

DuckDB
------

DuckDB is an embedded database: no server is needed, the whole database is a
single file readable by the XLTable service account.

.. code-block:: json

    "SERVER_DB": "DuckDB",
    "CREDENTIAL_DB": {
        "database": "/usr/olap/xltable/data/analytics.duckdb",
        "read_only": true,
        "query_timeout": 60
    },

``database`` is the path to the ``.duckdb`` file (use an absolute path).
``read_only`` is optional and defaults to ``true``; keep it enabled so that
several XLTable worker processes can open the same file simultaneously.
A ready-to-run sample database script is described in :doc:`duckdb_sample`.
