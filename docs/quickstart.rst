Quickstart
==========

This guide helps you deploy XLTable and connect Excel to your analytical database
as quickly as possible.

By the end of this guide you will have:

- XLTable server running on Linux
- A working database connection
- A simple OLAP cube accessible from Excel Pivot Tables

For complete details on each step, see the full documentation sections.

------------------------------------------------------------

Prerequisites
-------------

Before starting, make sure you have:

- A Linux server (Ubuntu 24.04+ recommended) with sudo access
- An analytical database (ClickHouse, BigQuery, Snowflake or Trino)
- Microsoft Excel (Microsoft 365 or Excel 2016+)
- XLTable distribution file (contact help@xltable.com to obtain it)

------------------------------------------------------------

Step 1: Install XLTable
-----------------------

Prepare the server and install required packages:

.. code-block:: bash

   sudo apt-get update
   sudo apt-get -y install supervisor nginx p7zip-full

Create the working directory:

.. code-block:: bash

   sudo mkdir /usr/olap
   sudo chmod a+rwx /usr/olap

Copy the distribution file to the server and extract it:

.. code-block:: bash

   scp xltable.7z user@your_server_ip:/usr/olap
   cd /usr/olap && 7z x xltable.7z
   chmod +x /usr/olap/xltable/main.bin

------------------------------------------------------------

Step 2: Configure database connection
--------------------------------------

Open the settings file:

.. code-block:: bash

   nano /usr/olap/xltable/setting/settings.json

Add your database connection and basic user credentials.
Example for ClickHouse:

.. code-block:: json

   {
       "SERVER_DB": "ClickHouse",
       "CREDENTIAL_DB": {
           "user": "default",
           "password": "your_password",
           "host": "your_clickhouse_host",
           "port": "8443",
           "secure": "True"
       },
       "USERS": {"analyst": "password123"},
       "USER_GROUPS": {"analyst": ["olap_users"]}
   }

For other database types, see :doc:`install`.

------------------------------------------------------------

Step 3: Create a minimal OLAP cube
------------------------------------

XLTable reads cube definitions from a table named ``olap_definition`` in your database.

For a ready-to-run example with sample tables, test data, and a complete cube definition, see :doc:`clickhouse_sample`.

------------------------------------------------------------

Step 4: Start the service
--------------------------

Create a Supervisor configuration file:

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

Reload Supervisor to start the service:

.. code-block:: bash

   sudo supervisorctl reload

Configure Nginx as a reverse proxy:

.. code-block:: bash

   sudo nano /etc/nginx/sites-enabled/olap

Paste the following content:

.. code-block:: nginx

   server {
       listen 80;
       server_name _;

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

------------------------------------------------------------

Step 5: Connect Excel
----------------------

1. Open Excel and go to **Data → Get Data → From Database → From Analysis Services**.
2. Enter the server URL: ``http://your_server_ip``
3. Enter the username and password configured in ``settings.json``.
4. Select the ``SalesCube`` cube.
5. Click **Finish** — your Pivot Table is ready.

Connection to XLTable is identical to connecting to Microsoft SQL Server Analysis Services (SSAS).
For details on authentication modes and advanced connection options, see :doc:`excel`.

------------------------------------------------------------

Next steps
----------

- :doc:`install` — complete installation guide for Linux and Windows
- :doc:`cubes` — full OLAP cube definition reference
- :doc:`reference` — settings.json parameters and SQL tag reference
- :doc:`clickhouse_sample` — ready-to-run ClickHouse script with sample tables, test data, and the ``myOLAPcube`` cube
- :doc:`support` — troubleshooting and contact information
