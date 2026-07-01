Version History
===============

Stay up to date with the latest releases by following us on
`Telegram <https://t.me/XLTable>`_ or `X <https://x.com/XLTable>`_.

------------------------------------------------------------

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
