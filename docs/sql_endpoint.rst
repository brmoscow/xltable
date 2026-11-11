.. _sql_endpoint:

SQL endpoint
============

Since 2.1.5 XLTable can serve its cubes to BI tools as PostgreSQL tables.
The *SQL endpoint* is a separate service that speaks the PostgreSQL wire
protocol: DataLens, DBeaver, ``psql`` — a client with a PostgreSQL
driver — connects to it as to a regular database
and sees every cube as a flat table whose columns are the hierarchy levels
and the measures. A plain ``SELECT … WHERE … GROUP BY`` is translated into a
pivot query of the same engine that serves Excel, AI assistants and the
:doc:`REST API <api>`: the same users, cube roles, row-level security,
result cache and logs. Raw SQL never reaches the warehouse — the endpoint
only ever asks the engine for aggregated pivot results.

.. note::

   Power BI is **not** a target of the SQL endpoint. Mature semantic layers
   connect Power BI through the Analysis Services protocol (XMLA with DAX
   queries) rather than through a PostgreSQL connection; XLTable's XMLA
   endpoint is the same one Excel uses (:doc:`excel`), and DAX support is
   on the :doc:`roadmap <backlog>`. A PostgreSQL-protocol connection from
   Power BI (Import or DirectQuery) is possible in principle but is neither
   tested nor supported.

How it works
------------

::

   BI tool (PostgreSQL driver)
         │  PostgreSQL protocol, TLS, port 5433
         ▼
   XLTable SQL endpoint  (python xlmain.py sql-endpoint / main.bin sql-endpoint)
         │  REST API, loopback, the BI user's own credentials
         ▼
   XLTable server  —  authentication, roles, RLS, cache, SQL to the warehouse

The endpoint keeps a small in-memory catalogue (``pg_catalog``,
``information_schema``) built from the cubes the signed-in user may see,
so schema browsers and ORMs work as with PostgreSQL. Every data query goes
to the server as a pivot specification (cube, levels, measures, filters)
through ``POST /api/query``; the result is then finished locally
(``HAVING``, ``ORDER BY``, ``LIMIT``, expressions over measures) and
returned to the client.

Installation
------------

1. Add the :confval:`SQL_ENDPOINT` section to ``settings.json`` and set
   ``enabled`` to ``true``. Outside of ``127.0.0.1`` a TLS certificate is
   required (``tls``): the PostgreSQL protocol sends the password in clear
   text inside the encrypted connection. The same certificate as for the
   HTTPS front can be used. With a certificate configured the endpoint
   refuses connections that do not negotiate TLS — a client with
   ``sslmode=prefer`` that does not trust the certificate otherwise falls
   back to plain text silently.

2. Start the service next to the XLTable workers:

   - **Windows Server (IIS)** — the endpoint runs with the Python
     environment of the IIS application, from the application folder:
     ``.venv\Scripts\python.exe xlmain.py sql-endpoint``. Register it as a
     Windows service with `NSSM <https://nssm.cc/>`_ (``nssm install
     XLTableSQL C:\olap\xltable\.venv\Scripts\python.exe xlmain.py
     sql-endpoint``, *Startup directory* = ``C:\olap\xltable``); the service
     runs under an account that can read ``settings.json`` and write
     ``log\``. Under IIS the application is served by the site, not on
     :confval:`SERVER_PORT`, so set ``server_url`` in :confval:`SQL_ENDPOINT`
     to the local address of the site, for example ``http://127.0.0.1``.
     See the installer README, *SQL endpoint*.
   - **Ubuntu** — a supervisor program from the installer template
     ``install_ubuntu/templates/olap-sql.conf.tmpl`` (see the installer
     README, *SQL endpoint*).
   - **Trying it out** — the same command in a console (``main.bin
     sql-endpoint`` on Ubuntu) prints the listening address; ``Ctrl+C``
     stops it.

3. Open port 5433 on the firewall for the BI servers. For a cloud BI
   (DataLens) the endpoint needs a public address and a certificate the BI
   trusts — a self-signed one works when its CA is uploaded in the BI
   connection settings.

The endpoint is a feature of the server edition under its own license flag:
the license must carry ``"sql": true`` (the admin console shows *SQL
endpoint: included*). XLTable Desktop (the free edition) does not include
it. Seats are the usual named users: the account a BI tool signs in with
takes one seat.

Connecting a BI tool
--------------------

Connection parameters are those of a PostgreSQL database:

.. list-table::
   :widths: 24 76

   * - Host, port
     - the server running the endpoint, ``5433``
   * - Database
     - the XLTable database (catalog) the cubes live in — the name shown in
       Excel when choosing a cube. A server with a single database accepts
       any name.
   * - User, password
     - an XLTable user: a local account from :confval:`USERS` or a domain
       account with its domain password. Windows single sign-on and API
       tokens are not available through the PostgreSQL protocol.
   * - SSL
     - *require* (DataLens: *TLS on*, upload the CA of a self-signed
       certificate — with *TLS off* DataLens is refused by a server that
       has a certificate); *disable* only for ``127.0.0.1``.

- **DataLens** — connection type *PostgreSQL*, host and port of the
  endpoint, the server's public address must be reachable from the DataLens
  subnets. Create a dataset from a cube table; set the aggregation of each
  measure field to *Sum* (or *None* to take the cube's own aggregate — see
  below), of dimension fields to *None*.
- **DBeaver, psql, other SQL clients** — a PostgreSQL connection; the cube
  tables are in schema ``public``.

A BI tool connects with **one** account per connection: everybody who opens
a dashboard sees the data that account may see. Create a dedicated XLTable
account for each BI connection and give it the cube roles that match the
audience of the dashboards.

Cube as a table
---------------

Each cube is a table in schema ``public`` named after the cube. Columns:

- every level of every hierarchy, as text (``character varying``); a day
  level of a calendar hierarchy (``--date=`day```, :ref:`smart measures
  <smart_measures>`) is a ``date`` column, so date functions and date
  filters of the BI work on it;
- every measure, as ``double precision``.

The table has no rows of its own: a query is always answered by the engine
at the granularity the query asks for. What the engine computes is
decided by the query shape:

.. code-block:: sql

   SELECT "Region", "Year", SUM("Sales Amount") AS amount, SUM("Sales Quantity") AS qty
   FROM "SalesCube"
   WHERE "Year" IN ('2025', '2026') AND "Store" <> 'Online'
   GROUP BY "Region", "Year"
   HAVING SUM("Sales Quantity") > 100
   ORDER BY amount DESC
   LIMIT 50

- levels in ``SELECT``, ``GROUP BY``, ``ORDER BY`` or ``HAVING`` become the
  axes of the pivot query;
- ``WHERE`` conditions on levels become the filters: ``=``, ``<>``, ``IN``,
  ``NOT IN``, ``BETWEEN``, ``>=`` together with ``<=`` on the same level,
  combined with ``AND``. A text level that holds days as ``YYYY-MM-DD`` can
  be filtered as a date — ``CAST("Day" AS DATE) BETWEEN …`` — which is what
  the calendar selector of DataLens sends for a ``DATE([Day])`` field;
- measures are requested under an aggregate, under ``MEASURE(…)`` or as a
  bare column (then ``GROUP BY`` is implied by the levels in the query);
- ``HAVING``, ``ORDER BY``, ``LIMIT``/``OFFSET`` and expressions over
  measures (``SUM("Amount") / SUM("Quantity")``) are applied to the pivot
  result; an outer ``SELECT * FROM (…) AS t LIMIT n`` that BI tools wrap
  around a query is fine.

A table preview — plain columns with ``LIMIT`` up to 1000 and no
``GROUP BY``, aggregates or ``ORDER BY``, as the dataset editor of DataLens
or the data tab of DBeaver send it — is not computed at the full granularity
of the cube. The endpoint first picks a few members of the finest level of
every hierarchy in the query that have data and then asks the engine for
that slice only. The rows are real cells of the cube with correct values;
which rows come back is arbitrary, as with any ``LIMIT`` without
``ORDER BY``.

Measures and aggregates
~~~~~~~~~~~~~~~~~~~~~~~

The cube defines how a measure is aggregated; the SQL only names it. The
aggregate function in the query must match the measure:

- a ``sum`` measure accepts ``SUM("m")``;
- a ``count`` measure accepts ``COUNT("m")`` and ``SUM("m")``;
- ``min`` / ``max`` measures accept ``MIN`` / ``MAX``;
- any measure accepts ``MEASURE("m")`` and the bare column ``"m"`` — the
  value the cube computes for the group;
- averages, distinct counts, ratios, semi-additive balances (``--semi``) and
  other non-additive measures are available only through ``MEASURE("m")`` or
  the bare column: ``AVG("Avg Price")`` or ``SUM("Avg Price")`` is rejected
  with an error that names the measure, because a BI-side re-aggregation of
  such a measure would be a wrong number shown with confidence;
- for the same reason a non-additive measure cannot be regrouped by an
  expression over a level: ``GROUP BY date_trunc('month', "Day")`` with
  ``MEASURE("Avg Price")`` is rejected — group by the level of the cube
  (``"Month"``) instead. Additive measures are regrouped freely.

``COUNT(*)`` is not supported — use a count measure of the cube.

Totals
~~~~~~

The endpoint returns the groups the query asks for; grand totals and
subtotals that a BI tool draws under a table are computed by the BI from
those groups. For additive measures (sums, counts) this is exact. For
non-additive measures (averages, distinct counts, ratios, balances with
``--semi``) a BI-side total is wrong by construction — ask the engine for
the total instead, with a query without the level (``SELECT
MEASURE("Avg Price") FROM "SalesCube"``), or build such tables in Excel or
the :doc:`web pivot <reports>`, where totals come from the engine.

Limits
~~~~~~

Rejected with a clear error (SQLSTATE ``0A000``): ``JOIN``, ``UNION``,
CTE (``WITH``), window functions, subqueries inside the cube query,
``COUNT(*)``, filters on measures in ``WHERE`` (use ``HAVING``), ``OR``
between different levels (use ``IN`` for one level), strict ``<`` / ``>``
(use ``BETWEEN`` or ``>=`` / ``<=``), functions over levels other than on
``date`` columns, DDL and DML.

A query whose pivot result exceeds ``SQL_ENDPOINT.max_rows`` (100 000 by
default) fails instead of being silently cut: add filters or aggregate by
fewer levels. Raw row-level data is not available — the endpoint serves
aggregates; for a full detailed export use :doc:`export <export>`.

Logs
----

The endpoint writes ``log/sql_endpoint.txt`` (rotated daily, kept for
:confval:`LOG_RETENTION_DAYS`): sign-ins, every pivot specification it
sends, errors. The server side logs the forwarded
queries like any other REST API call, under the BI user's name.
