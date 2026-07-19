
XLTable Documentation
=====================

**Semantic Layer for Big Data.**

Self-service analytics on big data — governed by IT, loved by users.

XLTable is an XMLA-compatible OLAP semantic layer for modern analytical
databases. Business users explore data in native **Excel Pivot Tables** or ask
questions in plain language through AI assistants — no SQL for end users, no
data copies, no add-ins, no BI tools in between. Excel becomes the front end,
your warehouse stays the single source of truth, and XLTable deploys inside
your perimeter: IT defines models, access rights and performance centrally,
while business users keep working in the tool they know best.

.. grid:: 1 2 2 3
   :gutter: 3

   .. grid-item-card:: :octicon:`rocket;1em` Quickstart
      :link: quickstart
      :link-type: doc

      Deploy XLTable, connect a database and open your first
      Pivot Table — in under an hour.

   .. grid-item-card:: :octicon:`book;1em` About XLTable
      :link: overview
      :link-type: doc

      Architecture, comparison with SSAS, deployment steps
      and system requirements.

   .. grid-item-card:: :octicon:`server;1em` Installation
      :link: install
      :link-type: doc

      Installation on Linux and Windows, authentication,
      Active Directory and database connections.

   .. grid-item-card:: :octicon:`stack;1em` OLAP cubes
      :link: cubes
      :link-type: doc

      Measures, dimensions, hierarchies, security roles and
      drillthrough — all defined in plain SQL.

   .. grid-item-card:: :octicon:`code;1em` Jinja templating
      :link: jinja
      :link-type: doc

      Adapt the generated SQL dynamically: row-level security,
      relative dates, conditional logic.

   .. grid-item-card:: :octicon:`table;1em` Connecting Excel
      :link: excel
      :link-type: doc

      Connect Pivot Tables over XMLA, authentication modes,
      data refresh and drill through.

Supported data sources
----------------------

All heavy computation runs inside your database — XLTable pushes queries down
to your warehouse, with no extracts and no in-memory copies. A read-only
service account is all it needs.

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Database
     - Ready-to-run sample
   * - ClickHouse (22.5+)
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

Why XLTable?
------------

- Native Excel Pivot Tables on big data — drag-and-drop over the standard
  SSAS/XMLA workflow, no SQL, no retraining
- Centralized semantic layer: dimensions, measures, hierarchies, calculated fields
- One model, two ways to explore: the same cube answers Excel Pivot Tables
  and AI assistants (MCP connector)
- Code-first: cube definitions are plain SQL files — keep them in Git, review
  changes in pull requests, deploy through your CI/CD flow
- Fine-grained access control down to rows and members, Active Directory / LDAP integration
- Your data never leaves: queries run inside your warehouse, XLTable deploys
  inside your perimeter
- Query result caching for a fast Excel experience
- Self-hosted on Linux or Windows, on-premise or in the cloud

Getting help
------------

.. grid:: 1 3 3 3
   :gutter: 3

   .. grid-item-card:: :octicon:`globe;1em` Website
      :link: https://xltable.com

      Product overview, pricing and trial requests.

   .. grid-item-card:: :octicon:`comment-discussion;1em` Telegram
      :link: https://t.me/XLTable

      News, releases and quick answers from the team.

   .. grid-item-card:: :octicon:`mail;1em` Email
      :link: mailto:help@xltable.com

      help@xltable.com — support and licensing.

Working with ChatGPT, Claude or another AI assistant? Give it the whole
documentation as a single file — see :doc:`ai`.

.. toctree::
   :maxdepth: 1
   :caption: Getting started
   :hidden:

   overview
   quickstart
   install
   excel
   cache

.. toctree::
   :maxdepth: 1
   :caption: Building cubes
   :hidden:

   cubes
   jinja
   reference

.. toctree::
   :maxdepth: 1
   :caption: Sample data
   :hidden:

   clickhouse_sample
   bigquery_sample
   snowflake_sample
   trino_sample
   greenplum_sample
   starrocks_sample
   databricks_sample
   duckdb_sample

.. toctree::
   :maxdepth: 1
   :caption: Project
   :hidden:

   faq
   support
   ai
   changelog
   backlog
