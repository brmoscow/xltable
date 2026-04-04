Snowflake Sample Data
=====================

This page describes a ready-to-run SQL script that creates a complete set of
sample Snowflake tables, fills them with test data, and registers the
``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.

The script file: :download:`snowflake_sample.sql <snowflake_sample.sql>`

------------------------------------------------------------

What the script creates
-----------------------

.. list-table::
   :header-rows: 1
   :widths: 28 8 64

   * - Table
     - Rows
     - Description
   * - ``olap.public.Times``
     - 731
     - Calendar: every day from 2023-01-01 to 2024-12-31
   * - ``olap.public.Regions``
     - 4
     - Sales regions: North, South, East, West
   * - ``olap.public.Managers``
     - 5
     - Sales managers linked to regions (many-to-many)
   * - ``olap.public.Stores``
     - 8
     - Retail stores, each assigned to a region
   * - ``olap.public.Models``
     - 8
     - Product models (Alpha … Theta)
   * - ``olap.public.Sales``
     - 3 000
     - Sales transactions: store, model, date, quantity, amount
   * - ``olap.public.Stock``
     - 500
     - Inventory snapshots: store, model, quantity on hand
   * - ``olap.public.olap_definition``
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

                     ┌──────────────────────────┐
                     │  olap.public.Times       │
                     │  (calendar)              │
                     └──────────┬───────────────┘
                                │ day_str
               ┌────────────────┴────────────────┐
               │                                 │
        ┌──────┴──────┐                   ┌──────┴──────┐
        │   .Sales    │                   │   .Stock    │
        └──────┬──────┘                   └──────┬──────┘
               │ store / model                   │ store / model
        ┌──────┴──────┐                   ┌──────┴──────┐
        │   .Stores   ├───────────────────┤   .Models   │
        └──────┬──────┘                   └─────────────┘
               │ region
        ┌──────┴──────┐
        │   .Regions  │
        └──────┬──────┘
               │ id  (many-to-many)
        ┌──────┴──────┐
        │  .Managers  │
        └─────────────┘

------------------------------------------------------------

Prerequisites
-------------

- A Snowflake account (Trial or paid)
- A user with **SYSADMIN** role or ``CREATE DATABASE`` privilege
- A running virtual warehouse (e.g. ``COMPUTE_WH``)
- **SnowSQL** CLI installed, or access to Snowflake Worksheets
- XLTable server already installed and running (see :doc:`install`)

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Download :download:`snowflake_sample.sql <snowflake_sample.sql>` and run it
using one of the options below.

**Option A — SnowSQL CLI**

.. code-block:: bash

   snowsql \
     --accountname <your_account> \
     --username    <user> \
     --dbname      olap \
     --schemaname  public \
     -f snowflake_sample.sql

**Option B — Snowflake Worksheets (Web UI)**

1. Open **Snowflake** → **Worksheets** → **+ New Worksheet**.
2. Paste the full contents of ``snowflake_sample.sql``.
3. Select your warehouse from the dropdown.
4. Click **Run All**.

After a successful run the output should contain no errors.
Verify that all tables were created:

.. code-block:: sql

   SELECT table_name, row_count
   FROM olap.information_schema.tables
   WHERE table_schema = 'PUBLIC'
   ORDER BY table_name;

Expected output:

.. code-block:: text

   ┌──────────────────────┬───────────┐
   │ TABLE_NAME           │ ROW_COUNT │
   ├──────────────────────┼───────────┤
   │ MANAGERS             │         5 │
   │ MODELS               │         8 │
   │ OLAP_DEFINITION      │         1 │
   │ REGIONS              │         4 │
   │ SALES                │      3000 │
   │ STOCK                │       500 │
   │ STORES               │         8 │
   │ TIMES                │       731 │
   └──────────────────────┴───────────┘

------------------------------------------------------------

Step 2: Configure XLTable
--------------------------

Open ``/usr/olap/xltable/setting/settings.json`` and update the database
connection block:

.. code-block:: json

   {
       "SERVER_DB": "Snowflake",
       "CREDENTIAL_DB": {
           "user":      "<user>",
           "password":  "<password>",
           "account":   "<your_account>",
           "warehouse": "COMPUTE_WH",
           "schema":    "olap.public"
       },
       "USERS": {"analyst": "password123"},
       "USER_GROUPS": {"analyst": ["olap_users"]}
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

The calendar is generated for 2023–2024.
To extend it to 2025, increase the generator row count and adjust the filter:

.. code-block:: sql

   -- In olap.public.Times — add 365 rows for 2025 (731 + 365 = 1096)
   FROM TABLE(GENERATOR(ROWCOUNT => 1096))

Then update the cube definition inside ``olap.public.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025')

**Add more stores or models**

Extend the ``VALUES`` lists in the ``olap.public.Stores`` / ``olap.public.Models``
sections. Update the ``CASE MOD(..., 8)`` expressions in the Sales and Stock
inserts accordingly, changing ``8`` to the new total count.

**Use a different database or schema**

Replace every occurrence of ``olap.public`` with your own database and schema.
Also update ``"schema"`` in ``settings.json``.

------------------------------------------------------------

Troubleshooting
---------------

``SQL compilation error: Database 'OLAP' does not exist``
    Run the first two statements manually:

    .. code-block:: sql

       CREATE DATABASE IF NOT EXISTS olap;
       USE DATABASE olap;

``Insufficient privileges to operate on database``
    Grant the required privileges or switch to a role that has them:

    .. code-block:: sql

       USE ROLE SYSADMIN;

``Virtual warehouse is suspended`` / query times out
    Resume the warehouse before running the script:

    .. code-block:: sql

       ALTER WAREHOUSE COMPUTE_WH RESUME;

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: sql

       SELECT id FROM olap.public.olap_definition;

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user.

``Invalid account identifier``
    The ``account`` field in ``settings.json`` must use the Snowflake account
    locator format, e.g. ``xy12345.eu-west-1``.
    Find it in **Snowflake UI → Admin → Accounts**.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: snowflake_sample.sql
   :language: sql
