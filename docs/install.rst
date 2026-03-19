
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
Ubuntu 24.04+ is recommended for production environments.

Prerequisites
^^^^^^^^^^^^^

- Linux server with sudo access
- Network access to analytical databases
- Open ports 80 or 443 for Excel clients

Prepare system
^^^^^^^^^^^^^^

Update system packages and install required system packages:

.. code-block:: bash

   sudo apt-get update
   sudo apt-get -y install supervisor nginx git p7zip-full

Create working directory:

.. code-block:: bash

   sudo mkdir /usr/olap
   sudo chmod a+rwx /usr/olap

Install XLTable
^^^^^^^^^^^^^^^

Copy XLTable distribution file into the working directory. Example of copying from Windows:

.. code-block:: bash

   scp -r c:\win_local_folder\xltable.7z user@server_ip:/usr/olap

Unpacking the distribution file and grant execution rights:

.. code-block:: bash

   cd /usr/olap
   7z x xltable.7z
   cd /usr/olap/xltable
   chmod +x main.bin

Set up connections with database (configuration examples in the folder ``/usr/olap/xltable/setting``):

.. code-block:: bash

   cd /usr/olap/xltable/setting
   cp settings_clickhouse_example.json settings.json
   nano settings.json

Example of a minimal settings.json:

.. code-block:: bash

  {    
    "SERVER_DB": "ClickHouse",
    "CREDENTIAL_DB": {
        "user": "...",
        "password": "...",
        "host": "...",
        "port": "8443",
        "secure": "True"
    },
    "WRITE_LOG": false,
    "OWNERS": {"admin": "pass1"},
    "USERS": {"name": "password"},
    "USER_GROUPS": {"name": ["group_name"]},
    "MAX_ROWS": 100000,
    "LDAP_CACHE_TIMEOUT": 300,
    "CONVERT_FIELDS_TO_STRING": true,
    "CREDENTIAL_ACTIVE_DIRECTORY": {
        "server_address": "..",
        "domain": "..",
        "domain_full": "..",
        "username": "..",
        "password": "..",
        "access_group": ".."
       }
   }

Add supervisor configuration:

.. code-block:: bash

   sudo nano /etc/supervisor/conf.d/olap.conf

Paste the following content (replace ``<your_user>`` with the actual Linux username):

.. code-block:: ini

   [program:olap]
   command=/usr/olap/xltable/main.bin
   directory=/usr/olap/xltable
   user=<your_user>
   autostart=true
   autorestart=true
   stopasgroup=true
   killasgroup=true

Reload Supervisor to apply the configuration:

.. code-block:: bash

   sudo supervisorctl reload

Configure Nginx as a reverse proxy:

.. code-block:: bash

   sudo rm /etc/nginx/sites-enabled/default
   sudo nano /etc/nginx/sites-enabled/olap

Paste the following content (change ``80`` to ``443`` for HTTPS):

.. code-block:: nginx

   server {
      listen 80;
      server_name _;

      access_log /var/log/olap_access.log;
      error_log /var/log/olap_error.log;

      location / {
         proxy_pass http://localhost:5000;
         proxy_redirect off;
         proxy_set_header Host $host;
         proxy_set_header X-Real-IP $remote_addr;
         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
         proxy_connect_timeout 300s;
         proxy_send_timeout 300s;
         proxy_read_timeout 300s;
      }
   }

Reload Nginx:

.. code-block:: bash

   sudo service nginx reload

.. note::

   After each change to the ``settings.json`` file, restart the service:

   .. code-block:: bash

      sudo supervisorctl reload


Upgrading version
^^^^^^^^^^^^^^^^^

Copy the archive with the new version to the server:

.. code-block:: bash

   scp -r c:\win_local_folder\xltable.7z user@server_ip:/usr/olap

Save the configuration and license, then extract the update on the server:

.. code-block:: bash

   cd /usr/olap
   cp /usr/olap/xltable/setting/*.json /usr/olap
   cp /usr/olap/xltable/*.lic /usr/olap
   rm -r xltable
   7z x xltable.7z
   cd /usr/olap/xltable
   chmod +x main.bin
   cp /usr/olap/*.json /usr/olap/xltable/setting
   cp /usr/olap/*.lic /usr/olap/xltable

   sudo supervisorctl reload

------------------------------------------------------------

Windows
-------

XLTable can be installed on Windows Server.
Windows Server 2019+ is recommended for production environments.

Prerequisites
^^^^^^^^^^^^^

- Windows Server 2019+ with administrator privileges
- Network access to analytical databases
- Open ports 80 or 443 for Excel clients

Prepare system
^^^^^^^^^^^^^^

- Install IIS (Web Server role).
- Install URL Rewrite and ARR (Application Request Routing).
- Create working directory: ``c:\olap``

Install XLTable
^^^^^^^^^^^^^^^

Copy XLTable distribution file into the working directory and unpacking it.
Set up connections with database (configuration examples in the folder ``c:\olap\xltable\setting``):

Configure the IIS site as a reverse proxy on the local port http://127.0.0.1:5000/{R:0} and add the REMOTE_USER header to the request.

Installing the service XLTable using NSSM (Non-Sucking Service Manager):

.. code-block:: bash
   
   nssm install XLTable "C:\olap\xltable\main.exe"
   nssm start XLTable

Enable required authentication in IIS.

.. note::

   After each change to the ``settings.json`` file, restart the service:

   .. code-block:: bash

      nssm restart XLTable

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
   "USER_GROUPS": {"user1": ["olap_users"], "user2": ["olap_admins"]},

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

Access is protected by a separate set of credentials defined in ``OWNERS``
(independent from regular ``USERS``).

Configure admin credentials
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Add the ``OWNERS`` section to ``settings.json``:

.. code-block:: json

   "OWNERS": {"admin": "secret_password"}

.. note::

   ``OWNERS`` credentials are completely separate from ``USERS``.
   A user defined in ``USERS`` cannot access the admin panel,
   and an owner cannot connect as a regular Excel user.

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
        "secure": "True"
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
