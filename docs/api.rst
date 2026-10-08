.. _rest_api:

REST API
========

Since 2.1.3 XLTable exposes its cubes over plain HTTP: three endpoints
return the list of cubes, a cube schema and an aggregated pivot query as
JSON. It is the same engine, the same security roles, the same row-level
security, cache and logs that serve Excel PivotTables and AI assistants —
without XMLA and without an MCP client. Use it from ETL pipelines, scripts,
internal portals and BI tools that can call an HTTP endpoint.

As everywhere in XLTable, the API takes **names, not SQL**: the client sends
cube, dimension and measure names, the server builds and runs the query.
Raw SQL access to the warehouse is never exposed.

Endpoints
---------

.. list-table::
   :header-rows: 1
   :widths: 34 66

   * - Endpoint
     - What it returns
   * - ``GET /api/cubes``
     - ``{"cubes": [{"name": "Sales", "description": "…"}, …]}`` — the
       cubes of the catalog; ``description`` is present when the cube
       author wrote :tag:`olap_description`. The same list as the
       ``list_cubes`` MCP tool.
   * - ``GET /api/cubes/<cube>``
     - The cube schema: dimensions with their levels, measures, folders and
       the semantics from the cube definition (descriptions, synonyms,
       ``ai_instructions``) — the same document as the ``describe_cube``
       MCP tool. Add ``?samples=1`` to include ``sample_values`` of
       low-cardinality levels (fetched from the warehouse, see
       :ref:`mcp_semantics`).
   * - ``POST /api/query``
     - An aggregated pivot query. The JSON body is the pivot specification
       of the ``query_cube`` MCP tool (``cube``, ``dimensions``,
       ``measures``, ``filters``, ``limit``); the response carries the
       rows, the column types and a ``truncated`` flag — see below.

With the ``olap_definition`` cube source (``CUBE_SOURCE=database``) and
more than one database in the warehouse, pass the database name: a
``database`` query parameter on the ``GET`` endpoints, a ``database`` field
in the body of ``POST /api/query``. A single database is selected
automatically.

Query
-----

Request:

.. code-block:: json

   {
     "cube": "Sales",
     "dimensions": ["Store", "Month"],
     "measures": ["Amount", "Quantity"],
     "filters": [
       {"level": "Year", "type": "in", "values": ["2025"]},
       {"level": "Month", "type": "between", "values": ["2025-01", "2025-06"]}
     ],
     "limit": 1000
   }

``dimensions`` and ``measures`` are names from the cube schema (case
sensitive); at least one of them is required. ``filters`` are applied before
aggregation: ``in``, ``not_in`` and ``between`` (exactly ``[low, high]``). A
user's own access filters (row-level security) are always added on top of
the request filters and cannot be widened by them. ``limit`` caps the number
of result rows (1000 by default).

Response:

.. code-block:: json

   {
     "cube": "Sales",
     "columns": [
       {"name": "Store", "type": "string"},
       {"name": "Month", "type": "date"},
       {"name": "Amount", "type": "number"},
       {"name": "Quantity", "type": "number"}
     ],
     "rows": [
       {"Store": "North", "Month": "2025-01-01", "Amount": 1250.5, "Quantity": 42}
     ],
     "row_count": 1,
     "truncated": false
   }

``columns`` lists the result columns in order with a type for formatting and
sorting on the client — ``number``, ``string``, ``date`` or ``bool`` (dates
travel as ISO strings in JSON, so the type is the only way to tell them from
text). ``truncated: true`` means the query produced more rows than
``limit``; pass a larger ``limit`` for the rest. Every row is a full
combination of the requested levels — there are no subtotal rows; for totals
run another query with fewer dimensions (or none: only measures).

Example with ``curl`` and a user account:

.. code-block:: bash

   curl -u analyst:secret https://xltable.company.local/api/cubes

   curl -u analyst:secret -H "Content-Type: application/json" \
        -d '{"cube":"Sales","dimensions":["Store"],"measures":["Amount"]}' \
        https://xltable.company.local/api/query

Authorization
-------------

The data endpoints require a **user identity** — the engine applies the
user's cube roles and row-level security and counts the user's named seat,
exactly as for Excel or MCP. Any of the following works, in the server
edition:

- **OAuth 2.1 Bearer token** issued by the built-in authorization server
  (``Authorization: Bearer <access token>``) — the same token an MCP client
  obtains for ``/mcp`` (:ref:`mcp_oauth`): one token gives access to cubes
  through both MCP and the REST API. This is the way a browser application
  calls the API: the user signs in once at ``/oauth/authorize`` (by Kerberos
  behind an authenticating front, or with a login and password) and the page
  sends the token with every request;
- **HTTP Basic** with a user from :confval:`USERS` or a domain login and
  password (``curl -u user:password``) — for scripts and ETL;
- the same credentials packed as ``Authorization: Bearer <base64 of
  user:password>`` for tools whose authorization field only accepts a
  Bearer value;
- the identity established by an authenticating front (IIS Windows
  Authentication, Apache ``--auth ad``) when the API is called from a
  domain-joined machine.

A request without valid credentials gets ``401`` with both ``Bearer`` and
``Basic`` challenges in ``WWW-Authenticate``. The tokens from
:confval:`API_TOKENS` are **not** accepted here: they carry no user, so
there is nobody to apply roles to — they remain the credential of the
:ref:`cache management API <cache_api>` only. Give a pipeline its own user
in :confval:`USERS` instead.

A service account may act on behalf of other users with the
``X-Effective-User`` header — see :ref:`mcp_effective_user`; the header
works on ``/mcp`` and on the data endpoints alike.

The browser-side CSRF guard of ``/admin`` and ``/api`` does not apply to
requests with a ``Bearer`` header: a browser never attaches one on its own,
so a page that holds a token can call ``POST /api/query`` with it. Basic
credentials cached by the browser and identities established by an
authenticating front remain protected — a cross-site ``POST`` with them is
rejected.

In the **free desktop edition** the API needs no authorization, like
``/mcp``: it serves the single local user on ``127.0.0.1``.

Licensing
---------

In the server edition the REST API is a license feature flag of its own:
the boolean ``api`` field of the license. Without it every data endpoint
answers ``403`` with ``"REST API is not included in your license"``;
Excel and MCP are not affected (and the ``mcp`` flag does not open the
API — the two are independent). With the flag, named seats are counted per
user in the one shared pool: a user occupies one seat whether they come from
Excel, an AI assistant or the API. The license page of the admin console
shows **REST API: included** when the flag is present.

Errors
------

Errors come back as ``{"error": "<message>"}``:

.. list-table::
   :header-rows: 1
   :widths: 12 88

   * - Status
     - When
   * - ``400``
     - The request is not a JSON object, a cube, level or measure name is
       unknown, a filter is malformed, the database is unknown, or the
       engine refused the query (a cube closed to the user by its roles, a
       syntax problem in the cube definition). The message names the
       problem and, where it helps, the valid names.
   * - ``401`` / ``403``
     - No valid credentials / the user has no access, the license lacks the
       ``api`` flag or all named seats are taken.
   * - ``503``
     - The warehouse connection failed, or the server is overloaded
       (:confval:`OVERLOAD_GUARD`) — retry later. The cube list and a
       schema without ``samples`` are served even under overload, like
       Discover for Excel.

Logging and cache
-----------------

API queries go through the same path as MCP queries: with
:confval:`WRITE_LOG` the console shows the ``PIVOT SPEC``, ``SQL`` and
``RESULT`` blocks, the ``log`` folder gets the SQL and Jinja dumps, and the
shared SQL result cache serves identical queries to Excel, assistants and
API clients alike (see :ref:`mcp_logging`).
