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

``secure`` enables TLS (port 8443 on a managed ClickHouse, 8123 is plain
HTTP), ``verify`` validates the server certificate. A server whose
certificate is issued by a cloud provider's or corporate CA also needs
``ca_cert`` — see :ref:`db_ca_cert`.

.. _db_ca_cert:

Cloud ClickHouse: CA certificate
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A managed ClickHouse (Yandex Cloud, other clouds) presents a certificate
signed by the provider's own CA, which is not among the public roots XLTable
trusts out of the box; the first query then fails with
``CERTIFICATE_VERIFY_FAILED: self-signed certificate in certificate chain``.
Download the provider's CA chain to a PEM file and point ``ca_cert`` at it.
For Yandex Cloud:

.. code-block:: bash

   sudo mkdir -p /etc/xltable
   curl -fsS https://storage.yandexcloud.net/cloud-certs/RootCA.pem \
        https://storage.yandexcloud.net/cloud-certs/IntermediateCA.pem \
        | sudo tee /etc/xltable/yandex-ca.pem > /dev/null

.. code-block:: json

   "SERVER_DB": "ClickHouse",
    "CREDENTIAL_DB": {
        "user": "...",
        "password": "...",
        "host": "rc1b-xxxxxxxxxxxxxxxx.mdb.yandexcloud.net",
        "port": "8443",
        "secure": true,
        "verify": true,
        "ca_cert": "/etc/xltable/yandex-ca.pem",
        "query_timeout": 60
    },

The same key is available on the **Connection** page of the admin console
(*CA certificate file*).

Without ``ca_cert`` the ClickHouse connection trusts the roots of the
operating system's certificate store (on Windows — *Trusted Root
Certification Authorities*, where the provider's CA can be imported
instead). On Ubuntu the installer points ``SSL_CERT_FILE`` and
``REQUESTS_CA_BUNDLE`` of the workers to the system bundle, so a CA
installed with ``update-ca-certificates`` is trusted without ``ca_cert``:

.. code-block:: bash

   sudo mkdir -p /usr/local/share/ca-certificates/Yandex
   sudo curl -fsS -o /usr/local/share/ca-certificates/Yandex/RootCA.crt \
        https://storage.yandexcloud.net/cloud-certs/RootCA.pem
   sudo curl -fsS -o /usr/local/share/ca-certificates/Yandex/IntermediateCA.crt \
        https://storage.yandexcloud.net/cloud-certs/IntermediateCA.pem
   sudo update-ca-certificates
   sudo supervisorctl restart 'olap:*'

``ca_cert`` works the same way for Trino, and is ignored when its
``verify`` is ``false``. Note that the Trino connection does not consult the
operating system's certificate store: without ``ca_cert`` only public roots
are trusted (on Ubuntu — the system bundle through ``REQUESTS_CA_BUNDLE``
set by the installer), so a corporate CA on Windows must be given as
``ca_cert``.

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

``verify`` validates the server certificate. For a Trino server with a
certificate from a corporate CA keep ``verify`` enabled and add
``"ca_cert": "/path/to/corp-ca.pem"`` (see :ref:`db_ca_cert`).

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
``access_token`` is a personal access token generated in **Settings → Developer → Access tokens**.
``catalog`` is the Unity Catalog catalog that holds your schemas; XLTable opens
the session in it, so two-level table names (``schema.table``) in cube SQL
resolve there. It is optional: when omitted, the default catalog of the
warehouse is used (``hive_metastore`` on legacy workspaces). On
**Databricks Free Edition** the catalog is ``workspace``.

.. note::

   Single quotes inside string literals of Databricks cube SQL are escaped
   with a backslash (``'It\'s'``). Spark SQL does not treat ``''`` as an
   escaped quote — adjacent literals are concatenated, so ``'It''s'`` silently
   becomes ``Its``.

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
