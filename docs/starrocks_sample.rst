StarRocks Sample Data
=====================

This page describes a ready-to-run SQL script that creates a complete set of
sample StarRocks tables, fills them with test data, and registers the
``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.

The script file: :download:`starrocks_sample.sql <starrocks_sample.sql>`

------------------------------------------------------------

What the script creates
-----------------------

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

- StarRocks 3.1+ cluster (local or remote) reachable from your workstation
  (the script uses ``generate_series()``, available since 3.1)
- ``mysql`` command-line client installed (StarRocks speaks the MySQL protocol)
- A StarRocks user with ``CREATE DATABASE``, ``CREATE TABLE``, ``INSERT`` privileges
- XLTable server already installed and running (see :doc:`install`)

.. note::

   The script sets ``PROPERTIES ("replication_num" = "1")`` on every table so
   it runs on single-node test clusters. On a production cluster remove this
   property (or set it to ``"3"``).

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Download :download:`starrocks_sample.sql <starrocks_sample.sql>` and run it
against your StarRocks cluster through the FE query port (9030 by default):

.. code-block:: bash

   mysql -h <your_starrocks_host> -P 9030 -u <user> -p < starrocks_sample.sql

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
       "SERVER_DB": "StarRocks",
       "CREDENTIAL_DB": {
           "host": "<your_starrocks_host>",
           "port": 9030,
           "user": "<user>",
           "password": "<password>",
           "ssl_disabled": true
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

If your cluster requires TLS, set ``"ssl_disabled": false`` and provide the
certificate path in ``"ssl_ca"`` (see :ref:`database_connections`).

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
To extend it to 2026, adjust the ``generate_series`` upper bound:

.. code-block:: sql

   -- In db.Times INSERT — add 365 days for 2026 (1095 + 365 = 1460)
   FROM (SELECT generate_series AS n FROM TABLE(generate_series(0, 1460))) t;

Then update the cube definition inside ``db.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025', '2026')

**Add more stores or models**

Extend the ``INSERT INTO db.Stores`` / ``db.Models`` sections and update the
``CASE`` blocks in the ``db.Sales`` and ``db.Stock`` inserts accordingly.

**Use a different database name**

Replace every occurrence of ``db.`` with your own prefix, e.g. ``mydb.``,
including inside the OLAP cube definition string stored in
``db.olap_definition``.

------------------------------------------------------------

Troubleshooting
---------------

``Unknown table function generate_series``
    ``generate_series()`` requires StarRocks 3.1 or newer.
    On older versions, generate the number sequence with a helper table
    or upgrade the cluster.

``Table creation failed: replication num should be less than or equal to the number of backends``
    A different error direction: your cluster has fewer backends than the
    requested replication. The script already uses ``"replication_num" = "1"``;
    make sure the property was not removed.

``ERROR 1064 near 'PROPERTIES'``
    The statement was cut mid-way — make sure the whole script file is piped
    into ``mysql`` and no statement separator was lost.

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: sql

       SELECT id FROM db.olap_definition;

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user.

``Access denied`` when running the script
    The StarRocks user needs at minimum:
    ``CREATE DATABASE``, ``CREATE TABLE``, ``INSERT``, ``DROP TABLE`` on ``db.*``.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: starrocks_sample.sql
   :language: sql
