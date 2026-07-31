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
   See :doc:`databases` for the list of supported database types.

   Example:

   .. code-block:: json

      "SERVER_DB": "ClickHouse"

   Default: not set

.. confval:: CREDENTIAL_DB

   Defines credentials used for accessing the server database. The set of
   keys depends on :confval:`SERVER_DB` — see :doc:`databases` for a
   connection example for every supported database type.

   Example (ClickHouse):

   .. code-block:: json

      "CREDENTIAL_DB": {
          "user": "olap_reader",
          "password": "...",
          "host": "ch.company.local",
          "port": "8443",
          "secure": true,
          "verify": true,
          "query_timeout": 60
      }

   Default: not set

.. confval:: CREDENTIAL_DB.query_timeout

   Maximum execution time of a single database query, in seconds. A query
   running longer is cancelled and an error is returned to Excel.
   Supported by all connection types.

   Example:

   .. code-block:: json

      "CREDENTIAL_DB": {
          "...": "...",
          "query_timeout": 120
      }

   Default: ``60``

.. confval:: CUBE_SOURCE

   Where the server reads cube definitions from:

   - ``"database"`` — the ``olap_definition`` table of the analytical
     database (see :ref:`cube_definition_storage`);
   - ``"folder"`` — local ``.sql`` files in the folder set by
     :confval:`CUBES_FOLDER`. Each file is one cube (file name without the
     extension = cube name); the file content is the same definition text
     that would otherwise be stored in ``olap_definition``, so the same
     file works in both modes without changes. Files are re-read on every
     request — saving a file makes the change visible immediately (data
     already shown in a pivot table is refreshed by Excel Refresh, as
     usual). In this mode Excel sees a single catalog named ``Cubes``.

   SQL queries of the cubes are executed through :confval:`SERVER_DB` /
   :confval:`CREDENTIAL_DB` in both modes — only the source of the
   definitions differs.

   .. note::
      Excel binds a pivot table to the catalog+cube pair. Switching the
      mode changes the catalog name (a warehouse database name vs
      ``Cubes``), so existing workbooks have to be reconnected.

   Example:

   .. code-block:: json

      "CUBE_SOURCE": "folder"

   Default: ``"database"``

.. confval:: CUBES_FOLDER

   Folder with local cube definitions: the output folder of
   :ref:`autogen <cube_autogen>` and, when ``CUBE_SOURCE`` is
   ``"folder"``, the folder the server reads cubes from. A relative path
   is resolved from the application root (the server working directory).

   Example:

   .. code-block:: json

      "CUBES_FOLDER": "/usr/olap/xltable/cubes"

   Default: ``"cubes"``

.. confval:: WRITE_LOG

   Enables debug logging of XLTable operations (MDX, generated SQL, Jinja
   diffs, result preview). Log files will be located in the folder
   ``...\xltable\log``.

   Example:

   .. code-block:: json

      "WRITE_LOG": true

   Default: ``false``

.. confval:: DUMP_XMLA

   Dumps every raw XMLA request and response to a separate file in the
   ``log`` folder. Intended only for diagnosing Excel/XMLA protocol issues:
   a single Excel action generates dozens of files. Independent of
   :confval:`WRITE_LOG`.

   Example:

   .. code-block:: json

      "DUMP_XMLA": true

   Default: ``false``

.. confval:: LOG_RETENTION_DAYS

   Files in the ``log`` folder older than this number of days are deleted
   automatically (checked at most once a day, on service start). Set to 0
   to disable the cleanup.

   Example:

   .. code-block:: json

      "LOG_RETENTION_DAYS": 30

   Default: ``14``

.. confval:: SERVER_PORT

   TCP port the server listens on. Applies to the standalone deployment
   (Ubuntu / ``python main.py``); under IIS the port is managed by IIS.
   The ``OLAP_PORT`` environment variable overrides this setting — the
   Ubuntu installer uses it to run several worker processes on
   consecutive ports (5000, 5001, ...). Requires a service restart.

   Example:

   .. code-block:: json

      "SERVER_PORT": 5000

   Default: ``5000``

.. confval:: SERVER_THREADS

   Number of worker threads of one server process (standalone deployment
   only). Threads waiting on the database do not block each other, so
   this is how many queries one process keeps in flight towards the
   warehouse; CPU-intensive result building still runs one report at a
   time per process — for parallel heavy reports run several worker
   processes (see :ref:`install_ubuntu`). Requires a service restart.

   Example:

   .. code-block:: json

      "SERVER_THREADS": 32

   Default: ``16``

.. confval:: USERS

   Defines the list of users for local authentication.
   Keys are user names, values are passwords.

   Example:

   .. code-block:: json

      "USERS": {"user1": "pass1", "user2": "pass2"}

   Default: not set

.. confval:: USER_GROUPS

   Defines user groups used for role-based access control.
   Keys are user names, values are lists of groups the user belongs to —
   these group names are matched against ``--olap_user_groups`` in cube
   definitions and against :confval:`ADMIN_GROUPS`.

   Example:

   .. code-block:: json

      "USER_GROUPS": {
          "user1": ["olap_users", "olap_admins"],
          "user2": ["olap_users"]
      }

   Default: not set

.. confval:: MAX_CELLS

   Limits the size of the pivoted result returned to Excel, measured in
   cells: unique row combinations × column combinations × measures.
   Queries exceeding the limit are rejected with a message suggesting
   filters, the same way SSAS cancels oversized results
   (``RowsetSerializationLimit``). The legacy ``MAX_ROWS`` key is still
   accepted and used as ``MAX_CELLS``.

   Example:

   .. code-block:: json

      "MAX_CELLS": 500000

   Default: ``100000``

.. confval:: MAX_FILTER_MEMBERS

   Caps the member list the server enumerates when Excel applies
   **Keep Only / Hide Selected Items** on a field. If the dimension level
   has more members than the cap, the resulting filter keeps only the
   first ``MAX_FILTER_MEMBERS`` of them and a warning is written to the
   log. The 10,000-item limit of the filter dropdown list is separate and
   not affected by this setting.

   Example:

   .. code-block:: json

      "MAX_FILTER_MEMBERS": 50000

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

   Example:

   .. code-block:: json

      "OVERLOAD_GUARD": {
          "MAX_MEMORY_PERCENT": 90,
          "MAX_CPU_PERCENT": 95,
          "MIN_FREE_DISK_MB": 512
      }

   Default: disabled

.. confval:: AUTH_CACHE_TIMEOUT

   Defines the lifetime of a cached authorization in seconds, for both
   local (:confval:`USERS`) and Active Directory users. After this period
   expires, XLTable re-checks the user against the current configuration
   or LDAP on the next request. When not set, the value of
   :confval:`LDAP_CACHE_TIMEOUT` is used.

   Example:

   .. code-block:: json

      "AUTH_CACHE_TIMEOUT": 1800

   Default: ``3600``

.. confval:: LDAP_CACHE_TIMEOUT

   Legacy name of :confval:`AUTH_CACHE_TIMEOUT`; kept for backward
   compatibility and used when ``AUTH_CACHE_TIMEOUT`` is not set.

   Example:

   .. code-block:: json

      "LDAP_CACHE_TIMEOUT": 300

   Default: ``300``

.. confval:: METADATA_CACHE_TTL

   Defines the lifetime in seconds of cached cube metadata (cube
   definitions, database/table/field lists) and of already-built session
   responses. After this period expires, XLTable re-reads the data from
   the database, so an edited cube definition is picked up automatically
   within this window — no manual cache clearing is required. Set to 0 to
   disable expiry (cache entries then live until the cache is cleared).

   Example:

   .. code-block:: json

      "METADATA_CACHE_TTL": 300

   Default: ``600``

.. confval:: RESULT_CACHE_MAX_MB

   Query results larger than this size (MB) are not stored in the shared
   result cache and are rebuilt on every refresh instead. Storing very
   large results makes all worker processes queue on the cache write, so
   oversized responses are cheaper to recompute. Set to 0 to disable
   result caching entirely (metadata is still cached).

   Example:

   .. code-block:: json

      "RESULT_CACHE_MAX_MB": 32

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

   Example:

   .. code-block:: json

      "SQL_CACHE_ENABLED": false

   Default: ``true``

.. confval:: SQL_CACHE_TTL

   Lifetime (seconds) of entries in the shared SQL result cache: within
   this window an identical query is served from the cache instead of
   the database. Set to 0 to disable expiry. When not set, the value of
   :confval:`METADATA_CACHE_TTL` is used.

   Example:

   .. code-block:: json

      "SQL_CACHE_TTL": 1200

   Default: ``600``

.. confval:: SQL_CACHE_MAX_MB

   Total size cap (MB) of the shared SQL result cache. When the cap is
   exceeded, the least recently used results are evicted.

   Example:

   .. code-block:: json

      "SQL_CACHE_MAX_MB": 512

   Default: ``256``

.. confval:: SQL_CACHE_MAX_RESULT_MB

   A single query result larger than this size (MB) is not stored in the
   shared SQL result cache and is re-read from the database instead.
   (Not to be confused with :confval:`RESULT_CACHE_MAX_MB`, which caps the
   cached XMLA response of one session.)

   Example:

   .. code-block:: json

      "SQL_CACHE_MAX_RESULT_MB": 64

   Default: ``32``

.. confval:: CACHE_BACKEND

   Storage of the shared session/metadata cache and the shared SQL
   result cache. ``sqlite`` — a local
   database file shared by the worker processes of one machine.
   ``redis`` — an external Redis server shared by **several XLTable
   servers** behind a load balancer (requires :confval:`REDIS_URL`); see
   :ref:`install_multi_server`. If the ``redis`` backend is
   misconfigured, the server logs an error and falls back to ``sqlite``.

   Example:

   .. code-block:: json

      "CACHE_BACKEND": "redis"

   Default: ``sqlite``

.. confval:: REDIS_URL

   Redis connection string for ``CACHE_BACKEND: redis``, in the form
   ``redis://[:password@]host:port/db`` (``rediss://`` for TLS). All
   servers sharing the cache must use the same Redis database and have
   identical ``settings.json`` files.

   Example:

   .. code-block:: json

      "REDIS_URL": "redis://:secret@10.0.0.5:6379/0"

   Default: not set

.. confval:: CONVERT_FIELDS_TO_STRING

   Forces conversion of certain fields to string type before returning results.

   Example:

   .. code-block:: json

      "CONVERT_FIELDS_TO_STRING": true

   Default: ``true``

.. confval:: ADMIN_GROUPS

   Defines user groups for accessing the admin panel (``/admin``).
   A user whose :confval:`USER_GROUPS` (or Active Directory groups)
   intersect this list gets admin access.

   Example:

   .. code-block:: json

      "ADMIN_GROUPS": ["olap_admins"]

   Default: not set

.. confval:: API_TOKENS

   Bearer tokens (a string or a list of strings) accepted by the cache
   management API (see :ref:`cache_api`) — intended for external systems
   such as ETL pipelines, so they do not need an admin password. When not
   set, the API accepts only admin credentials.

   Example:

   .. code-block:: json

      "API_TOKENS": ["etl-3f7c9a1b", "backup-51d2e8c4"]

   Default: not set

.. confval:: CREDENTIAL_ACTIVE_DIRECTORY

   Defines connection parameters for Active Directory authentication.
   See :doc:`install` for details on AD setup.

   Example:

   .. code-block:: json

      "CREDENTIAL_ACTIVE_DIRECTORY": {
          "server_address": "dc.company.org",
          "domain": "company",
          "domain_full": "company.org",
          "username": "service_olap",
          "password": "...",
          "access_groups": ["olap_users_all", "olap_users_sales"]
      }

   Default: not set

.. confval:: EXPORT

   Enables exporting large pivot results to CSV files and the preview
   mode (the service **Data Output** field). A block of sub-keys — see
   :ref:`export_settings`. When the section is absent, the feature is
   fully off and leaves no trace: cube metadata, menus and server
   behavior are exactly as before.

   Example — an empty object is enough to enable the feature:

   .. code-block:: json

      "EXPORT": {}

   Default: disabled

.. confval:: PUBLIC_URL

   The server address as Excel users' browsers reach it, e.g.
   ``http://bi.company.local:5000``. Used to build the links Excel opens
   in the browser (the export status page). When not set, the address of
   the incoming request is used — set this explicitly when the server is
   behind a proxy or reachable by several names.

   Example:

   .. code-block:: json

      "PUBLIC_URL": "http://bi.company.local:5000"

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

   Example:

   .. code-block:: json

      "EXPORT": {"enabled": false}

   Default: ``true``

.. confval:: EXPORT.preview_rows

   Number of rows shown by the ``Preview: first N rows`` mode of the
   **Data Output** field. The caption of the member shows the actual
   configured number.

   Example:

   .. code-block:: json

      "EXPORT": {"preview_rows": 500}

   Default: ``1000``

.. confval:: EXPORT.hard_limit_rows

   Absolute cap on the number of rows in an exported file — a safety net
   against runaway exports.

   Example:

   .. code-block:: json

      "EXPORT": {"hard_limit_rows": 10000000}

   Default: ``50000000``

.. confval:: EXPORT.file_ttl_hours

   How long a built export file is kept on the server. Within this
   window, repeated exports of an unchanged layout return the same file
   without re-querying the database; after it the file is deleted and
   the next export builds it again.

   Example:

   .. code-block:: json

      "EXPORT": {"file_ttl_hours": 8}

   Default: ``24``

.. confval:: EXPORT.decimal_separator

   Decimal separator for numbers in the CSV file: ``","`` (comma —
   matches Excel with Russian regional settings) or ``"."`` (numbers
   written as-is).

   Example:

   .. code-block:: json

      "EXPORT": {"decimal_separator": "."}

   Default: ``","``

.. confval:: EXPORT.dimension_caption

   Name of the service field in the field list. Change it if a cube
   already has a field named **Data Output** (in that case the feature
   is disabled for such a cube automatically and a warning is logged).

   Example:

   .. code-block:: json

      "EXPORT": {"dimension_caption": "Export"}

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
