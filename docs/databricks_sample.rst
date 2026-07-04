Databricks Sample Data
======================

This page describes a ready-to-run SQL script that creates a complete set of
sample Databricks (Delta) tables, fills them with test data, and registers
the ``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.

The script file: :download:`databricks_sample.sql <databricks_sample.sql>`

------------------------------------------------------------

What the script creates
-----------------------

The script creates schema ``db`` in the **current catalog** —
``hive_metastore`` by default, which matches the default ``catalog``
behaviour of XLTable. On Unity Catalog, run ``USE CATALOG <name>;`` first
and set the same catalog in ``settings.json``.

.. list-table::
   :header-rows: 1
   :widths: 22 8 70

   * - Table
     - Rows
     - Description
   * - ``db.Times``
     - 1096
     - Calendar: every day from 2023-01-01 to 2025-12-31
   * - ``db.Regions``
     - 4
     - Sales regions: North, South, East, West
   * - ``db.Managers``
     - 5
     - Sales managers linked to regions (many-to-many)
   * - ``db.Stores``
     - 8
     - Retail stores, each assigned to a region
   * - ``db.Models``
     - 8
     - Product models (Alpha … Theta)
   * - ``db.Sales``
     - 3 000
     - Sales transactions: store, model, date, quantity, amount
   * - ``db.Stock``
     - 500
     - Inventory snapshots: store, model, quantity on hand
   * - ``db.olap_definition``
     - 1
     - OLAP cube definition read by XLTable

The cube ``myOLAPcube`` exposes:

- **Measures:** Sales Quantity, Sales Amount, Sales last year (Qty & Amount),
  Average Stock Quantity, calculated Turnover ratio
- **Dimensions:** Store ID, Store, Region, Manager, Model,
  Date hierarchy (Year → Quarter → Month → Day)

------------------------------------------------------------

Data model
----------

.. code-block:: text

                     ┌─────────────┐
                     │  db.Times   │
                     │  (calendar) │
                     └──────┬──────┘
                            │ day_str
               ┌────────────┴────────────┐
               │                         │
        ┌──────┴──────┐           ┌──────┴──────┐
        │  db.Sales   │           │  db.Stock   │
        └──────┬──────┘           └──────┬──────┘
               │ store / model           │ store / model
        ┌──────┴──────┐           ┌──────┴──────┐
        │  db.Stores  ├───────────┤  db.Models  │
        └──────┬──────┘           └─────────────┘
               │ region
        ┌──────┴──────┐
        │ db.Regions  │
        └──────┬──────┘
               │ id  (many-to-many)
        ┌──────┴──────┐
        │db.Managers  │
        └─────────────┘

------------------------------------------------------------

Prerequisites
-------------

- A Databricks workspace with a running **SQL warehouse**
  (or an all-purpose cluster)
- A user with ``CREATE SCHEMA``, ``CREATE TABLE`` privileges in the catalog
- A personal access token for XLTable
  (**User Settings → Developer → Access tokens**)
- XLTable server already installed and running (see :doc:`install`)

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Download :download:`databricks_sample.sql <databricks_sample.sql>` and run it
using one of the options below.

**Option A — Databricks SQL editor (recommended)**

1. Open your workspace and go to **SQL Editor**.
2. Select a running SQL warehouse.
3. Paste the script contents into a new query and click **Run all**.

**Option B — Databricks SQL CLI**

.. code-block:: bash

   dbsqlcli --hostname   <workspace-host> \
            --http-path  <warehouse-http-path> \
            --access-token <dapi...> \
            -e databricks_sample.sql

After a successful run the output should contain no errors.
Verify that all tables were created and populated:

.. code-block:: sql

   SELECT 'Times'            AS `table`, COUNT(*) AS rows FROM db.Times
   UNION ALL SELECT 'Regions',           COUNT(*) FROM db.Regions
   UNION ALL SELECT 'Managers',          COUNT(*) FROM db.Managers
   UNION ALL SELECT 'Stores',            COUNT(*) FROM db.Stores
   UNION ALL SELECT 'Models',            COUNT(*) FROM db.Models
   UNION ALL SELECT 'Sales',             COUNT(*) FROM db.Sales
   UNION ALL SELECT 'Stock',             COUNT(*) FROM db.Stock
   UNION ALL SELECT 'olap_definition',   COUNT(*) FROM db.olap_definition
   ORDER BY `table`;

Expected output:

.. code-block:: text

   table            | rows
   -----------------+------
   Managers         |    5
   Models           |    8
   Regions          |    4
   Sales            | 3000
   Stock            |  500
   Stores           |    8
   Times            | 1096
   olap_definition  |    1

------------------------------------------------------------

Step 2: Configure XLTable
--------------------------

Open ``/usr/olap/xltable/setting/settings.json`` and update the database
connection block:

.. code-block:: json

   {
       "SERVER_DB": "Databricks",
       "CREDENTIAL_DB": {
           "server_hostname": "adb-xxxxxxxxxxxx.azuredatabricks.net",
           "http_path": "/sql/1.0/warehouses/xxxxxxxxxxxx",
           "access_token": "dapi..."
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
       "LDAP_CACHE_TIMEOUT": 300
   }

``server_hostname`` and ``http_path`` can be found in the Databricks workspace
under **SQL Warehouses → Connection details**. If you created the sample in a
Unity Catalog catalog (not ``hive_metastore``), add ``"catalog": "<name>"``
to ``CREDENTIAL_DB``.

XLTable automatically discovers all cubes stored in the ``olap_definition``
table, so no additional cube configuration is needed.

------------------------------------------------------------

Step 3: Restart XLTable
------------------------

.. code-block:: bash

   sudo supervisorctl restart olap

------------------------------------------------------------

Step 4: Connect Excel
---------------------

1. Open Excel and go to **Data → Get Data → From Database → From Analysis Services**.
2. Enter the server URL: ``http://your_server_ip``
3. Log in with ``user1 / pass1``.
4. Select ``myOLAPcube``.
5. Drag any measures and dimensions onto the Pivot Table — done.

Available fields in the Pivot Table:

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Field name (Excel)
     - Type
     - Notes
   * - Sales Quantity
     - Measure
     - ``sum(sales.qty)``
   * - Sales Amount
     - Measure
     - ``sum(sales.amount)``
   * - Sales last year Quantity
     - Measure
     - Same query, dates shifted +1 year via Jinja
   * - Sales last year Amount
     - Measure
     - Same query, dates shifted +1 year via Jinja
   * - Average Stock Quantity
     - Measure
     - ``avg(stock.qty)``
   * - Turnover
     - Calculated
     - Sales Quantity ÷ Average Stock Quantity
   * - Store ID / Store
     - Dimension
     -
   * - Region
     - Dimension
     - North · South · East · West
   * - Manager
     - Dimension
     - Many-to-many with Region
   * - Model
     - Dimension
     - Alpha … Theta
   * - Year / Quarter / Month / Day
     - Dimension
     - ``Dates`` hierarchy, drill-down supported

------------------------------------------------------------

Customising the script
-----------------------

**Change the date range**

The calendar is generated for 2023–2025.
To extend it to 2026, adjust the ``range`` upper bound:

.. code-block:: sql

   -- In db.Times — add 365 days for 2026 (1096 + 365 = 1461)
   FROM range(0, 1461);

Then update the cube definition inside ``db.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025', '2026')

**Add more stores or models**

Extend the ``VALUES`` lists in ``db.Stores`` / ``db.Models`` and update the
``CASE`` blocks in the ``db.Sales`` and ``db.Stock`` queries accordingly.

**Use a different schema or catalog**

Replace every occurrence of ``db.`` with your own prefix, e.g. ``mydb.``,
including inside the OLAP cube definition string stored in
``db.olap_definition``. For a non-default catalog, run
``USE CATALOG <name>;`` before the script and set ``"catalog"`` in
``settings.json``.

------------------------------------------------------------

Troubleshooting
---------------

``Schema 'db' not found``
    Make sure ``CREATE SCHEMA IF NOT EXISTS db;`` ran in the same catalog
    you are querying. Check the current catalog with ``SELECT current_catalog();``.

``PERMISSION_DENIED`` when creating tables
    On Unity Catalog the user needs ``USE CATALOG``, ``USE SCHEMA``,
    ``CREATE TABLE`` grants. Ask your workspace admin, or run the sample in
    ``hive_metastore``.

``Warehouse is stopped``
    Databricks SQL warehouses auto-stop when idle. Start the warehouse in
    **SQL Warehouses** before running the script or connecting from Excel.

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: sql

       SELECT id FROM db.olap_definition;

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user, and that ``catalog`` in
    ``CREDENTIAL_DB`` matches the catalog where the sample was created.

``Invalid access token``
    Personal access tokens expire. Generate a new one in
    **User Settings → Developer → Access tokens** and update
    ``access_token`` in ``settings.json``.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: databricks_sample.sql
   :language: sql
