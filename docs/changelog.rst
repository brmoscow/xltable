Version History
===============

Stay up to date with the latest releases by following us on
`Telegram <https://t.me/XLTable>`_ or `X <https://x.com/XLTable>`_.

------------------------------------------------------------

Version 2.0.15 — 2026-07-04
----------------------------

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
