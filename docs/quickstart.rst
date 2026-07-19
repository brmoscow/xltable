Quickstart
==========

This guide helps you deploy XLTable on **Windows 10 / 11** and connect Excel
to your analytical database as quickly as possible — no additional components
are required.

By the end of this guide you will have:

- XLTable server running on Windows 10 or 11
- A trial license activated
- A working database connection
- A simple OLAP cube accessible from Excel Pivot Tables

For a production installation on Linux or Windows Server, see :doc:`install`.

------------------------------------------------------------

Prerequisites
-------------

Before starting, make sure you have:

- A computer running Windows 10 or 11 (Windows Server also works — see :doc:`install`)
- An analytical database (ClickHouse, BigQuery, Snowflake, Trino, StarRocks, Databricks, Greenplum or DuckDB)
- Microsoft Excel (Microsoft 365 or Excel 2016+)
- XLTable distribution archive (contact help@xltable.com to obtain it)

------------------------------------------------------------

Step 1: Install XLTable
-----------------------

Download the distribution archive and extract it to a folder of your choice,
e.g. ``C:\xltable\``.

That is the whole installation — XLTable ships as a standalone executable.

------------------------------------------------------------

Step 2: Configure database connection
--------------------------------------

Edit the configuration file:

.. code-block:: text

   C:\xltable\setting\settings.json

Add your database connection and basic user credentials.
Example for ClickHouse:

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
         "query_timeout": 60
      },
      "WRITE_LOG": false,
      "MAX_CELLS": 100000,
      "OVERLOAD_GUARD": {
          "MAX_MEMORY_PERCENT": 90,
          "MAX_CPU_PERCENT": 95,
          "MIN_FREE_DISK_MB": 512
      },
      "CONVERT_FIELDS_TO_STRING": true,
      "USERS": {"user1": "pass1", "user2": "pass2"},
      "USER_GROUPS": {"user1": ["olap_users", "olap_admins"], "user2": ["olap_users"]},
      "ADMIN_GROUPS": ["olap_admins"]
   }

.. note::

   Changes to ``settings.json`` are picked up automatically within a few
   seconds of saving — no service restart is required.

For other database types, see :ref:`database_connections`.

------------------------------------------------------------

Step 3: Start the server
------------------------

Start the server by double-clicking ``main.exe`` (or from the command line):

.. code-block:: text

   C:\xltable\main.exe

The server listens on port 5000.

------------------------------------------------------------

Step 4: Get a trial license
---------------------------

Open the admin panel in your browser:

.. code-block:: text

   http://localhost:5000/admin

Log in as a user whose group is listed in ``ADMIN_GROUPS``
(``user1`` in the example above).

On the **License** tab, copy the **server id** and send it to
help@xltable.com (or Telegram https://t.me/XLTable) — we will issue you a
trial license. Upload the received ``.lic`` file using the form on the same
**License** tab.

For details, see :ref:`obtaining_license` and :ref:`admin_panel`.

------------------------------------------------------------

Step 5: Create a minimal OLAP cube
------------------------------------

XLTable reads cube definitions from a table named ``olap_definition`` in your database.

For a ready-to-run example with sample tables, test data, and a complete cube definition, see :doc:`clickhouse_sample`.

------------------------------------------------------------

Step 6: Connect Excel
----------------------

1. Open Excel and go to **Data → Get Data → From Database → From Analysis Services**.
2. Enter the server URL: ``http://localhost:5000``
3. Enter the username and password configured in ``settings.json``.
4. Select the ``myOLAPcube`` cube.
5. Click **Finish** — your Pivot Table is ready.

Connection to XLTable is identical to connecting to Microsoft SQL Server Analysis Services (SSAS).
For details on authentication modes and advanced connection options, see :doc:`excel`.

Connecting from other computers
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To let Excel users on other machines connect, allow inbound TCP port 5000
in Windows Firewall (run as administrator):

.. code-block:: text

   netsh advfirewall firewall add rule name="xltable" dir=in action=allow protocol=TCP localport=5000

They can then connect to ``http://<server-name-or-ip>:5000``.

------------------------------------------------------------

Next steps
----------

- :doc:`install` — complete installation guide for Linux, Windows 10 / 11 and Windows Server, including autostart and updates
- :doc:`cubes` — full OLAP cube definition reference
- :doc:`reference` — settings.json parameters and SQL tag reference
- :doc:`clickhouse_sample` — ready-to-run ClickHouse script with sample tables, test data, and the ``myOLAPcube`` cube
- :doc:`support` — troubleshooting and contact information
