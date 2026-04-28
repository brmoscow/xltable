Trino Sample Data
=================

This page describes a ready-to-run SQL script that creates a complete set of
sample Trino tables, fills them with test data, and registers the
``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.

The script file: :download:`trino_sample.sql <trino_sample.sql>`

------------------------------------------------------------

What the script creates
-----------------------

The script uses **catalog** ``hive`` and **schema** ``db`` by default.
Replace every occurrence of ``hive.db`` with ``<your_catalog>.<your_schema>``
before running if your setup differs.

.. list-table::
   :header-rows: 1
   :widths: 26 8 66

   * - Table
     - Rows
     - Description
   * - ``hive.db.Times``
     - 731
     - Calendar: every day from 2023-01-01 to 2024-12-31
   * - ``hive.db.Regions``
     - 4
     - Sales regions: North, South, East, West
   * - ``hive.db.Managers``
     - 5
     - Sales managers linked to regions (many-to-many)
   * - ``hive.db.Stores``
     - 8
     - Retail stores, each assigned to a region
   * - ``hive.db.Models``
     - 8
     - Product models (Alpha … Theta)
   * - ``hive.db.Sales``
     - 3 000
     - Sales transactions: store, model, date, quantity, amount
   * - ``hive.db.Stock``
     - 500
     - Inventory snapshots: store, model, quantity on hand
   * - ``hive.db.olap_definition``
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

- Trino cluster (local or remote) reachable from your workstation
- ``trino`` CLI installed (available at `trino.io/download <https://trino.io/download.html>`_)
- A catalog configured in Trino (e.g. ``hive``, ``iceberg``, ``delta``)
- A Trino user with ``CREATE SCHEMA``, ``CREATE TABLE``, ``INSERT`` privileges
- XLTable server already installed and running (see :doc:`install`)

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Before running, open :download:`trino_sample.sql <trino_sample.sql>` and
replace every occurrence of ``hive.db`` with your actual
``<catalog>.<schema>``.

Then execute it using one of the options below.

**Option A — Trino CLI with TLS (recommended)**

.. code-block:: bash

   trino --server     https://<your_trino_host>:8443 \
         --user       <user> \
         --password \
         --file       trino_sample.sql

**Option B — Trino CLI without TLS**

.. code-block:: bash

   trino --server http://<your_trino_host>:8080 \
         --user   <user> \
         --file   trino_sample.sql

After a successful run the output should contain no errors.
Verify that all tables were created and populated:

.. code-block:: sql

   SELECT 'Times'            AS "table", COUNT(*) AS rows FROM hive.db.Times
   UNION ALL SELECT 'Regions',            COUNT(*) FROM hive.db.Regions
   UNION ALL SELECT 'Managers',           COUNT(*) FROM hive.db.Managers
   UNION ALL SELECT 'Stores',             COUNT(*) FROM hive.db.Stores
   UNION ALL SELECT 'Models',             COUNT(*) FROM hive.db.Models
   UNION ALL SELECT 'Sales',              COUNT(*) FROM hive.db.Sales
   UNION ALL SELECT 'Stock',              COUNT(*) FROM hive.db.Stock
   UNION ALL SELECT 'olap_definition',    COUNT(*) FROM hive.db.olap_definition
   ORDER BY "table";

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
   Times            |  731
   olap_definition  |    1

------------------------------------------------------------

Step 2: Configure XLTable
--------------------------

Open ``/usr/olap/xltable/setting/settings.json`` and update the database
connection block:

.. code-block:: json

   {
       "SERVER_DB": "Trino",
       "CREDENTIAL_DB": {
           "host": "<your_trino_host>",
           "port": 8443,
           "user": "<user>",
           "password": "<password>",
           "catalog": "hive",
           "http_scheme": "https",
           "verify": false
       },
       "USERS": {"analyst": "password123"},
       "USER_GROUPS": {"analyst": ["olap_users"]}
       ...
   }

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
3. Log in with ``analyst / password123``.
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

**Change the catalog or schema**

Do a global search-and-replace in ``trino_sample.sql``:
``hive.db``  →  ``<your_catalog>.<your_schema>``.
Also update ``catalog`` in ``settings.json`` accordingly.

**Change the date range**

The calendar is generated for 2023–2024.
To extend it to 2025, adjust the ``SEQUENCE`` upper bound:

.. code-block:: sql

   -- In hive.db.Times INSERT — add 365 days for 2025 (730 + 365 = 1095)
   FROM UNNEST(SEQUENCE(0, 1095)) AS t(n);

Then update the cube definition inside ``hive.db.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025')

**Add more stores or models**

Extend the ``INSERT INTO hive.db.Stores`` / ``hive.db.Models`` sections and
update the ``CASE`` blocks in the ``hive.db.Sales`` and ``hive.db.Stock``
inserts accordingly.

**Use a different schema name**

Replace every occurrence of ``hive.db.`` with your preferred
``<catalog>.<schema>.``, including inside the OLAP cube definition string
stored in ``hive.db.olap_definition``.

------------------------------------------------------------

Troubleshooting
---------------

``Schema not found: hive.db``
    Make sure the first statement ran successfully.
    Try running ``CREATE SCHEMA IF NOT EXISTS hive.db;`` manually first,
    or verify the catalog name with ``SHOW CATALOGS;``.

``Catalog 'hive' does not exist``
    Replace ``hive`` throughout the script with the name of a catalog
    actually configured in your Trino cluster.
    Check available catalogs with ``SHOW CATALOGS;``.

``Table not found`` during INSERT
    The corresponding ``CREATE TABLE`` did not succeed.
    Re-run the ``CREATE TABLE`` block for that table manually and check for
    permission errors.

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: sql

       SELECT id FROM hive.db.olap_definition;

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user.

``Access denied`` when running the script
    The Trino user needs at minimum:
    ``CREATE SCHEMA``, ``CREATE TABLE``, ``INSERT``, ``DROP TABLE``
    on the target catalog and schema.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: trino_sample.sql
   :language: sql
