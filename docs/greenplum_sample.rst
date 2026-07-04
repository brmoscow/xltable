Greenplum Sample Data
=====================

This page describes a ready-to-run SQL script that creates a complete set of
sample Greenplum tables, fills them with test data, and registers the
``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.

The script file: :download:`greenplum_sample.sql <greenplum_sample.sql>`

------------------------------------------------------------

What the script creates
-----------------------

The script creates a schema named ``db`` inside your Greenplum database.
Replace every occurrence of ``db.`` with ``<your_schema>.`` before running
if your setup differs.

.. list-table::
   :header-rows: 1
   :widths: 22 8 70

   * - Table
     - Rows
     - Description
   * - ``db.times``
     - 1096
     - Calendar: every day from 2023-01-01 to 2025-12-31
   * - ``db.regions``
     - 4
     - Sales regions: North, South, East, West
   * - ``db.managers``
     - 5
     - Sales managers linked to regions (many-to-many)
   * - ``db.stores``
     - 8
     - Retail stores, each assigned to a region
   * - ``db.models``
     - 8
     - Product models (Alpha … Theta)
   * - ``db.sales``
     - 3 000
     - Sales transactions: store, model, date, quantity, amount
   * - ``db.stock``
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
                     │  db.times   │
                     │  (calendar) │
                     └──────┬──────┘
                            │ day_str
               ┌────────────┴────────────┐
               │                         │
        ┌──────┴──────┐           ┌──────┴──────┐
        │  db.sales   │           │  db.stock   │
        └──────┬──────┘           └──────┬──────┘
               │ store / model           │ store / model
        ┌──────┴──────┐           ┌──────┴──────┐
        │  db.stores  ├───────────┤  db.models  │
        └──────┬──────┘           └─────────────┘
               │ region
        ┌──────┴──────┐
        │ db.regions  │
        └──────┬──────┘
               │ id  (many-to-many)
        ┌──────┴──────┐
        │db.managers  │
        └─────────────┘

------------------------------------------------------------

Prerequisites
-------------

- Greenplum instance (local or remote) reachable from your workstation
- ``psql`` CLI installed (bundled with Greenplum or PostgreSQL client tools)
- A Greenplum user with ``CREATE SCHEMA``, ``CREATE TABLE``, ``INSERT``
  privileges on the target database
- XLTable server already installed and running (see :doc:`install`)

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Download :download:`greenplum_sample.sql <greenplum_sample.sql>` and run it
against your Greenplum instance using one of the options below.

**Option A — psql with TLS (recommended)**

.. code-block:: bash

   psql "host=<your_greenplum_host> \
         port=6432 \
         dbname=<database> \
         user=<user> \
         password=<password> \
         sslmode=require" \
     -f greenplum_sample.sql

**Option B — psql without TLS**

.. code-block:: bash

   psql "host=<your_greenplum_host> \
         port=6432 \
         dbname=<database> \
         user=<user> \
         password=<password>" \
     -f greenplum_sample.sql

**Option C — connection URL**

.. code-block:: bash

   psql postgresql://<user>:<password>@<your_greenplum_host>:6432/<database>?sslmode=require \
     -f greenplum_sample.sql

After a successful run the output should contain no errors.
Verify that all tables were created:

.. code-block:: sql

   SELECT 'managers'        AS "table", COUNT(*) AS rows FROM db.managers
   UNION ALL
   SELECT 'models',                     COUNT(*) FROM db.models
   UNION ALL
   SELECT 'olap_definition',            COUNT(*) FROM db.olap_definition
   UNION ALL
   SELECT 'regions',                    COUNT(*) FROM db.regions
   UNION ALL
   SELECT 'sales',                      COUNT(*) FROM db.sales
   UNION ALL
   SELECT 'stock',                      COUNT(*) FROM db.stock
   UNION ALL
   SELECT 'stores',                     COUNT(*) FROM db.stores
   UNION ALL
   SELECT 'times',                      COUNT(*) FROM db.times
   ORDER BY "table";

Expected output:

.. code-block:: text

        table       | rows
   -----------------+------
    managers        |    5
    models          |    8
    olap_definition |    1
    regions         |    4
    sales           | 3000
    stock           |  500
    stores          |    8
    times           | 1096

------------------------------------------------------------

Step 2: Configure XLTable
--------------------------

Open ``/usr/olap/xltable/setting/settings.json`` and update the database
connection block:

.. code-block:: json

   {
       "SERVER_DB": "Greenplum",
       "CREDENTIAL_DB": {
           "host": "<your_greenplum_host>",
           "port": 6432,
           "sslmode": "require",
           "dbname": "<database>",
           "user": "<user>",
           "password": "<password>",
           "target_session_attrs": "read-write"
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

The calendar is generated for 2023–2025 using ``generate_series``.
To extend it to 2026, change the end date and update the cube filter:

.. code-block:: sql

   -- In db.times INSERT — extend generate_series to 2026-12-31
   FROM generate_series('2023-01-01'::date, '2026-12-31'::date, '1 day'::interval) AS d;

Then update the cube definition inside ``db.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025', '2026')

**Add more stores or models**

Extend the ``INSERT INTO db.stores`` / ``db.models`` sections and update the
``CASE`` expressions in the ``db.sales`` and ``db.stock`` inserts accordingly.

**Use a different schema**

Replace every occurrence of ``db.`` with your own prefix, e.g. ``myschema.``.
Also update the ``host``, ``dbname``, ``user``, and credentials in
``settings.json``.

------------------------------------------------------------

Troubleshooting
---------------

``ERROR: schema "db" does not exist``
    The first statement in the script did not run successfully.
    Try running ``CREATE SCHEMA IF NOT EXISTS db;`` manually first.

``ERROR: permission denied for schema db``
    The Greenplum user needs at minimum:
    ``CREATE``, ``USAGE`` on the schema, and ``CREATE TABLE``, ``INSERT``
    on the database.
    Grant them with:

    .. code-block:: sql

       GRANT USAGE, CREATE ON SCHEMA db TO <user>;

``ERROR: column "hashtext" does not exist`` or syntax errors
    Make sure you are connecting to a Greenplum (or PostgreSQL ≥ 9.4) instance.
    The ``hashtext`` function and ``generate_series`` with dates are built-in
    and require no extensions.

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: sql

       SELECT id FROM db.olap_definition;

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user.

``Access denied`` when running the script
    The Greenplum user needs at minimum:
    ``CREATE SCHEMA``, ``CREATE TABLE``, ``INSERT``, ``DROP TABLE`` on the
    target database and schema.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: greenplum_sample.sql
   :language: sql
