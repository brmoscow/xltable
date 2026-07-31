.. _settings_schema:

settings.json reference
=======================

This page describes the main configuration parameters available
in the ``settings.json`` file.

These parameters control server behavior, authentication,
database access, caching and system limits.

Every parameter below has its own anchor — hover over a name and use the
¶ link to share a direct reference to it.

Parameter reference
-------------------

.. confval:: SERVER_DB

   Defines the primary database used by the XLTable server for internal operations.

   Default: not set

.. confval:: CREDENTIAL_DB

   Defines credentials used for accessing the server database.

   Default: not set

.. confval:: CREDENTIAL_DB.query_timeout

   Maximum execution time of a single database query, in seconds. A query
   running longer is cancelled and an error is returned to Excel.
   Supported by all connection types.

   Default: ``60``

.. confval:: WRITE_LOG

   Enables debug logging of XLTable operations (MDX, generated SQL, Jinja
   diffs, result preview). Log files will be located in the folder
   ``...\xltable\log``.

   Default: ``false``

.. confval:: DUMP_XMLA

   Dumps every raw XMLA request and response to a separate file in the
   ``log`` folder. Intended only for diagnosing Excel/XMLA protocol issues:
   a single Excel action generates dozens of files. Independent of
   :confval:`WRITE_LOG`.

   Default: ``false``

.. confval:: LOG_RETENTION_DAYS

   Files in the ``log`` folder older than this number of days are deleted
   automatically (checked at most once a day, on service start). Set to 0
   to disable the cleanup.

   Default: ``14``

.. confval:: SERVER_PORT

   TCP port the server listens on. Applies to the standalone deployment
   (Ubuntu / ``python main.py``); under IIS the port is managed by IIS.
   The ``OLAP_PORT`` environment variable overrides this setting — the
   Ubuntu installer uses it to run several worker processes on
   consecutive ports (5000, 5001, ...). Requires a service restart.

   Default: ``5000``

.. confval:: SERVER_THREADS

   Number of worker threads of one server process (standalone deployment
   only). Threads waiting on the database do not block each other, so
   this is how many queries one process keeps in flight towards the
   warehouse; CPU-intensive result building still runs one report at a
   time per process — for parallel heavy reports run several worker
   processes (see :ref:`install_ubuntu`). Requires a service restart.

   Default: ``16``

.. confval:: USERS

   Defines the list of users for local authentication.

   Default: not set

.. confval:: USER_GROUPS

   Defines user groups used for role-based access control.

   Default: not set

.. confval:: MAX_CELLS

   Limits the size of the pivoted result returned to Excel, measured in
   cells: unique row combinations × column combinations × measures.
   Queries exceeding the limit are rejected with a message suggesting
   filters, the same way SSAS cancels oversized results
   (``RowsetSerializationLimit``). The legacy ``MAX_ROWS`` key is still
   accepted and used as ``MAX_CELLS``.

   Default: ``100000``

.. confval:: MAX_FILTER_MEMBERS

   Caps the member list the server enumerates when Excel applies
   **Keep Only / Hide Selected Items** on a field. If the dimension level
   has more members than the cap, the resulting filter keeps only the
   first ``MAX_FILTER_MEMBERS`` of them and a warning is written to the
   log. The 10,000-item limit of the filter dropdown list is separate and
   not affected by this setting.

   Default: ``100000``

.. confval:: OVERLOAD_GUARD

   Rejects data queries while the server host is out of resources, instead
   of forwarding them to the database. When any threshold is exceeded —
   ``MAX_MEMORY_PERCENT`` (RAM usage, %), ``MAX_CPU_PERCENT`` (CPU usage,
   %), ``MIN_FREE_DISK_MB`` (free disk space, MB) — Excel shows
   "Server is overloaded ... Please try again later" with the specific
   reason on data refresh. Metadata (Discover) requests and session
   open/close requests are never rejected, so connecting to a cube and
   already open connections keep working. Each threshold is
   optional; omit the whole block to disable the guard. Note: inside a
   container the measured resources are the host's, not the container
   limits.

   Default: disabled

.. confval:: AUTH_CACHE_TIMEOUT

   Defines the lifetime of a cached authorization in seconds, for both
   local (:confval:`USERS`) and Active Directory users. After this period
   expires, XLTable re-checks the user against the current configuration
   or LDAP on the next request. When not set, the value of
   :confval:`LDAP_CACHE_TIMEOUT` is used.

   Default: ``3600``

.. confval:: LDAP_CACHE_TIMEOUT

   Legacy name of :confval:`AUTH_CACHE_TIMEOUT`; kept for backward
   compatibility and used when ``AUTH_CACHE_TIMEOUT`` is not set.

   Default: ``300``

.. confval:: METADATA_CACHE_TTL

   Defines the lifetime in seconds of cached cube metadata (cube
   definitions, database/table/field lists) and of already-built session
   responses. After this period expires, XLTable re-reads the data from
   the database, so an edited cube definition is picked up automatically
   within this window — no manual cache clearing is required. Set to 0 to
   disable expiry (cache entries then live until the cache is cleared).

   Default: ``600``

.. confval:: RESULT_CACHE_MAX_MB

   Query results larger than this size (MB) are not stored in the shared
   result cache and are rebuilt on every refresh instead. Storing very
   large results makes all worker processes queue on the cache write, so
   oversized responses are cheaper to recompute. Set to 0 to disable
   result caching entirely (metadata is still cached).

   Default: ``16``

.. confval:: SQL_CACHE_ENABLED

   Shared SQL result cache: when several users (or several sessions of
   one user) produce an identical SQL query, it is executed in the
   database once and the result is shared between them. Safe with
   row-level security: per-user access filters are rendered into the SQL
   text itself, so users with different permissions generate different
   SQL and never share results. Excel **Refresh** gives the pressing
   user fresh data and updates the shared entries for everyone (see
   :ref:`refreshing_data`). Set to ``false`` to execute every query
   individually.

   Default: ``true``

.. confval:: SQL_CACHE_TTL

   Lifetime (seconds) of entries in the shared SQL result cache: within
   this window an identical query is served from the cache instead of
   the database. Set to 0 to disable expiry. When not set, the value of
   :confval:`METADATA_CACHE_TTL` is used.

   Default: ``600``

.. confval:: SQL_CACHE_MAX_MB

   Total size cap (MB) of the shared SQL result cache. When the cap is
   exceeded, the least recently used results are evicted.

   Default: ``256``

.. confval:: SQL_CACHE_MAX_RESULT_MB

   A single query result larger than this size (MB) is not stored in the
   shared SQL result cache and is re-read from the database instead.
   (Not to be confused with :confval:`RESULT_CACHE_MAX_MB`, which caps the
   cached XMLA response of one session.)

   Default: ``32``

.. confval:: CACHE_BACKEND

   Storage of the shared session/metadata cache and the shared SQL
   result cache. ``sqlite`` — a local
   database file shared by the worker processes of one machine.
   ``redis`` — an external Redis server shared by **several XLTable
   servers** behind a load balancer (requires :confval:`REDIS_URL`); see
   :ref:`install_multi_server`. If the ``redis`` backend is
   misconfigured, the server logs an error and falls back to ``sqlite``.

   Default: ``sqlite``

.. confval:: REDIS_URL

   Redis connection string for ``CACHE_BACKEND: redis``, in the form
   ``redis://[:password@]host:port/db`` (``rediss://`` for TLS). All
   servers sharing the cache must use the same Redis database and have
   identical ``settings.json`` files.

   Default: not set

.. confval:: CONVERT_FIELDS_TO_STRING

   Forces conversion of certain fields to string type before returning results.

   Default: ``true``

.. confval:: ADMIN_GROUPS

   Defines user groups for accessing the admin panel (``/admin``).

   Default: not set

.. confval:: API_TOKENS

   Bearer tokens (a string or a list of strings) accepted by the cache
   management API (see :ref:`cache_api`) — intended for external systems
   such as ETL pipelines, so they do not need an admin password. When not
   set, the API accepts only admin credentials.

   Default: not set

.. confval:: CREDENTIAL_ACTIVE_DIRECTORY

   Defines connection parameters for Active Directory authentication.

   Default: not set

.. confval:: EXPORT

   Enables exporting large pivot results to CSV files and the preview
   mode (the service **Data Output** field). A block of sub-keys — see
   :ref:`export_settings`. When the section is absent, the feature is
   fully off and leaves no trace: cube metadata, menus and server
   behavior are exactly as before.

   Default: disabled

.. confval:: PUBLIC_URL

   The server address as Excel users' browsers reach it, e.g.
   ``http://bi.company.local:5000``. Used to build the links Excel opens
   in the browser (the export status page). When not set, the address of
   the incoming request is used — set this explicitly when the server is
   behind a proxy or reachable by several names.

   Default: not set

.. _export_settings:

Export to file (EXPORT)
-----------------------

The :confval:`EXPORT` section of ``settings.json`` turns on file export and
the preview mode for all cubes (see :ref:`excel_export` for how users work
with it). Minimal configuration — an empty object is enough:

.. code-block:: json

   {
       "EXPORT": {},
       "PUBLIC_URL": "http://bi.company.local"
   }

All keys of the section are optional:

.. confval:: EXPORT.enabled

   Set to ``false`` to turn the feature off while keeping the section
   (same as removing it).

   Default: ``true``

.. confval:: EXPORT.preview_rows

   Number of rows shown by the ``Preview: first N rows`` mode of the
   **Data Output** field. The caption of the member shows the actual
   configured number.

   Default: ``1000``

.. confval:: EXPORT.hard_limit_rows

   Absolute cap on the number of rows in an exported file — a safety net
   against runaway exports.

   Default: ``50000000``

.. confval:: EXPORT.file_ttl_hours

   How long a built export file is kept on the server. Within this
   window, repeated exports of an unchanged layout return the same file
   without re-querying the database; after it the file is deleted and
   the next export builds it again.

   Default: ``24``

.. confval:: EXPORT.decimal_separator

   Decimal separator for numbers in the CSV file: ``","`` (comma —
   matches Excel with Russian regional settings) or ``"."`` (numbers
   written as-is).

   Default: ``","``

.. confval:: EXPORT.dimension_caption

   Name of the service field in the field list. Change it if a cube
   already has a field named **Data Output** (in that case the feature
   is disabled for such a cube automatically and a warning is logged).

   Default: ``Data Output``

Export files are written to the ``export_files`` folder next to the server
code, the job registry lives in ``exports.db``; both appear on first use.
The **Cache** tab of the admin panel shows the current jobs, files and their
total size, and provides a **Clear Export Jobs and Files** button that also
removes orphaned files and compacts ``exports.db``. In multi-server
deployments (``CACHE_BACKEND: redis``) export is not yet cluster-aware:
route ``/exports/*`` requests to one designated server on the load balancer.

.. _applying_config:

Applying configuration changes
------------------------------

Changes to ``settings.json`` are picked up automatically — no service
restart is required. XLTable watches the file and re-reads it within a few
seconds of saving (in multi-process deployments such as IIS, every worker
process picks the change up on its next request).

- If the saved file contains a JSON syntax error, the service keeps running
  with the previous configuration and writes the parse error to the log; the
  file is re-read once it is fixed.
- When the configuration content changes, the cache is cleared automatically,
  so nothing cached under the previous (for example, incorrect) configuration
  — authorized sessions, cube metadata — stays in effect. Users re-authorize
  transparently on their next request.
- The same comparison runs on service start, so a restart with a changed
  ``settings.json`` also begins with a clean cache.

The admin panel (see :ref:`admin_panel`) shows which settings file is in use
and when it was last loaded.

Deployment-level parameters that live outside ``settings.json`` (service
user, port, IIS application pool settings) still require a service restart.
