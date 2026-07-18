BigQuery Sample Data
====================

This page describes a ready-to-run SQL script that creates a complete set of
sample BigQuery tables, fills them with test data, and registers the
``myOLAPcube`` OLAP cube from the :ref:`unified_example`.

Use this script to explore XLTable features without setting up your own data.

The script file: :download:`bigquery_sample.sql <bigquery_sample.sql>`

------------------------------------------------------------

What the script creates
-----------------------

.. list-table::
   :header-rows: 1
   :widths: 28 8 64

   * - Table
     - Rows
     - Description
   * - ``olap.Times``
     - 1096
     - Calendar: every day from 2023-01-01 to 2025-12-31
   * - ``olap.Regions``
     - 4
     - Sales regions: North, South, East, West
   * - ``olap.Managers``
     - 5
     - Sales managers linked to regions (many-to-many)
   * - ``olap.Stores``
     - 8
     - Retail stores, each assigned to a region
   * - ``olap.Models``
     - 8
     - Product models (Alpha … Theta)
   * - ``olap.Sales``
     - 3 000
     - Sales transactions: store, model, date, quantity, amount
   * - ``olap.Stock``
     - 500
     - Inventory snapshots: store, model, quantity on hand
   * - ``olap.olap_definition``
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

                     ┌──────────────────────┐
                     │  olap.Times    │
                     │  (calendar)          │
                     └──────────┬───────────┘
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

- A Google Cloud project with the **BigQuery API** enabled
- The ``olap`` dataset created in your project:

  .. code-block:: bash

     bq mk --dataset <project_id>:olap

- A service account (or user account) with the following IAM roles on the
  dataset: **BigQuery Data Editor** and **BigQuery Job User**
- A service account key file (JSON) downloaded to the XLTable server
- XLTable server already installed and running (see :doc:`install`)

------------------------------------------------------------

Step 1: Run the SQL script
--------------------------

Download :download:`bigquery_sample.sql <bigquery_sample.sql>` and run it
using one of the options below.

**Option A — bq CLI**

.. code-block:: bash

   bq query \
     --use_legacy_sql=false \
     --project_id=<your_project_id> \
     < bigquery_sample.sql

**Option B — BigQuery Studio (Cloud Console)**

1. Open the `BigQuery Studio <https://console.cloud.google.com/bigquery>`_ page.
2. Click **+ New query**.
3. Paste the full contents of ``bigquery_sample.sql`` into the editor.
4. Select your project from the project picker.
5. Click **Run**.

After a successful run the output should contain no errors.
Verify that all tables were created:

.. code-block:: sql

   SELECT table_id, row_count
   FROM `olap.__TABLES__`
   ORDER BY table_id;

Expected output:

.. code-block:: text

   ┌──────────────────────┬───────────┐
   │ table_id             │ row_count │
   ├──────────────────────┼───────────┤
   │ Managers             │         5 │
   │ Models               │         8 │
   │ Regions              │         4 │
   │ Sales                │      3000 │
   │ Stock                │       500 │
   │ Stores               │         8 │
   │ Times                │      1096 │
   │ olap_definition      │         1 │
   └──────────────────────┴───────────┘

------------------------------------------------------------

Step 2: Configure XLTable
--------------------------

Open ``/usr/olap/xltable/setting/settings.json`` and update the database
connection block:

.. code-block:: json

   {
       "SERVER_DB": "BigQuery",
       "CREDENTIAL_DB": {
           "key_path": "/path/to/service-account-key.json",
           "query_timeout": 300
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
To extend it to 2026, adjust the ``GENERATE_DATE_ARRAY`` end date:

.. code-block:: sql

   -- In olap.Times — extend end date by one year
   FROM UNNEST(GENERATE_DATE_ARRAY('2023-01-01', '2026-12-31')) AS day;

Then update the cube definition inside ``olap.olap_definition``:

.. code-block:: sql

   WHERE year_str IN ('2023', '2024', '2025', '2026')

**Add more stores or models**

Extend the ``UNNEST(ARRAY<STRUCT<...>>[...])`` literals in the
``olap.Stores`` / ``olap.Models`` sections.
Update the ``stores_arr`` / ``models_arr`` CTEs in the Sales and Stock
inserts accordingly, and adjust the ``% 8`` modulo to match the new count.

**Use a different dataset name**

Replace every occurrence of ``olap`` with your own dataset name.
Also update the ``key_path`` and ``project_id`` in ``settings.json``.

------------------------------------------------------------

Troubleshooting
---------------

``Not found: Dataset <project>:olap``
    Create the dataset first:

    .. code-block:: bash

       bq mk --dataset <project_id>:olap

``Access Denied: BigQuery BigQuery: Permission denied``
    Ensure the service account has **BigQuery Data Editor** and
    **BigQuery Job User** roles on the project or dataset.

``Syntax error`` near ``ARRAY<STRUCT<...>>``
    Make sure ``--use_legacy_sql=false`` is passed to the ``bq`` CLI.
    Legacy SQL does not support standard SQL type syntax.

``No cubes visible in Excel``
    Verify the definition row exists:

    .. code-block:: sql

       SELECT id FROM `olap.olap_definition`;

    Also confirm that ``USER_GROUPS`` in ``settings.json`` contains
    ``"olap_users"`` for the connecting user.

``key_path file not found`` on XLTable startup
    The service account JSON file must be accessible to the XLTable process.
    Use an absolute path and ensure file permissions allow the server user
    to read it.

------------------------------------------------------------

Viewing XLTable query history
-----------------------------

Every SQL query sent by XLTable starts with a marker comment
``/* user:<name>, app:xltable */`` identifying the application and the
XLTable user. The history is available via ``INFORMATION_SCHEMA.JOBS`` of
the region your datasets live in (replace ``region-eu`` with your region):

.. code-block:: sql

   SELECT creation_time, user_email, total_bytes_processed, query
   FROM `region-eu`.INFORMATION_SCHEMA.JOBS
   WHERE query LIKE '%app:xltable%'
   ORDER BY creation_time DESC
   LIMIT 10;

See also :ref:`query_history_marker`.

------------------------------------------------------------

Full script
-----------

.. literalinclude:: bigquery_sample.sql
   :language: sql
