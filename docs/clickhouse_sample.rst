ClickHouse Sample Data
======================

This page describes a ready-to-run SQL script that creates a complete set of
sample ClickHouse tables, fills them with test data, and registers the
``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.

The script file: :download:`clickhouse_sample.sql <clickhouse_sample.sql>`

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

- ClickHouse instance (local or remote) reachable from your workstation
- ``clickhouse-client`` CLI installed, **or** access to the ClickHouse HTTP interface
- A ClickHouse user with ``CREATE DATABASE``, ``CREATE TABLE``, ``INSERT`` privileges
- XLTable server already installed and running (see :doc:`install`)

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Download :download:`clickhouse_sample.sql <clickhouse_sample.sql>` and run it
against your ClickHouse instance using one of the options below.

**Option A — clickhouse-client with TLS (recommended)**

.. code-block:: bash

   clickhouse-client \
     --host     <your_clickhouse_host> \
     --port     9440 \
     --secure \
     --user     <user> \
     --password <password> \
     --multiline --multiquery \
     < clickhouse_sample.sql

**Option B — clickhouse-client without TLS**

.. code-block:: bash

   clickhouse-client \
     --host     <your_clickhouse_host> \
     --port     9000 \
     --user     <user> \
     --password <password> \
     --multiline --multiquery \
     < clickhouse_sample.sql

**Option C — HTTP interface (curl)**

.. code-block:: bash

   curl "https://<your_clickhouse_host>:8443/" \
     --user "<user>:<password>" \
     --data-binary @clickhouse_sample.sql

After a successful run the output should contain no errors.
Verify that all tables were created:

.. code-block:: sql

   SELECT table, count() AS rows
   FROM system.tables
   WHERE database = 'db'
   GROUP BY table
   ORDER BY table;

Expected output:

.. code-block:: text

   ┌─table────────────────┬──rows─┐
   │ Managers             │     5 │
   │ Models               │     8 │
   │ Regions              │     4 │
   │ Sales                │  3000 │
   │ Stock                │   500 │
   │ Stores               │     8 │
   │ Times                │  1096 │
   │ olap_definition      │     1 │
   └──────────────────────┴───────┘

------------------------------------------------------------

Step 2: Configure XLTable
--------------------------

Open ``/usr/olap/xltable/setting/settings.json`` and update the database
connection block:

.. code-block:: json

   {
       "SERVER_DB": "ClickHouse",
       "CREDENTIAL_DB": {
           "user": "<user>",
           "password": "<password>",
           "host": "<your_clickhouse_host>",
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

XLTable automatically discovers all cubes stored in the ``olap_definition``
table, so no additional cube configuration is needed.

------------------------------------------------------------

Step 3: Apply the settings
--------------------------

XLTable re-reads ``settings.json`` automatically within a few seconds of
saving — no restart is needed. If the service is not running yet, start it:

.. code-block:: bash

   sudo supervisorctl start olap

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
     - ``sum(sales.sum)``
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
To extend it to 2026, adjust the ``numbers()`` call and the CTE filter:

.. code-block:: sql

   -- In db.Times INSERT — add 365 days for 2026 (1096 + 365 = 1461)
   FROM numbers(1461);

Then update the cube definition inside ``db.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025', '2026')

**Add more stores or models**

Extend the ``INSERT INTO db.Stores`` / ``db.Models`` sections and update the
array literals in the ``db.Sales`` and ``db.Stock`` inserts accordingly.

**Use a different database name**

Replace every occurrence of ``db.`` with your own prefix, e.g. ``mydb.``.
Also update the ``host``, ``user``, and credentials in ``settings.json``.

------------------------------------------------------------

Troubleshooting
---------------

``DB::Exception: Database db doesn't exist``
    Make sure the first statement in the script ran successfully.
    Try running ``CREATE DATABASE IF NOT EXISTS db;`` manually first.

``DB::Exception: Syntax error`` near the INSERT statements
    Pass ``--multiline --multiquery`` flags to ``clickhouse-client``.
    Without them the client treats each line as a separate query.

``DB::Exception: Unknown identifier``
    Check that all tables were created and are non-empty before the cube
    definition insert: ``SELECT count() FROM db.Times;``

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: sql

       SELECT id FROM db.olap_definition;

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user.

``Access denied`` when running the script
    The ClickHouse user needs at minimum:
    ``CREATE DATABASE``, ``CREATE TABLE``, ``INSERT``, ``DROP TABLE`` on ``db.*``.

------------------------------------------------------------

Viewing XLTable query history
-----------------------------

Every SQL query sent by XLTable starts with a marker comment
``/* user:<name>, app:xltable */`` identifying the application and the
XLTable user. In ClickHouse the same marker is additionally set in the
``log_comment`` setting — a separate column of ``system.query_log`` that
allows exact filtering:

.. code-block:: sql

   SELECT
       event_time,
       query,
       user,
       query_duration_ms
   FROM system.query_log
   WHERE log_comment LIKE 'user:%, app:xltable'
   ORDER BY event_time DESC
   LIMIT 10;

See also :ref:`query_history_marker`.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: clickhouse_sample.sql
   :language: sql
