Reference
=========

This section provides technical reference information for XLTable configuration,
SQL extensions and runtime variables.

It is intended for administrators, integrators and developers
working with cube definitions and system configuration.

------------------------------------------------------------

.. _sql_tags:

SQL tags
--------

XLTable defines OLAP cubes using SQL scripts.

In addition to standard SQL syntax, cube definitions include special
inline tags embedded inside SQL comments. These tags act as keywords
that provide metadata and behavioral instructions for the XLTable engine.

SQL tags are not executed by the database.
They are parsed by XLTable before query execution and used to define:

- cube properties
- dimensions and measures
- security rules
- execution behavior
- metadata and configuration

This approach allows keeping cube definitions fully SQL-based
while extending them with OLAP semantics.

General usage
^^^^^^^^^^^^^

Tags are embedded directly into SQL scripts using comments.
During processing, XLTable reads these tags and builds
the OLAP cube structure based on them.

Tag reference
^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Tag
     - Description

   * - definition_check_on
     - When present in the cube definition, enforces mandatory syntax validation
       of the cube definition before connecting to data.
       If validation fails, the connection is not established and an error is returned.

   * - hide
     - Hides a measure or dimension from the list of fields in Excel.
   
   * - hierarchy   
     - After the tag, you must specify the name of the hierarchy to which the field belongs. 
       Fields with the same hierarchy name will be grouped together in Excel.
       
   * - olap_access_filters
     - Marks the beginning of a block defining security filters for a specific user role.
       Each filter is written on its own line (no commas between lines) as
       ``<alias> in ('v1', 'v2')``, where ``<alias>`` is the field's alias from the cube's
       SELECT section (display names from ``--translation`` cannot be used). Filters on
       different fields are combined with AND; the values of one list are alternatives (OR).
       The filters are enforced on every SQL query the server builds; an explicit
       filter on the same field in a query is intersected with the allowed values.

   * - olap_calculated_fields
     - Marks the beginning of a block containing the list of calculated fields. After the tag, you must specify the name of the folder calculated fields.

   * - olap_calculated_fields_visible
     - Marks the beginning of a block listing calculated fields available to a specific user role.

   * - olap_cube
     - Marks the beginning of a block describing cube properties and metadata.

   * - olap_dimensions
     - Marks the beginning of a block listing dimension attributes.

   * - olap_dimensions_visible
     - Marks the beginning of a block listing dimension attributes available to a specific user role.

   * - olap_drillthrough
     - Marks a block, inside an ``olap_source`` measure-group block, listing the
       detail columns returned when a user drills through a cell of that measure
       group in Excel. The value is a comma-separated list of field aliases or
       display names already defined in the cube. See :ref:`drillthrough`.

   * - olap_jinja
     - Marks the beginning of a block with Jinja template logic that modifies SQL scripts.

   * - olap_measures
     - Marks the beginning of a block listing measures.

   * - olap_measures_visible
     - Marks the beginning of a block listing measures available to a specific user role.

   * - olap_source
     - Marks the beginning of a block defining the source dataset for measures or dimensions. After the tag, you must specify the name of the group of measures or dimension.

   * - olap_user_groups
     - Marks the beginning of a block listing security groups assigned to a user role.

   * - olap_user_role
     - Marks the beginning of a block defining a user role.

   * - relationship
     - Defines the join type for a ``LEFT JOIN`` clause within an ``olap_source`` block.
       Valid values:

       - ``many-to-many`` — join where the dimension table relates to multiple source rows.
       - ``one-table`` — all measures are in one table; dimension columns are selected directly without a join.
       - ``part-source`` — the ``LEFT JOIN`` is treated as part of the current ``olap_source`` block rather than a cross-source relationship.
         Use this to attach extra tables (CTEs, lookup tables) that belong to the same source and should not create a new join path to other sources.

   * - translation
     - Defines the localized name of a measure or dimension attribute displayed in Excel.
       The value must be unique within the cube.

   * - folder
     - Overrides the display folder for a field in the Excel field list.
       By default, fields are grouped under a folder named after their ``olap_source``.
       Use this tag to place a field into a differently named folder.

       Syntax: ``--folder=`Folder Name```

   * - format
     - Defines the display format of a measure in Excel Pivot Tables.
       The value follows the standard **Excel number format** syntax.
       A semicolon separates the positive and negative patterns: ``positive;negative``.

       .. list-table::
          :header-rows: 1
          :widths: 38 31 31

          * - Format string
            - Positive value
            - Negative value
          * - ``#,##0;-#,##0``
            - 1,234
            - -1,234
          * - ``#,##0.00;-#,##0.00``
            - 1,234.56
            - -1,234.56
          * - ``#,##0.0;-#,##0.0``
            - 1,234.6
            - -1,234.6
          * - ``0%``
            - 56%
            - -56%
          * - ``0.0%``
            - 56.3%
            - -56.3%
          * - ``0.00%``
            - 56.34%
            - -56.34%
          * - ``#,##0;(#,##0)``
            - 1,234
            - (1,234)
          * - ``#,##0.00;(#,##0.00)``
            - 1,234.56
            - (1,234.56)

       The format string is stored in the cube definition and applied by Excel
       when the field is placed on a Pivot Table. Leaving the tag out lets
       Excel apply its default general format.

.. _unified_example:

Unified example
---------------

All tags listed in the table above are used together in a single cube definition example below.

This example demonstrates how SQL tags are embedded into a cube SQL script
and how they describe cube structure, measures, dimensions, security rules
and visibility settings.

The script represents a complete cube definition and can be used
as a reference when creating new OLAP cubes XLTable for ClickHouse.

.. code-block:: sql

    CREATE OR REPLACE TABLE db.olap_definition 
    ENGINE = MergeTree() ORDER BY id AS

    SELECT 'myOLAPcube' AS id,
    '	
    with calendar as (
        SELECT * FROM db.Times where year_str in (''2023'', ''2024'', ''2025'')
    )

    --olap_cube
    --olap_calculated_fields Calculated fields
    (sales_sum_qty/stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0;-#,##0`
    --olap_jinja
    {{ sql_text | replace("salesly.date_sale", "addYears(salesly.date_sale, 1)") }}

    --olap_source Sales
    SELECT
    --olap_measures
     sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`
    ,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount` --format=`#,##0.00;-#,##0.00` --hide
    FROM db.Sales sales
    LEFT JOIN db.Stores stores on sales.store = stores.id
    LEFT JOIN db.Models models on sales.model = models.id
    LEFT JOIN calendar times on sales.date_sale = times.day_str
    LEFT JOIN db.Currencies curr on sales.currency = curr.id --relationship=`part-source`
    --olap_drillthrough
    stores_name, regions_name, models_name, times_day_str, sales_sum_qty, sales_sum_sum

    --olap_source Sales last year
    SELECT
    --olap_measures
     sum(salesly.qty) as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
    ,sum(salesly.sum) as salesly_sum_sum --translation=`Sales last year Amount` --format=`#,##0.00;-#,##0.00` --hide 
    FROM db.Sales salesly
    LEFT JOIN db.Stores stores on salesly.store = stores.id
    LEFT JOIN db.Models models on salesly.model = models.id
    LEFT JOIN calendar times on salesly.date_sale = times.day_str  

    --olap_source Stock
    SELECT
    --olap_measures
     avg(stock.qty) as stock_avg_qty --translation=`Average Stock Quantity`
    FROM db.Stock stock
    LEFT JOIN db.Stores stores on stock.store = stores.id
    LEFT JOIN db.Models models on stock.model = models.id

    --olap_source Stores
    SELECT
    --olap_dimensions
     stores.id as store_id --translation=`Store ID`
    ,stores.name as stores_name --translation=`Store` --folder=`Distribution`
    FROM db.Stores stores
    LEFT JOIN db.Regions regions on stores.region = regions.id

    --olap_source Regions
    SELECT
    --olap_dimensions
     regions.name as regions_name --translation=`Region`
    FROM db.Regions regions
    LEFT JOIN db.Managers managers on regions.id = managers.region --relationship=`many-to-many`

    --olap_source Managers
    SELECT
    --olap_dimensions
     managers.name as managers_name --translation=`Manager`
    FROM db.Managers managers

    --olap_source Models
    SELECT
    --olap_dimensions
     models.name as models_name --translation=`Model`
    FROM db.Models models

    --olap_source Dates
    SELECT
    --olap_dimensions
     times.year_str as times_year_str --hierarchy=`Dates` --translation=`Year`
    ,toQuarter(toDate(times.day_str)) as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
    ,times.month_str as times_month_str --hierarchy=`Dates` --translation=`Month` 
    ,times.day_str as times_day_str --hierarchy=`Dates` --translation=`Day` 
    FROM calendar times

    --olap_user_role
    --olap_user_groups
    olap_users  
    --olap_calculated_fields_visible
    all
    --olap_measures_visible
    sales_sum_qty, stock_avg_qty
    --olap_dimensions_visible
    all
    --olap_access_filters
    regions_name in (`North`, `South`)
    ' AS definition

------------------------------------------------------------

Jinja context variables
-----------------------

The Jinja ``context`` object handed to cube templates — its ``cube`` / ``request``
/ ``sql`` namespaces plus ``user`` and ``now`` — is documented in the
:doc:`Jinja chapter <jinja>`. See :ref:`jinja_var`.

------------------------------------------------------------

.. _settings_schema:

settings.json schema
--------------------

This section describes the main configuration parameters available
in the ``settings.json`` file.

These parameters control server behavior, authentication,
database access, caching and system limits.

Parameter reference
^^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 35 45 20

   * - Parameter
     - Description
     - Default value

   * - SERVER_DB
     - Defines the primary database used by the XLTable server for internal operations.
     - —

   * - CREDENTIAL_DB
     - Defines credentials used for accessing the server database.
     - —

   * - CREDENTIAL_DB.query_timeout
     - Maximum execution time of a single database query, in seconds. A query
       running longer is cancelled and an error is returned to Excel.
       Supported by all connection types.
     - 60

   * - WRITE_LOG
     - Enables debug logging of XLTable operations (MDX, generated SQL, Jinja
       diffs, result preview). Log files will be located in the folder
       ``...\xltable\log``.
     - false

   * - DUMP_XMLA
     - Dumps every raw XMLA request and response to a separate file in the
       ``log`` folder. Intended only for diagnosing Excel/XMLA protocol issues:
       a single Excel action generates dozens of files. Independent of
       ``WRITE_LOG``.
     - false

   * - LOG_RETENTION_DAYS
     - Files in the ``log`` folder older than this number of days are deleted
       automatically (checked at most once a day, on service start). Set to 0
       to disable the cleanup.
     - 14

   * - SERVER_PORT
     - TCP port the server listens on. Applies to the standalone deployment
       (Ubuntu / ``python main.py``); under IIS the port is managed by IIS.
       The ``OLAP_PORT`` environment variable overrides this setting — the
       Ubuntu installer uses it to run several worker processes on
       consecutive ports (5000, 5001, ...). Requires a service restart.
     - 5000

   * - SERVER_THREADS
     - Number of worker threads of one server process (standalone deployment
       only). Threads waiting on the database do not block each other, so
       this is how many queries one process keeps in flight towards the
       warehouse; CPU-intensive result building still runs one report at a
       time per process — for parallel heavy reports run several worker
       processes (see :ref:`install_ubuntu`). Requires a service restart.
     - 16

   * - USERS
     - Defines the list of users for local authentication.
     - —

   * - USER_GROUPS
     - Defines user groups used for role-based access control.
     - —

   * - MAX_CELLS
     - Limits the size of the pivoted result returned to Excel, measured in
       cells: unique row combinations × column combinations × measures.
       Queries exceeding the limit are rejected with a message suggesting
       filters, the same way SSAS cancels oversized results
       (``RowsetSerializationLimit``). The legacy ``MAX_ROWS`` key is still
       accepted and used as ``MAX_CELLS``.
     - 100000

   * - MAX_FILTER_MEMBERS
     - Caps the member list the server enumerates when Excel applies
       **Keep Only / Hide Selected Items** on a field. If the dimension level
       has more members than the cap, the resulting filter keeps only the
       first ``MAX_FILTER_MEMBERS`` of them and a warning is written to the
       log. The 10,000-item limit of the filter dropdown list is separate and
       not affected by this setting.
     - 100000

   * - OVERLOAD_GUARD
     - Rejects data queries while the server host is out of resources, instead
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
     - disabled

   * - AUTH_CACHE_TIMEOUT
     - Defines the lifetime of a cached authorization in seconds, for both
       local (``USERS``) and Active Directory users. After this period
       expires, XLTable re-checks the user against the current configuration
       or LDAP on the next request. When not set, the value of
       ``LDAP_CACHE_TIMEOUT`` is used.
     - 3600

   * - LDAP_CACHE_TIMEOUT
     - Legacy name of ``AUTH_CACHE_TIMEOUT``; kept for backward
       compatibility and used when ``AUTH_CACHE_TIMEOUT`` is not set.
     - 300

   * - METADATA_CACHE_TTL
     - Defines the lifetime of cached cube metadata and query results in
       seconds: cube definitions, database/table/field lists and MDX query
       results. After this period expires, XLTable re-reads the data from the
       database, so an edited cube definition is picked up automatically
       within this window — no manual cache clearing is required. Set to 0 to
       disable expiry (cache entries then live until the cache is cleared).
     - 600

   * - RESULT_CACHE_MAX_MB
     - Query results larger than this size (MB) are not stored in the shared
       result cache and are rebuilt on every refresh instead. Storing very
       large results makes all worker processes queue on the cache write, so
       oversized responses are cheaper to recompute. Set to 0 to disable
       result caching entirely (metadata is still cached).
     - 16

   * - SQL_CACHE_ENABLED
     - Shared SQL result cache: when several users (or several sessions of
       one user) produce an identical SQL query, it is executed in the
       database once and the result is shared between them. Safe with
       row-level security: per-user access filters are rendered into the SQL
       text itself, so users with different permissions generate different
       SQL and never share results. Excel **Refresh** gives the pressing
       user fresh data and updates the shared entries for everyone (see
       :ref:`refreshing_data`). Set to ``false`` to execute every query
       individually.
     - true

   * - SQL_CACHE_TTL
     - Lifetime (seconds) of entries in the shared SQL result cache: within
       this window an identical query is served from the cache instead of
       the database. Set to 0 to disable expiry. When not set, the value of
       ``METADATA_CACHE_TTL`` is used.
     - 600

   * - SQL_CACHE_MAX_MB
     - Total size cap (MB) of the shared SQL result cache. When the cap is
       exceeded, the least recently used results are evicted.
     - 256

   * - SQL_CACHE_MAX_RESULT_MB
     - A single query result larger than this size (MB) is not stored in the
       shared SQL result cache and is re-read from the database instead.
       (Not to be confused with ``RESULT_CACHE_MAX_MB``, which caps the
       cached XMLA response of one session.)
     - 32

   * - CACHE_BACKEND
     - Storage of the shared session/metadata cache and the shared SQL
       result cache. ``sqlite`` — a local
       database file shared by the worker processes of one machine.
       ``redis`` — an external Redis server shared by **several XLTable
       servers** behind a load balancer (requires ``REDIS_URL``); see
       :ref:`install_multi_server`. If the ``redis`` backend is
       misconfigured, the server logs an error and falls back to ``sqlite``.
     - sqlite

   * - REDIS_URL
     - Redis connection string for ``CACHE_BACKEND: redis``, in the form
       ``redis://[:password@]host:port/db`` (``rediss://`` for TLS). All
       servers sharing the cache must use the same Redis database and have
       identical ``settings.json`` files.
     - —

   * - CONVERT_FIELDS_TO_STRING
     - Forces conversion of certain fields to string type before returning results.
     - true

   * - ADMIN_GROUPS
     - Defines user groups for accessing the admin panel (``/admin``).
     - —

   * - API_TOKENS
     - Bearer tokens (a string or a list of strings) accepted by the cache
       management API (see :ref:`cache_api`) — intended for external systems
       such as ETL pipelines, so they do not need an admin password. When not
       set, the API accepts only admin credentials.
     - —

   * - CREDENTIAL_ACTIVE_DIRECTORY
     - Defines connection parameters for Active Directory authentication.
     - —

.. _applying_config:

Applying configuration changes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

  