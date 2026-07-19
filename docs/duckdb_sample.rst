DuckDB Sample Data
==================

This page describes a ready-to-run SQL script that creates a complete set of
sample tables inside a DuckDB database file, fills them with test data, and
registers the ``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.
DuckDB is an embedded database — there is no separate database server to
install: the whole database lives in a single file next to XLTable.

The script file: :download:`duckdb_sample.sql <duckdb_sample.sql>`

------------------------------------------------------------

What the script creates
-----------------------

The script creates a schema named ``db`` inside your DuckDB database file.
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

- DuckDB CLI (`installation guide <https://duckdb.org/docs/installation>`_)
  or Python with the ``duckdb`` package (``pip install duckdb``)
- XLTable server already installed and running (see :doc:`install`)

No database server, user accounts or network configuration are needed —
the script creates a regular file on disk.

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Download :download:`duckdb_sample.sql <duckdb_sample.sql>` and run it to
create the database file. Place the file where the XLTable service can read
it, e.g. ``/usr/olap/xltable/data/`` on Linux.

**Option A — DuckDB CLI**

.. code-block:: bash

   mkdir -p /usr/olap/xltable/data
   duckdb /usr/olap/xltable/data/sample.duckdb -f duckdb_sample.sql

**Option B — Python**

.. code-block:: bash

   python -c "import duckdb; duckdb.connect('/usr/olap/xltable/data/sample.duckdb').execute(open('duckdb_sample.sql').read())"

Verify that all tables were created:

.. code-block:: bash

   duckdb -readonly /usr/olap/xltable/data/sample.duckdb \
     "SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'db' ORDER BY table_name"

Expected output:

.. code-block:: text

   ┌─────────────────┬───────┐
   │   table_name    │ rows  │
   ├─────────────────┼───────┤
   │ managers        │     5 │
   │ models          │     8 │
   │ olap_definition │     1 │
   │ regions         │     4 │
   │ sales           │  3000 │
   │ stock           │   500 │
   │ stores          │     8 │
   │ times           │  1096 │
   └─────────────────┴───────┘

------------------------------------------------------------

Step 2: Configure XLTable
--------------------------

Open ``/usr/olap/xltable/setting/settings.json`` and update the database
connection block:

.. code-block:: json

   {
       "SERVER_DB": "DuckDB",
       "CREDENTIAL_DB": {
           "database": "/usr/olap/xltable/data/sample.duckdb",
           "read_only": true,
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

Use an **absolute path** in ``database`` so it does not depend on the service
working directory. Keep ``read_only: true`` (the default): XLTable only reads
the data, and read-only mode lets several XLTable worker processes open the
same database file simultaneously.

Make sure the file is readable by the account the XLTable service runs under
(``user=`` in ``olap.conf``, usually ``olap``):

.. code-block:: bash

   sudo chown olap /usr/olap/xltable/data/sample.duckdb

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

Using your own data
-------------------

DuckDB can query Parquet and CSV files directly, so a cube can be built on
top of plain files without importing them into tables — reference them in
the cube definition the same way as tables:

.. code-block:: sql

   FROM read_parquet('/usr/olap/xltable/data/sales/*.parquet') sales

Only the ``olap_definition`` table itself has to exist inside the ``.duckdb``
file.

------------------------------------------------------------

Customising the script
-----------------------

**Change the date range**

The calendar is generated for 2023–2025 using ``generate_series``.
To extend it to 2026, change the end date and update the cube filter:

.. code-block:: sql

   -- In db.times INSERT — extend generate_series to 2026-12-31
   FROM generate_series(DATE '2023-01-01', DATE '2026-12-31', INTERVAL 1 DAY) AS t(d);

Then update the cube definition inside ``db.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025', '2026')

**Add more stores or models**

Extend the ``INSERT INTO db.stores`` / ``db.models`` sections and update the
``CASE`` expressions in the ``db.sales`` and ``db.stock`` inserts accordingly.

**Use a different schema**

Replace every occurrence of ``db.`` with your own prefix, e.g. ``myschema.``.

------------------------------------------------------------

Troubleshooting
---------------

``IO Error: Could not set lock on file``
    Another process holds a **read-write** connection to the database file
    (for example, an open DuckDB CLI session without ``-readonly``).
    Close it, and keep ``read_only: true`` in ``settings.json`` — read-only
    connections do not conflict with each other.

``IO Error: Cannot open file`` / ``Permission denied``
    The XLTable service account cannot read the file. Check the path in
    ``settings.json`` (use an absolute path) and the file permissions
    (``chown olap`` on Linux).

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: bash

       duckdb -readonly /usr/olap/xltable/data/sample.duckdb "SELECT id FROM db.olap_definition"

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user.

``Catalog Error: Table with name ... does not exist``
    The script did not run against the same file XLTable opens — compare the
    path used in Step 1 with ``database`` in ``settings.json``.

------------------------------------------------------------

Viewing XLTable query history
-----------------------------

DuckDB is embedded and has no server-side query history. To see the SQL
queries XLTable executes, set ``WRITE_LOG=true`` in ``settings.json``
(picked up automatically, no restart needed) and check the XLTable logs —
see :ref:`enable_logging`.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: duckdb_sample.sql
   :language: sql
