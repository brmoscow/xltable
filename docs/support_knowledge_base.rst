Frequently Asked Questions (Support)
====================================

Reference Information
---------------------

- https://xltable.com/
- https://xltable-olap.readthedocs.io/en/latest/

.. contents:: On This Page
   :local:
   :depth: 1

What are the minimum system requirements for XLTable installation?
------------------------------------------------------------------

See:
https://xltable-olap.readthedocs.io/en/latest/overview.html#system-requirements

After installation, I see a missing license message or no xltable.lic file
----------------------------------------------------------------------------

You need to upload a license file.

1. Open the Admin Panel:
   https://xltable-olap.readthedocs.io/en/latest/install.html#admin-panel
2. Send the ``server_id`` to the vendor or partner who provided the distribution package.
3. Upload the received license file through the Admin Panel.

I cannot connect to the XLTable server from Excel
--------------------------------------------------

Symptoms: connection refused, timeout, or failure on the first step of the Excel connection wizard.

- Check the connection guide:
  https://xltable-olap.readthedocs.io/en/latest/excel.html
- Run diagnostics:
  https://xltable-olap.readthedocs.io/en/latest/support.html#excel-connection-issues
- In Excel, always use a full server URL with protocol: ``http://...`` or ``https://...``.
- Verify network access to XLTable on port ``80/443``.

Excel shows an XML parsing error, or curl returns HTTP 500
-----------------------------------------------------------

- Validate ``settings.json`` against the schema:
  https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema
- Make sure required blocks are present, including ``WRITE_LOG`` and ``CREDENTIAL_DB``.
- After changes, restart the service and test the Excel connection again:
  https://xltable-olap.readthedocs.io/en/latest/excel.html

Can I store cube metadata in one ClickHouse instance and fact data in another?
--------------------------------------------------------------------------------

Yes. Connections are configured in ``settings.json`` (``CREDENTIAL_DB``), while cube definitions are stored in the ``olap_definition`` table.

Details:

- https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- https://xltable-olap.readthedocs.io/en/latest/cubes.html#cube-definition-storage

XLTable cannot connect to ClickHouse databases
----------------------------------------------

- Verify ``CREDENTIAL_DB`` parameters (``host``, ``port``, ``secure``):
  https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- If ClickHouse accepts only TLS/HTTPS, install the correct certificate chain on the XLTable server and retry.

Where is the specific ClickHouse database configured?
-----------------------------------------------------

The target database and connection settings are configured in ``settings.json`` under ``CREDENTIAL_DB``:

- https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema

If the ``olap_definition`` table does not exist, create it as shown here:
https://xltable-olap.readthedocs.io/en/latest/cubes.html#cube-definition-storage

How can I see SQL queries sent by XLTable to ClickHouse?
---------------------------------------------------------

- Enable ``WRITE_LOG=true`` in ``settings.json``
- Restart the service
- Check XLTable logs:
  - https://xltable-olap.readthedocs.io/en/latest/support.html#enable-logging
  - https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema
- Optionally inspect ClickHouse ``system.query_log`` using a ``log_comment`` marker.

Data in storage is updated often; we need cache refresh. Is configurable cache TTL planned?
---------------------------------------------------------------------------------------------

Use two standard options:

- refresh in Excel (``Refresh/Refresh All``)
- clear cache in the Admin Panel (``Clear Cache``)

Documentation:

- https://xltable-olap.readthedocs.io/en/latest/excel.html#refreshing-data
- https://xltable-olap.readthedocs.io/en/latest/install.html#admin-panel

Long execution or timeout in Excel: ClickHouse view is slow, physical table is faster
---------------------------------------------------------------------------------------

- Enable logging and check the actual SQL first
- Reduce the number of fields and dimensions in the model and PivotTable
- For heavy sources, use narrower views or materialized ClickHouse tables

Why does XLTable return more rows than another analytics system with a similar report layout?
-----------------------------------------------------------------------------------------------

Row counts can differ because of different result granularity: XLTable may include intermediate totals, not only leaf-level rows.

For fair comparison, align:

- dimensions
- filters
- subtotal level

SQL generation details:
https://xltable-olap.readthedocs.io/en/latest/cubes.html#sql-generation-logic

XLTable service does not start automatically after server reboot
----------------------------------------------------------------

- Check service management:
  https://xltable-olap.readthedocs.io/en/latest/install.html#service-management
- On Linux, the baseline setup is often ``supervisor``:
  - status: ``sudo supervisorctl status olap``
  - logs: ``sudo supervisorctl tail olap``
  - executable permissions for the binary

What access is typically required for a contractor to configure a cube?
------------------------------------------------------------------------

Typical access includes:

- SSH/admin access to the XLTable server
- XLTable access to ClickHouse
- permissions on ``olap_definition`` to upload and update cubes
- network access for Excel users to XLTable on ``80/443`` (or via VPN)

Step-by-step references:

- https://xltable-olap.readthedocs.io/en/latest/install.html
- https://xltable-olap.readthedocs.io/en/latest/excel.html

Client is migrating from Microsoft SQL Server and SSAS. Can we avoid extra ClickHouse objects?
------------------------------------------------------------------------------------------------

Yes. You can reduce the number of intermediate ClickHouse objects by moving part of the logic into XLTable cube definition (SQL + tags).

References:

- SSAS comparison:
  https://xltable-olap.readthedocs.io/en/latest/overview.html#comparison-with-ssas
- Cube definition rules:
  https://xltable-olap.readthedocs.io/en/latest/cubes.html

We need to combine two attributes from different tables into one dimension, but get an error
----------------------------------------------------------------------------------------------

For attributes from different tables, create separate dimensions and join data sources with ``LEFT JOIN`` in cube definition.

Working example (Unified example):
https://xltable-olap.readthedocs.io/en/latest/reference.html#unified-example

ClickHouse cannot nest window functions inside aggregates like MDX in Microsoft tools. How do we replicate multi-step measure logic?
-----------------------------------------------------------------------------------------------------------------------------

Use Jinja in cube definition for multi-step measure logic. This allows injecting filters and transforming SQL before execution.

Documentation:

- https://xltable-olap.readthedocs.io/en/latest/cubes.html#jinja-scripts
- https://xltable-olap.readthedocs.io/en/latest/reference.html#jinja-context-variables

What is the license cost and trial period length?
--------------------------------------------------

Pricing information:
https://xltable.com/#pricing

Is trial installation on Microsoft Windows available, and why would a Windows server be needed?
-------------------------------------------------------------------------------------------------

Yes, a Windows Server distribution is available on request.

Installation instructions:
https://xltable-olap.readthedocs.io/en/latest/install.html#windows

For pilots, Linux deployment is usually simpler. Windows is typically chosen when IT policy requires IIS and Microsoft domain integration.
