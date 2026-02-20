
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
Ubuntu 20.04+ is recommended for production environments.

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
   nano settings.json

Add supervisor configuration:

.. code-block:: bash
   
   cd /etc/supervisor/conf.d
   sudo nano olap.conf

   # paste this code into the file and change <you_user>
   [program:olap]
   command=/usr/olap/xltable/main.bin
   directory=/usr/olap/xltable
   user=<you_user>
   autostart=true
   autorestart=true
   stopasgroup=true
   killasgroup=true

   $ sudo supervisorctl reload

Configure Nginx:

.. code-block:: bash

   cd /etc/nginx/sites-enabled
   sudo rm /etc/nginx/sites-enabled/default
   sudo nano olap

   # paste this code into the file, change if necessary 80 to 443 for https
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
      }

   }
   
   sudo service nginx reload

Important points:
- After each changing the settings.json file, need to restart the service using the command:
   
.. code-block:: bash

   $ sudo supervisorctl reload


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

Important points:
- After each changing the settings.json file, need to restart the service using the command:
   
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

