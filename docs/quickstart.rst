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

- A Linux server (Ubuntu 22.04+ recommended) with sudo access
- An analytical database (ClickHouse, BigQuery, Snowflake, Trino or StarRocks)
- Microsoft Excel (Microsoft 365 or Excel 2016+)
- XLTable distribution file (contact help@xltable.com to obtain it)

------------------------------------------------------------

Step 1: Install XLTable
-----------------------

Create the working directory:

.. code-block:: bash

   sudo mkdir /usr/olap
   sudo chmod a+rwx /usr/olap

Copy the distribution zip to the server:

.. code-block:: bash

   scp xltable-*-ubuntu.zip user@your_server_ip:/usr/olap/

Run the install script:

.. code-block:: bash

   bash install_xltable.sh

The script will:

- Install ``supervisor``, ``nginx``, ``unzip``
- Extract xltable to ``/usr/olap/xltable/``
- Create ``/usr/olap/xltable/setting/settings.json`` from the example (if missing)
- Configure supervisor to autostart the service
- Configure nginx as a reverse proxy on port 80

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
           "user": "...",
           "password": "...",
           "host": "...",
           "port": "8443",
           "secure": "True"
       },
       "OWNERS": {"admin": "pass1"},
       "USERS": {"analyst": "password123"},
       "USER_GROUPS": {"analyst": ["olap_users"]}
   }

.. note::

   After each change to the ``settings.json`` file, restart the service:

   .. code-block:: bash

      sudo supervisorctl restart olap

For other database types, see :doc:`install`.

------------------------------------------------------------

Step 3: Create a minimal OLAP cube
------------------------------------

XLTable reads cube definitions from a table named ``olap_definition`` in your database.

For a ready-to-run example with sample tables, test data, and a complete cube definition, see :doc:`clickhouse_sample`.

------------------------------------------------------------

Step 4: Start the service
--------------------------

The install script starts the service automatically. To manage it manually:

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
