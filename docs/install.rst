
Installation
============

This section describes how to install XLTable, configure system access
and connect analytical databases.

XLTable can be deployed on Linux or Windows servers
and supports integration with Active Directory and multiple databases.

------------------------------------------------------------

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

Copy XLTable distribution zip to the server:

.. code-block:: bash

   scp xltable-*-ubuntu.zip user@server:/usr/olap/

Run the install script:

.. code-block:: bash

   bash install_xltable.sh

The script will:

- Install ``supervisor``, ``nginx``, ``unzip``
- Extract xltable to ``/usr/olap/xltable/``
- Create ``/usr/olap/xltable/setting/settings.json`` from the example (if missing)
- Configure supervisor to autostart the service
- Configure nginx as a reverse proxy on port 80

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
    "MAX_ROWS": 100000,
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

   After each change to the ``settings.json`` file, restart the service:

   .. code-block:: bash

      sudo supervisorctl restart olap


Upgrading version
^^^^^^^^^^^^^^^^^

Copy the new distribution zip to the server (remove or replace any previous zip first):

.. code-block:: bash

   scp xltable-*-ubuntu.zip user@server:/usr/olap/

Run the update script:

.. code-block:: bash

   bash update_xltable.sh

The script will:

- Verify the zip integrity
- Back up ``settings.json`` and ``.lic`` license files
- Replace the xltable installation
- Restore the backed-up config and license files
- Reload supervisor

Service Management
^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 20 50

   * - Action
     - Command
   * - Start
     - ``sudo supervisorctl start olap``
   * - Stop
     - ``sudo supervisorctl stop olap``
   * - Restart
     - ``sudo supervisorctl restart olap``
   * - Status
     - ``sudo supervisorctl status olap``
   * - Logs
     - ``sudo tail -f /var/log/supervisor/olap*.log``

------------------------------------------------------------

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
   tar -xf xltable-2.0.11-windows_server.zip

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

**9. Verify**

Open the admin panel in a browser at ``http://localhost/admin``.

In Excel, connect to the server at ``http://<server-name>/``.

Update
^^^^^^

1. Stop the IIS application pool (IIS Manager → Application Pools → Stop)
2. Back up ``settings.json`` and the license file ``.lic``
3. Extract the new distribution archive into ``C:\olap\xltable\``, overwriting existing files
4. Restore the backed-up ``settings.json`` and ``.lic``
5. Start the application pool

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

- **Service status** — confirms the server is running and shows the active database backend.
- **Documentation** — direct link to the XLTable documentation.
- **Clear Cache** — removes all cached session data. Users will need to re-authenticate after the cache is cleared.

------------------------------------------------------------

Database connections
--------------------

XLTable connects directly to analytical databases and executes SQL queries
on their side. All database connections are defined centrally in the
``settings.json`` file and reused across OLAP cubes.

Currently supported connection types:

- ClickHouse
- BigQuery
- Snowflake
- Trino
- StarRocks
- Databricks

For each database type, the corresponding configuration section must be
defined in ``settings.json``.

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
        "key_path": "..."
    },

Snowflake
^^^^^^^^^^

Example structure for Snowflake connection:

.. code-block:: json

    "SERVER_DB": "Snowflake",
    "CREDENTIAL_DB": {
         "user": "...",
         "password": "...",
         "account": "...",
         "warehouse": "...",    
         "schema": "..."
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
        "verify": false
    },  

StarRocks
^^^^^^^^^^

Example structure for StarRocks connection:

.. code-block:: json

    "SERVER_DB": "StarRocks",
    "CREDENTIAL_DB": {
        "host": "...",
        "port": ...,
        "user": "...",
        "password": "...",
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
        "catalog": "..."
    },

``server_hostname`` and ``http_path`` can be found in the Databricks workspace
under **SQL Warehouses → Connection details**.
``access_token`` is a personal access token generated in **User Settings → Developer → Access tokens**.
``catalog`` is optional; if omitted, ``hive_metastore`` is used.
