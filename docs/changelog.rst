Version History
===============

Stay up to date with the latest releases by following us on
`Telegram <https://t.me/XLTable>`_ or `X <https://x.com/XLTable>`_.

------------------------------------------------------------

Version 2.0.17 — upcoming
----------------------------

- **SQL results are cached once and shared between users** — previously query results were cached per user session, so a department opening the same dashboard sent the same SQL to the database once per user; now an identical SQL query is executed once per ``SQL_CACHE_TTL`` (600 seconds by default) and every other user gets the result from the cache within milliseconds. Excel **Refresh** keeps its meaning: the user who presses it bypasses the cached entries obtained before the refresh and — once the data is re-read — updates them for everyone; other users keep using the cache. Row-level security is unaffected: per-user access filters are part of the generated SQL text, so users with different permissions never share results. With ``CACHE_BACKEND: redis`` the cache is shared across all servers of the cluster. Cache size is capped (``SQL_CACHE_MAX_MB``, LRU eviction; ``SQL_CACHE_MAX_RESULT_MB`` per result), the feature can be turned off with ``SQL_CACHE_ENABLED: false``, and the admin panel shows entry count, size and hit rate. See :ref:`refreshing_data`.
- **Query marker in database logs for all connectors** — every SQL query now starts with a ``/* user:<name>, app:xltable */`` comment (previously only ClickHouse tagged queries, via ``log_comment``), so database administrators can find XLTable queries — and see which user requested the data — in the query history of any supported database: ClickHouse ``system.query_log``, Greenplum ``pg_stat_activity``/server log, StarRocks audit log, Trino ``system.runtime.queries``, Snowflake ``QUERY_HISTORY``, Databricks ``system.query.history``, BigQuery ``INFORMATION_SCHEMA.JOBS``. Ready-to-use history queries per database are in the FAQ. The ClickHouse ``log_comment`` marker is kept unchanged.
- **Query timeout for all connectors (query_timeout)** — the ``query_timeout`` parameter in ``CREDENTIAL_DB`` (maximum execution time of a single database query, in seconds; 300 by default) is now honored by every connection type, not only ClickHouse. Where the database supports it, the query is cancelled server-side (Snowflake ``STATEMENT_TIMEOUT_IN_SECONDS``, Databricks ``STATEMENT_TIMEOUT``, Greenplum ``statement_timeout``, Trino ``query_max_execution_time``, StarRocks ``query_timeout``, BigQuery job timeout); for embedded DuckDB the query is interrupted by XLTable itself. See :ref:`database_connections`.
- **Cancelling a running query works in all connectors** — when a refresh is interrupted in Excel (pressing ``Esc``), the server now cancels the query in the database instead of letting it run to completion. Previously only the ClickHouse connector supported this; now the query is cancelled server-side in Greenplum (``pg_cancel_backend``), StarRocks (``KILL QUERY``), Trino (``system.runtime.kill_query``), Snowflake (``SYSTEM$CANCEL_QUERY``) and BigQuery (job cancellation) — for these databases Cancel works across worker processes and servers, same as for ClickHouse. Databricks and embedded DuckDB have no server-side kill command, so the query is interrupted in-process: cancellation applies when the Cancel request reaches the same server process that runs the query.
- **Snowflake key-pair authentication** — the Snowflake connector now supports the authentication method Snowflake recommends for service accounts after deprecating single-factor password sign-ins: specify ``private_key_path`` (and ``private_key_passphrase`` for an encrypted key) in ``CREDENTIAL_DB`` to authenticate with an RSA key pair. A programmatic access token (PAT) can still be passed in the ``password`` field, and existing password-based configurations keep working unchanged. See :ref:`database_connections`.
- **Snowflake performance** — queries run several times faster: the connection to Snowflake is now established once and reused across requests (previously every Excel request opened a new connection, which costs 1–2 seconds in Snowflake), and the warehouse and schema are selected once at connection time instead of two extra network round-trips before every query. A connection that expires or drops is re-established automatically. Also added a ``query_timeout`` setting (300 seconds by default) that cancels runaway queries on the Snowflake side via ``STATEMENT_TIMEOUT_IN_SECONDS``.
- **BigQuery and Databricks performance** — the same connection reuse as for Snowflake: the BigQuery client, together with its live OAuth token, is now shared across requests instead of re-authenticating with Google on every Excel request, and the Databricks warehouse session is kept between requests and re-opened automatically if it expires.
- **Fixed: Expand/Keep Only service queries on Snowflake and Greenplum** — Excel commands that rely on service queries (expanding a single item, Keep Only / Hide Selected Items) failed because these databases change the letter case of unquoted column aliases; the case of the service columns is now restored by the connector. A runtime query error is also no longer misreported as "syntax problems in the cube definition" when the cube definition is in fact valid.

Version 2.0.16 — 2026-07-10
----------------------------

- **DuckDB Connector** — added support for DuckDB as a data source. DuckDB is embedded: the whole database is a single file next to XLTable — no database server to install, which makes it the fastest way to try XLTable or to serve small and medium datasets. Cubes can also be built directly on top of Parquet/CSV files via ``read_parquet()`` / ``read_csv()`` in the cube definition. See :doc:`duckdb_sample`.
- **Multi-server deployments (CACHE_BACKEND: redis)** — several XLTable servers can now share one cache through Redis and work behind a load balancer (e.g. nginx) with no sticky sessions: a session opened through one server is valid on all of them, a running query can be cancelled through any server, the licensed user limit is counted across the whole cluster, and cache management in the admin panel of any server applies to all. The default single-machine cache is unchanged. See :ref:`install_multi_server`.

Version 2.0.15 — 2026-07-04
----------------------------

- **Parallel worker processes on Linux (concurrency)** — the Ubuntu installer now starts several server processes behind nginx load balancing (one per CPU core, up to 4 by default; configurable with ``XLTABLE_INSTANCES``). Heavy reports from many concurrent users are built in parallel instead of queueing on a single CPU core; all processes share one cache and one ``settings.json``. Existing installations pick this up by re-running ``install_xltable.sh``.
- **Worker threads and port settings (SERVER_THREADS, SERVER_PORT)** — the number of worker threads of one server process is now configurable (default raised from 8 to 16, so more database queries stay in flight simultaneously), as is the listening port (``SERVER_PORT``, or the ``OLAP_PORT`` environment variable used by the multi-process setup).
- **Result cache size cap (RESULT_CACHE_MAX_MB)** — query results larger than the configured size (16 MB by default) are no longer stored in the shared result cache: under concurrent load, writing huge cached responses made all worker processes queue on the cache database; such results are cheaper to rebuild. Also sped up the assembly of very large XMLA responses.
- **Collapse / Expand Entire Field** — the Pivot Table context-menu commands **Expand/Collapse → Collapse Entire Field** and **Expand Entire Field** are now supported in all combinations, verified against SSAS traces, both for separate nested fields and for levels of a multi-level hierarchy: collapsing a whole nested field, expanding an entire field or hierarchy level (all items at once), expanding a single item of a collapsed field back (only that item shows the nested field) and collapsing single items of an expanded field. A collapsed field is not queried at all — its table is not scanned or joined until the field is expanded again.
- **Keep Only / Hide Selected Items** — the Pivot Table context-menu commands **Filter → Keep Only Selected Items** and **Hide Selected Items** are now supported, including items of multi-level hierarchies. Excel's service query for the hierarchy position of the selected items (``__XlItemPath`` / ``__XlSiblingCount`` / ``__XlChildCount``) is answered the same way as by SSAS.
- **Large dimension filters** — Keep Only / Hide Selected Items works on dimensions with tens of thousands of members, verified against an SSAS trace with 20,000 items: the full member list is returned to Excel (capped by the new ``MAX_FILTER_MEMBERS`` setting, 100,000 by default), member filters are generated as compact SQL ``IN (...)`` lists instead of ``OR`` chains, and the ClickHouse connector automatically raises ``max_query_size`` for oversized queries (the default 256 KB parser limit rejected large filter lists).
- **Result limit in cells (MAX_CELLS)** — the result size limit is now measured in cells of the pivoted table (row combinations × column combinations × measures) instead of rows, with a default of 1,000,000 — the same way SSAS limits oversized results. The legacy ``MAX_ROWS`` setting is still accepted. A separate, clear message is returned when the columns area exceeds the Excel sheet limit of 16,384 columns.
- **XMLA diagnostics (DUMP_XMLA)** — new setting that dumps every raw XMLA request and response to the ``log`` folder, for diagnosing Excel/XMLA protocol issues.
- **Automatic log cleanup (LOG_RETENTION_DAYS)** — log files older than the configured number of days (14 by default) are now removed automatically.
- **Overload protection (OVERLOAD_GUARD)** — when the server host runs out of memory, CPU or disk space (configurable thresholds), data queries are rejected with a clear "Server is overloaded" message in Excel instead of being forwarded to the database. Metadata requests still pass, so cube connections stay alive.
- **Metadata cache TTL (METADATA_CACHE_TTL)** — cached cube definitions, schema lists and query results now expire after a configurable period (600 seconds by default), so an edited cube is picked up automatically without clearing the cache.
- **Hot reload of settings.json** — configuration changes are picked up automatically within a few seconds of saving the file, without a service restart. A file with a JSON syntax error is ignored (the previous configuration keeps working) and logged.
- **Cache follows settings.json** — database credentials are no longer stored in the cache (they are read from the live configuration on every request), and the cache is cleared automatically whenever the configuration content changes — on hot reload or on service start. A service started with an incorrect configuration no longer requires a manual cache clear after the fix.
- **Authorization cache timeout (AUTH_CACHE_TIMEOUT)** — cached authorizations of local users now expire the same way as Active Directory ones; the new setting applies to both (``LDAP_CACHE_TIMEOUT`` is kept as a legacy fallback).
- **Admin panel: cache management** — new per-user cache overview with last-activity times, a **Sign out** button for a single user, and a **Clear Metadata Cache** action that applies cube changes without signing users out.

Version 2.0.14 — 2026-07-01
----------------------------

- **Drillthrough** — double-clicking a Pivot Table cell now returns the underlying detail rows. Detail columns are configured per measure group with the new ``olap_drillthrough`` tag in the cube definition.
- **New Jinja context** — expanded the Jinja rendering context available in cube definitions with additional variables for building dynamic query logic.
- **Debug console** — new debug console for inspecting rendered SQL, Jinja context and query execution, making cube development and troubleshooting easier.

Version 2.0.13 — 2026-06-18
----------------------------

- **Extended Jinja context** — Jinja templates now receive additional context variables (``user``, ``now``, ``request`` and per-source SQL fragments) for row-level security and dynamic query logic.
- **SQL and XML escaping** — hardened escaping of user names, member values and identifiers across all connectors to prevent SQL injection and malformed XMLA responses.
- **Many-to-many fix** — corrected SQL generation for ``many-to-many`` relationships.
- **Connector fixes** — multiple fixes across database connectors, including ``ILIKE`` support for BigQuery.
- **MCP connector (in development)** — early support for an MCP connector, currently under active development.

Version 2.0.12 — 2026-05-22
----------------------------

- **Greenplum Connector** — added support for Greenplum as a data source.
- **HTTP gzip compression** — server HTTP responses now support gzip compression, reducing the amount of data transferred.
- **Faster XMLA response building** — significantly improved performance when generating XMLA responses with a large number of rows.

Version 2.0.11 — 2026-04-01
----------------------------

- **Databricks Connector** — added support for Databricks as a data source.
- **OLAP cube syntax validation** — new function for validating cube definition syntax before loading.
- **Windows 10 and 11 support** — added the ability to run on Windows 10 and 11 operating systems.

Version 2.0.10 — 2026-03-19
----------------------------

- **StarRocks Connector** — added support for StarRocks as a data source.
- **Admin Panel** — new web-based interface for managing server configuration.
- **Part-source parameter** — added ``part-source`` attribute for defining tag relationships in cube configuration.
- **Jinja context variables** — cube definitions now support Jinja templating with context variables.
- **Improved logging** — enhanced diagnostic output across all supported connectors for easier troubleshooting.
