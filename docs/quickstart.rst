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

.. note::

   This guide sets up the **server edition** for a trial: named users, a
   license, network access for other Excel users. The distribution starts
   as the **free desktop edition** out of the box — a single-user, local-only
   server whose first run is guided end to end by the **Quick start** page
   of the admin console (see :ref:`start_page`); if that is what you need,
   just start ``XLTable.exe`` and follow the checklist in the browser.

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
      "EDITION": "server",
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

   The ``settings.json`` shipped in the distribution is the free desktop
   configuration (``"EDITION": "free"``) — replace it with the example
   above; ``"EDITION": "server"`` is what enables named users, the license
   and network access (see :confval:`EDITION`). Changes to ``settings.json``
   are picked up automatically within a few seconds of saving — no service
   restart is required (changing ``EDITION`` is the exception: it needs a
   restart).

For other database types, see :ref:`database_connections`.

.. tip::

   Once the server is running, the connection can be reviewed and tested on
   the **Warehouse connection** page of the admin console
   (``http://127.0.0.1:5000/admin``); the free desktop edition can fill in
   and save the whole connection right there, without editing the JSON —
   see :doc:`connection`.

------------------------------------------------------------

Step 3: Start the server
------------------------

Start the server by double-clicking ``XLTable.exe`` (or from the command line):

.. code-block:: text

   C:\xltable\XLTable.exe

The server listens on port 5000.

------------------------------------------------------------

Step 4: Get a trial license
---------------------------

Open the admin panel in your browser:

.. code-block:: text

   http://127.0.0.1:5000/admin

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
2. Enter the server URL: ``http://127.0.0.1:5000``
   (prefer ``127.0.0.1`` over ``localhost`` — the latter adds ~2 s per
   request on Windows, see the note in :doc:`excel`)
3. Enter the username and password configured in ``settings.json``.
4. Select the ``myOLAPcube`` cube.
5. Click **Finish** — your Pivot Table is ready.

Connection to XLTable is identical to connecting to Microsoft SQL Server Analysis Services (SSAS).
For details on authentication modes and advanced connection options, see :doc:`excel`.

------------------------------------------------------------

Next steps
----------

- :doc:`install` — complete installation guide for Linux, Windows 10 / 11 and Windows Server, including autostart and updates
- :doc:`cubes` — full OLAP cube definition reference
- :doc:`reference` — SQL tag reference for cube definitions
- :doc:`settings` — settings.json parameter reference
- :doc:`clickhouse_sample` — ready-to-run ClickHouse script with sample tables, test data, and the ``myOLAPcube`` cube
- :doc:`support` — troubleshooting and contact information
