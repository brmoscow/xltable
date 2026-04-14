Frequently Asked Questions (Support)
====================================

Reference links
---------------

- https://xltable.com/
- https://xltable-olap.readthedocs.io/en/latest/

What are the minimum system requirements for installing XLTable?
----------------------------------------------------------------

See the documentation page:
https://xltable-olap.readthedocs.io/en/latest/overview.html#system-requirements

After installation, I see a message that no license is found or that xltable.lic is missing.
-----------------------------------------------------------------------------------------------

You need to upload a license file. Open the Admin Panel:
https://xltable-olap.readthedocs.io/en/latest/install.html#admin-panel

Send the server ID to the vendor or partner who provided your distribution package.
Then upload the license file you receive through the Admin Panel.

I cannot connect to the XLTable server from Excel.
---------------------------------------------------

I get errors such as "Connection failed, target computer actively refused it,"
timeout errors, or an error on the first step of the connection wizard.

Check the connection guide:
https://xltable-olap.readthedocs.io/en/latest/excel.html

Run diagnostics:
https://xltable-olap.readthedocs.io/en/latest/support.html#excel-connection-issues

In the Excel server field, always use the full URL with protocol: ``http://...`` or ``https://....``
Also verify access to XLTable over ports 80/443.

Excel shows an XML parsing error, or curl returns HTTP 500 from the server.
----------------------------------------------------------------------------

Validate ``settings.json`` against the documented schema:
https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema

Required blocks (including ``WRITE_LOG`` and ``CREDENTIAL_DB``) must be present.
After changes, restart the service and test the Excel connection again:
https://xltable-olap.readthedocs.io/en/latest/excel.html

Can I store cube metadata in one ClickHouse instance and actual data in another?
----------------------------------------------------------------------------------

Yes. Connections are defined in ``settings.json`` (``CREDENTIAL_DB`` block),
while cube definitions are stored in the ``olap_definition`` table.

More details:

- https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- https://xltable-olap.readthedocs.io/en/latest/cubes.html#cube-definition-storage

XLTable cannot connect to ClickHouse databases.
-----------------------------------------------

Check ``CREDENTIAL_DB`` parameters (``host``, ``port``, ``secure``) using this example:
https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections

If ClickHouse accepts only TLS/HTTPS, install the correct certificate chain
on the XLTable server and try again.

Where is the specific ClickHouse database configured?
-----------------------------------------------------

The target database and connection parameters are configured in ``settings.json``,
in the ``CREDENTIAL_DB`` block:

- https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema

If the ``olap_definition`` table does not exist, create it as shown here:
https://xltable-olap.readthedocs.io/en/latest/cubes.html#cube-definition-storage

How can I see SQL queries that XLTable sends to ClickHouse?
------------------------------------------------------------

Set ``WRITE_LOG=true`` in ``settings.json``, restart the service,
and check XLTable logs:

- https://xltable-olap.readthedocs.io/en/latest/support.html#enable-logging
- https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema

You can also inspect queries in ClickHouse via ``system.query_log``
using the ``log_comment`` marker.

Data in storage updates frequently; we need to refresh cache.
-------------------------------------------------------------

Is configurable cache TTL planned?

Use two standard methods:

- Refresh in Excel (Refresh / Refresh All).
- Clear cache in the Admin Panel (Clear Cache).

Documentation:

- https://xltable-olap.readthedocs.io/en/latest/excel.html#refreshing-data
- https://xltable-olap.readthedocs.io/en/latest/install.html#admin-panel

Excel queries run too long or timeout; a ClickHouse view is slow while a physical table is faster.
----------------------------------------------------------------------------------------------------

Enable logging first and verify the actual SQL query.
To improve performance, reduce the number of fields/dimensions in the model and PivotTable.
For heavy sources, use narrower views or materialized tables in ClickHouse.

Why is the number of rows returned by XLTable higher than in another analytics system
with a similar report layout?
---------------------------------------------------------------------------------------

Row counts may differ due to different result granularity.
XLTable can include intermediate totals, not only leaf-level rows.
Compare systems with identical dimensions, filters, and subtotal settings.

SQL generation logic:
https://xltable-olap.readthedocs.io/en/latest/cubes.html#sql-generation-logic

The XLTable service does not start automatically after server reboot.
----------------------------------------------------------------------

Check service management instructions:
https://xltable-olap.readthedocs.io/en/latest/install.html#service-management

On Linux, the default setup is often ``supervisor``. Check:

- status: ``sudo supervisorctl status olap``
- logs: ``sudo supervisorctl tail olap``
- execute permissions for the binary file

What access is usually required for a contractor to configure a cube?
----------------------------------------------------------------------

Typical access includes:

- SSH/admin access to the XLTable server
- XLTable access to ClickHouse
- permissions on ``olap_definition`` for cube upload/update
- network access for Excel users to XLTable over 80/443 (or via VPN)

Step-by-step docs:

- https://xltable-olap.readthedocs.io/en/latest/install.html
- https://xltable-olap.readthedocs.io/en/latest/excel.html

The client is migrating from Microsoft SQL Server and SSAS.
------------------------------------------------------------

Can we avoid creating extra objects in ClickHouse?

Yes. You can reduce the number of intermediate ClickHouse objects by moving part
of the logic into the XLTable cube definition (SQL + tags).

References:

- SSAS comparison: https://xltable-olap.readthedocs.io/en/latest/overview.html#comparison-with-ssas
- Cube definition rules: https://xltable-olap.readthedocs.io/en/latest/cubes.html

We need to combine two attributes from different tables into one dimension,
but an error occurs.
---------------------------------------------------------------------------

For attributes from different tables, create separate dimensions and join sources
using ``LEFT JOIN`` in the cube definition.

Working example (Unified example):
https://xltable-olap.readthedocs.io/en/latest/reference.html#unified-example

ClickHouse does not allow nesting window functions inside aggregates
like MDX in Microsoft tools.
--------------------------------------------------------------------

How can we replicate multi-step measure logic?

Use Jinja scripts in the cube definition for multi-step measure logic.
This allows you to inject filters and transform SQL before execution.

Documentation:

- https://xltable-olap.readthedocs.io/en/latest/cubes.html#jinja-scripts
- https://xltable-olap.readthedocs.io/en/latest/reference.html#jinja-context-variables

What is the license cost and trial period length?
--------------------------------------------------

Pricing information is available at:
https://xltable.com/#pricing

Is a trial installation on Microsoft Windows available?
--------------------------------------------------------

Why would a Windows server be needed?

Yes, a Windows Server distribution is available on request.

Installation instructions:
https://xltable-olap.readthedocs.io/en/latest/install.html#windows

For pilots, Linux deployment is usually simpler.
Windows is typically chosen when IT policy requires IIS and Microsoft domain integration.
