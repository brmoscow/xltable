
Caching
=======

Caching is what keeps Excel fast on big data: repeated report views come
back in milliseconds instead of re-running SQL in the database. This page
describes how the cache is organized, the settings that control it and
every way to clear it — from **Refresh** in Excel to an API call at the end
of an ETL pipeline.

.. _cache_layers:

Cache layers
------------

- **Session response cache** — each session keeps its already-built XMLA
  responses, so repeating the same report view does not re-run the query.
  Responses larger than ``RESULT_CACHE_MAX_MB`` are not stored and are
  rebuilt on every refresh.

- **Shared SQL result cache** — SQL query results are **shared between
  users**: when several users (or several sessions of one user) produce an
  identical SQL query, it runs in the database once per ``SQL_CACHE_TTL``
  (600 seconds by default) and the others are served from the cache within
  milliseconds. Safe with row-level security: per-user access filters are
  part of the generated SQL text, so users with different permissions
  generate different SQL and never share results.

- **Metadata cache** — cube definitions, database/table/field lists and MDX
  query results are kept for ``METADATA_CACHE_TTL`` (600 seconds by
  default), so an edited cube definition is picked up automatically within
  this window, without any manual cache clearing.

- **Authorization cache** — a successful authorization (local users and
  Active Directory) is kept for ``AUTH_CACHE_TIMEOUT`` seconds before the
  user is re-checked against the configuration or LDAP on their next
  request.

Pressing **Refresh** in Excel always gives the pressing user fresh data:
cached results obtained before the refresh are bypassed for that user and,
once re-read from the database, updated for everyone else as well. Users
who do not press Refresh keep being served from the cache until its TTL
expires. See :ref:`refreshing_data`.

Settings
--------

The cache is configured in ``settings.json``. The table below maps each
setting to what it controls; full descriptions are in
:ref:`settings_schema`.

.. list-table::
   :header-rows: 1
   :widths: 32 53 15

   * - Setting
     - Controls
     - Default
   * - ``SQL_CACHE_ENABLED``
     - Shared SQL result cache on/off.
     - true
   * - ``SQL_CACHE_TTL``
     - Lifetime (seconds) of shared SQL results.
     - 600
   * - ``SQL_CACHE_MAX_MB``
     - Total size cap of the shared SQL cache (LRU eviction).
     - 256
   * - ``SQL_CACHE_MAX_RESULT_MB``
     - A single SQL result larger than this is not cached.
     - 32
   * - ``METADATA_CACHE_TTL``
     - Lifetime (seconds) of cube metadata and MDX query results.
     - 600
   * - ``RESULT_CACHE_MAX_MB``
     - A single session response larger than this is not cached.
     - 16
   * - ``AUTH_CACHE_TIMEOUT``
     - Lifetime (seconds) of a cached authorization.
     - 3600
   * - ``CACHE_BACKEND``
     - Cache storage: ``sqlite`` (one machine) or ``redis`` (cluster).
     - sqlite
   * - ``REDIS_URL``
     - Redis connection string for ``CACHE_BACKEND: redis``.
     - —

Cache backends
--------------

With the default ``sqlite`` backend the cache is a local database file
shared by all worker processes of one machine.

With ``CACHE_BACKEND: redis`` several XLTable servers behind a load
balancer share one cache: sessions, licensed named-user seats and cached
results are valid on every server, and clearing the cache on any server
takes effect for the whole cluster. Setup steps, a load-balancer example
and security notes are in :ref:`install_multi_server`. If the ``redis``
backend is misconfigured, the server logs an error and falls back to
``sqlite`` instead of failing to start.

Clearing the cache
------------------

Most of the time no manual clearing is needed: entries expire by their TTL,
and when the content of ``settings.json`` changes, the cache is cleared
automatically so nothing cached under the previous configuration stays in
effect (see :ref:`applying_config`). When fresh data is needed immediately:

- **Refresh in Excel** — per user: bypasses cached results for the pressing
  user and updates the shared entries for everyone else
  (:ref:`refreshing_data`).
- **Admin panel** (:ref:`admin_panel`) — the **Cache** tab shows per-user
  sessions and shared-cache statistics, with **Clear Metadata Cache**
  (cube definitions, schema lists and query results; users stay signed in —
  use after editing a cube) and **Clear All Cache** (everything; users
  re-authenticate on their next request). A **Sign out** button drops the
  sessions of a single user.
- **Cache management API** — for external systems such as ETL pipelines;
  see below.

------------------------------------------------------------

.. _cache_api:

Cache management API
--------------------

``POST /api/cache/clear`` clears the cache on request of an external system.
The typical use is a final step of an ETL pipeline: right after the data in
the warehouse is updated, the pipeline clears the XLTable cache so users get
fresh data immediately instead of waiting out the cache TTL.

Authorization — either of:

- ``Authorization: Bearer <token>`` with a token listed in ``API_TOKENS``
  (recommended for pipelines — no admin password in scripts);
- admin credentials via HTTP Basic auth (an ``OWNERS`` account or a user
  from an admin group).

The ``scope`` parameter (query string, form field or JSON body) selects what
is cleared:

.. list-table::
   :header-rows: 1
   :widths: 14 66

   * - scope
     - Effect
   * - ``sql`` (default)
     - Only the shared SQL result cache — the right choice after a data
       update: cube definitions and user sessions stay untouched.
   * - ``metadata``
     - Also cached cube definitions and schema lists; users stay signed in.
       Equivalent to **Clear Metadata Cache** in the admin panel — use after
       editing a cube.
   * - ``all``
     - Everything, including authorized sessions; users re-authorize on
       their next request.

Examples:

.. code-block:: bash

   # after an ETL run: refresh data for all users
   curl -X POST -H "Authorization: Bearer <token>" \
        http://xltable-server/api/cache/clear

   # after editing a cube definition
   curl -X POST -H "Authorization: Bearer <token>" \
        "http://xltable-server/api/cache/clear?scope=metadata"

The response is JSON: ``{"cleared": "sql"}`` on success, ``401`` for missing
or invalid credentials, ``400`` for an unknown scope.

With ``CACHE_BACKEND: redis`` one call clears the shared cache of the whole
cluster — any server behind the load balancer can be called. With the default
``sqlite`` backend the call clears the cache of the machine that served it,
so in a multi-machine setup without Redis call each server directly.
