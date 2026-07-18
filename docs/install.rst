
Installation
============

This section describes how to install XLTable, configure system access
and connect analytical databases.

XLTable can be deployed on Linux or Windows servers
and supports integration with Active Directory and multiple databases.

------------------------------------------------------------

.. _install_ubuntu:

Linux
-----

XLTable can be installed on modern Linux distributions.
Ubuntu 22.04+ is recommended for production environments.

Prerequisites
^^^^^^^^^^^^^

- Ubuntu 22.04+ server with ``sudo`` access
- Network access to analytical databases
- Open ports 80 or 443 for Excel clients
- XLTable distribution zip placed in ``/usr/olap/`` (e.g. ``xltable-1.0.0-ubuntu.zip``)

Prepare system
^^^^^^^^^^^^^^

Create working directory:

.. code-block:: bash

   sudo mkdir /usr/olap
   sudo chmod a+rwx /usr/olap

Install XLTable
^^^^^^^^^^^^^^^

Copy the XLTable distribution zip and the installer to the server:

.. code-block:: bash

   scp xltable-*-ubuntu.zip install_ubuntu.zip user@server:/usr/olap/

Unpack the installer scripts and run the install script:

.. code-block:: bash

   cd /usr/olap
   unzip -o install_ubuntu.zip
   bash install_xltable.sh

The script will:

- Install ``supervisor``, ``nginx``, ``unzip``
- Extract xltable to ``/usr/olap/xltable/``
- Create ``/usr/olap/xltable/setting/settings.json`` from the example (if missing)
- Configure supervisor to autostart several xltable worker processes
  (one per CPU core, up to 4 by default)
- Configure nginx on port 80 as a load balancer across the worker
  processes (ports 5000, 5001, ...)

.. note::

   Several worker processes are what lets heavy reports from many concurrent
   users be built in parallel: Python limits one process to one CPU core for
   result building, so the instance count is effectively the number of large
   reports the server can render at the same time. All instances share the
   same cache and ``settings.json``. To change the count, re-run the installer
   with the desired number — the existing configuration and settings are kept:

   .. code-block:: bash

      XLTABLE_INSTANCES=6 bash install_xltable.sh

Set up connections with database (configuration examples in the folder ``/usr/olap/xltable/setting``):

.. code-block:: bash

   nano /usr/olap/xltable/setting/settings.json

Example of a minimal settings.json:

.. code-block:: json

  {
    "SERVER_DB": "ClickHouse",
    "CREDENTIAL_DB": {
        "user": "..",
        "password": "..",
        "host": "..",
        "port": "8443",
        "secure": true,
        "verify": true,
        "query_timeout": 300
    },
    "WRITE_LOG": false,
    "DUMP_XMLA": false,
    "LOG_RETENTION_DAYS": 14,
    "MAX_CELLS": 1000000,
    "OVERLOAD_GUARD": {
        "MAX_MEMORY_PERCENT": 90,
        "MAX_CPU_PERCENT": 95,
        "MIN_FREE_DISK_MB": 512
    },
    "CONVERT_FIELDS_TO_STRING": true,
    "USERS": {"user1": "pass1", "user2": "pass2"},
    "USER_GROUPS": {"user1": ["olap_users", "olap_admins"], "user2": ["olap_users"]},
    "ADMIN_GROUPS": ["olap_admins"],
    "CREDENTIAL_ACTIVE_DIRECTORY": {
        "server_address": "..",
        "domain": "..",
        "domain_full": "..",
        "username": "..",
        "password": "..",
        "access_groups": ["..", ".."]
    },
    "LDAP_CACHE_TIMEOUT": 300
  }

.. note::

   Changes to ``settings.json`` are picked up automatically within a few
   seconds of saving — no service restart is required (see
   :ref:`settings_schema`).


Upgrading version
^^^^^^^^^^^^^^^^^

Copy the new distribution zip to the server (remove or replace any previous zip first):

.. code-block:: bash

   scp xltable-*-ubuntu.zip user@server:/usr/olap/

Run the update script:

.. code-block:: bash

   cd /usr/olap
   bash update_xltable.sh

The script will:

- Verify the zip integrity
- Back up ``settings.json`` and the ``.lic`` license file to ``/usr/olap/backup_<timestamp>/``
- Stop the service and replace the xltable installation
- Restore the backed-up config and license files
- Set file ownership to the service user from the supervisor config
- Restart the service and show its status

The backup folder is kept after the update — remove it once you have
confirmed the new version works.

.. _service_management:

Service Management
^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 20 50

   * - Action
     - Command
   * - Start
     - ``sudo supervisorctl start 'olap:*'``
   * - Stop
     - ``sudo supervisorctl stop 'olap:*'``
   * - Restart
     - ``sudo supervisorctl restart 'olap:*'``
   * - Status
     - ``sudo supervisorctl status 'olap:*'``
   * - Logs
     - ``sudo tail -f /var/log/supervisor/olap*.log``

``olap:*`` addresses every worker process of the service; it also works on
installations that still run the old single-process configuration.

------------------------------------------------------------

.. _install_windows:

Windows
-------

XLTable can be installed on Windows Server 2019+.

Prerequisites
^^^^^^^^^^^^^

**IIS Roles and Features** (Server Manager → Add Roles and Features):

- Role: **Web Server (IIS)**
- Under **Web Server → Application Development**: enable **CGI** (also enables FastCGI)
- Under **Web Server → Security**: enable **Windows Authentication** and **Basic Authentication**

- Network access to analytical databases
- Open ports 80 or 443 for Excel clients

Installation
^^^^^^^^^^^^

**1. Install Python 3.12.6**

Download and install Python 3.12.6 for Windows (64-bit). During installation, check **"Add Python to PATH"**.

**2. Create the application folder**

.. code-block:: bash

   mkdir C:\olap

**3. Extract the distribution archive**

Copy the distribution archive into ``C:\olap``, then extract it:

.. code-block:: bash

   cd C:\olap
   tar -xf xltable-<version>-windows_server.zip

The application folder will be at ``C:\olap\xltable\``.

**4. Create a virtual environment**

.. code-block:: bash

   cd C:\olap\xltable
   python -m venv .venv

**5. Install dependencies**

.. code-block:: bash

   C:\olap\xltable\.venv\Scripts\pip install -r requirements.txt

**6. Configure settings**

Edit the configuration file ``C:\olap\xltable\setting\settings.json`` and fill in all required fields (database connections, license path, etc.).

**7. Configure IIS with web.config**

Use the file ``C:\olap\xltable\web.config``. It configures FastCGI to run the application via the virtual environment Python interpreter.

Authentication is set to **Windows Authentication** and **Basic Authentication** (anonymous access disabled).

**8. Register the FastCGI application in IIS**

Open **IIS Manager → server node → FastCGI Settings → Add Application**:

- **Full Path:** ``C:\olap\xltable\.venv\Scripts\python.exe``
- **Arguments:** ``C:\olap\xltable\.venv\Lib\site-packages\wfastcgi.py``

**9. Point the IIS site to the application**

In **IIS Manager → Sites**, select **Default Web Site** (or create a dedicated site):

- **Basic Settings → Physical Path:** ``C:\olap\xltable``
- **Authentication:** disable **Anonymous Authentication**, enable **Windows Authentication** and **Basic Authentication** (matches the ``web.config`` from step 7)
- Restart the site

**10. Verify**

Open the admin panel in a browser at ``http://localhost/admin``.

In Excel, connect to the server at ``http://<server-name>/``.

Update
^^^^^^

1. Stop the IIS application pool (IIS Manager → Application Pools → Stop)
2. Back up ``settings.json`` and the license file ``.lic``
3. Extract the new distribution archive into ``C:\olap\xltable\``, overwriting existing files
4. Restore the backed-up ``settings.json`` and ``.lic``
5. Update dependencies (skip if ``requirements.txt`` did not change):

   .. code-block:: bash

      C:\olap\xltable\.venv\Scripts\pip install -r C:\olap\xltable\requirements.txt

6. Start the application pool

------------------------------------------------------------

Authentication
--------------

XLTable supports two authorization modes: local authentication
defined in ``settings.json`` and integration with Active Directory(LDAP).

Local authorization
^^^^^^^^^^^^^^^^^^^

At the basic level, authorization is configured directly
in the ``settings.json`` file.

Administrators can define:

- Users and passwords
- User groups
- Mapping of users to groups

This mode is suitable for:
- test environments
- small installations
- isolated deployments without domain infrastructure

Example structure:

.. code-block:: json

   "USERS": {"user1": "pass1", "user2": "pass2"},
   "USER_GROUPS": {"user1": ["olap_users", "olap_admins"], "user2": ["olap_users"]},
   "ADMIN_GROUPS": ["olap_admins"],

Active Directory integration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

XLTable supports authentication and authorization
using Microsoft Active Directory.

Active Directory integration allows you to:
- Authenticate users automatically
- Map AD users and groups to XLTable roles
- Centralize access management

To enable Active Directory authentication, configure the corresponding
section in the ``settings.json`` file.

This section defines connection parameters to the domain controller, account for looking up user information, group mapping rules and other LDAP parameters.

Example structure:

.. code-block:: json

    "CREDENTIAL_ACTIVE_DIRECTORY": {
        "server_address": "dc.company.org",
        "domain": "company",
        "domain_full": "company.org",
        "username": "service_olap",
        "password": "...",
        "access_groups": ["olap_users_all", "olap_users_sales", "olap_users_accounting"]
    }

------------------------------------------------------------

.. _admin_panel:

Admin panel
-----------

XLTable includes a built-in admin panel for monitoring and managing the server.

URL
^^^

The admin panel is available at:

.. code-block:: text

   http://<server>/admin

Access is granted to users who belong to a group listed in ``ADMIN_GROUPS``.

Configure admin access
^^^^^^^^^^^^^^^^^^^^^^

Add the ``ADMIN_GROUPS`` section to ``settings.json``:

.. code-block:: json

   "ADMIN_GROUPS": ["olap_admins"]

To access the admin panel, log in as a user whose group is listed in ``ADMIN_GROUPS``.
For local users, the group is assigned via ``USER_GROUPS``; for AD users — via Active Directory group membership.

Features
^^^^^^^^

The admin panel provides:

- **Service status** — confirms the server is running, shows the active
  database backend and the settings file in use with the time it was last
  loaded (``settings.json`` is re-read automatically when it changes, see
  :ref:`settings_schema`).
- **Documentation** — direct link to the XLTable documentation.
- **Cache overview** — a per-user table showing active sessions, the number of
  cached entries and the time of the last activity, with a **Sign out** button
  that drops the sessions of a single user without affecting the others.
- **Clear Metadata Cache** — removes cached cube definitions, schema lists and
  query results while keeping users signed in. Use it after editing a cube so
  the new definition is picked up immediately (it is also picked up
  automatically within ``METADATA_CACHE_TTL``, see :ref:`settings_schema`).
- **Clear All Cache** — removes all cached session data. Users will need to re-authenticate after the cache is cleared.

------------------------------------------------------------

.. _database_connections:

Database connections
--------------------

XLTable connects directly to analytical databases and executes SQL queries
on their side. All database connections are defined centrally in the
``settings.json`` file and reused across OLAP cubes.

Currently supported connection types:

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
seconds (default: 300). A query running longer than this is cancelled and an
error is returned to Excel instead of holding the connection indefinitely.

ClickHouse
^^^^^^^^^^

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
        "query_timeout": 300
    },

BigQuery
^^^^^^^^^^

Example structure for BigQuery connection with path to service account key file:

.. code-block:: json

    "SERVER_DB": "BigQuery",
    "CREDENTIAL_DB": {
        "key_path": "...",
        "query_timeout": 300
    },

Snowflake
^^^^^^^^^^

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
         "query_timeout": 300
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
         "query_timeout": 300
    },

Trino
^^^^^^^^^^

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
        "query_timeout": 300
    },

StarRocks
^^^^^^^^^^

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
        "query_timeout": 300
    },

Databricks
^^^^^^^^^^

Example structure for Databricks connection:

.. code-block:: json

    "SERVER_DB": "Databricks",
    "CREDENTIAL_DB": {
        "server_hostname": "adb-xxxxxxxxxxxx.azuredatabricks.net",
        "http_path": "/sql/1.0/warehouses/xxxxxxxxxxxx",
        "access_token": "dapi...",
        "catalog": "...",
        "query_timeout": 300
    },

``server_hostname`` and ``http_path`` can be found in the Databricks workspace
under **SQL Warehouses → Connection details**.
``access_token`` is a personal access token generated in **User Settings → Developer → Access tokens**.
``catalog`` is optional; if omitted, ``hive_metastore`` is used.

Greenplum
^^^^^^^^^^

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
        "query_timeout": 300
    },

DuckDB
^^^^^^^^^^

DuckDB is an embedded database: no server is needed, the whole database is a
single file readable by the XLTable service account.

.. code-block:: json

    "SERVER_DB": "DuckDB",
    "CREDENTIAL_DB": {
        "database": "/usr/olap/xltable/data/analytics.duckdb",
        "read_only": true,
        "query_timeout": 300
    },

``database`` is the path to the ``.duckdb`` file (use an absolute path).
``read_only`` is optional and defaults to ``true``; keep it enabled so that
several XLTable worker processes can open the same file simultaneously.
A ready-to-run sample database script is described in :doc:`duckdb_sample`.

------------------------------------------------------------

.. _install_multi_server:

Scaling to multiple servers (Redis cache)
-----------------------------------------

A single XLTable machine already runs several worker processes behind nginx
(see :ref:`install_ubuntu`). When one machine is not enough, run XLTable on
several servers and let them share one cache through Redis: set
``CACHE_BACKEND`` to ``redis`` in ``settings.json`` on every server.

.. code-block:: json

    "CACHE_BACKEND": "redis",
    "REDIS_URL": "redis://:yourpassword@redis-host:6379/0"  

With a shared cache every server can handle every request, so a load
balancer in front of the servers needs no sticky sessions — plain
round-robin works:

.. code-block:: nginx

   upstream xltable {
       least_conn;
       server 10.0.0.11:80;
       server 10.0.0.12:80;
   }

   server {
       listen 80;
       client_max_body_size 16m;
       location / {
           proxy_pass http://xltable;
           proxy_read_timeout 600s;   # heavy reports may run for minutes
           proxy_set_header Authorization $http_authorization;
       }
   }

What the shared cache gives you:

- a session opened through one server is valid on all of them — Excel
  refreshes keep working no matter where the balancer sends them;
- **Cancel** works across servers: a query started on one server can be
  cancelled by a request that lands on another (except Databricks and
  embedded DuckDB, where the query is interrupted in-process and the Cancel
  request must reach the server process running the query);
- the licensed user limit is counted across all servers, not per server;
- **Clear All Cache** / **Clear Metadata Cache** in the admin panel of any
  server take effect for the whole cluster.

.. warning::

   - ``settings.json`` must be **identical on all servers**. Every server
     checks a fingerprint of its configuration against the shared cache and
     clears the cache on mismatch — servers with different configurations
     would keep wiping the cache for each other. Deploy configuration
     changes to all servers together.
   - The Redis instance must **not be reachable by anyone but the XLTable
     servers**: protect it with a password (``requirepass`` /  ACL), keep it
     on a private network. Cached entries carry session authorization state,
     and anyone able to write to this Redis can effectively execute code on
     the XLTable servers.

When ``CACHE_BACKEND`` is not set (or set to ``sqlite``), XLTable keeps the
default single-machine cache shared by the worker processes of that machine.
If the ``redis`` backend is misconfigured (missing ``REDIS_URL``), the
server logs an error and falls back to the SQLite cache instead of failing
to start.

