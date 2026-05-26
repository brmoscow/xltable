Version History
===============

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
