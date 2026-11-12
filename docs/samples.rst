.. _samples:

Sample data
===========

Every supported database has a ready-to-run SQL script that creates a small
set of sample tables, fills them with test data and registers the same cube —
``myOLAPcube`` from the :ref:`unified_example`. Use it to try XLTable on your
own warehouse without preparing data: run the script, point XLTable at the
database, connect Excel. Each page below walks through these steps and ends
with the full script.

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Database
     - Sample
   * - ClickHouse
     - :doc:`clickhouse_sample`
   * - BigQuery
     - :doc:`bigquery_sample`
   * - Snowflake
     - :doc:`snowflake_sample`
   * - Trino
     - :doc:`trino_sample`
   * - Greenplum
     - :doc:`greenplum_sample`
   * - StarRocks
     - :doc:`starrocks_sample`
   * - Databricks
     - :doc:`databricks_sample`
   * - DuckDB
     - :doc:`duckdb_sample`

.. tip::

   No warehouse at hand? XLTable Desktop needs none of this to get started:
   a fresh installation comes with built-in demo data and two ready cubes
   (see :ref:`demo_data`), and the public demo server at
   https://xltable.com/demo needs no installation at all.

.. toctree::
   :maxdepth: 1
   :hidden:

   clickhouse_sample
   bigquery_sample
   snowflake_sample
   trino_sample
   greenplum_sample
   starrocks_sample
   databricks_sample
   duckdb_sample
