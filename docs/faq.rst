FAQ
====================================

What are the minimum system requirements for installing XLTable?
----------------------------------------------------------------

See :ref:`system_requirements`.

After installation, I see a message that no license is found or that xltable.lic is missing.
-----------------------------------------------------------------------------------------------

You need to upload a license file. Open the Admin Panel (see :ref:`admin_panel`).

Send the server ID to the vendor or partner who provided your distribution package.
Then upload the license file you receive through the Admin Panel.

I cannot connect to the XLTable server from Excel.
---------------------------------------------------

I get errors such as "Connection failed, target computer actively refused it," timeout errors, or an error on the first step of the connection wizard.

- Check the connection guide: :doc:`excel`
- Run diagnostics: :doc:`support`
- In the Excel server field, always use the full URL with protocol: ``http://...`` or ``https://...``.
- Also verify access to XLTable over ports 80/443.

Excel shows an XML parsing error, or curl returns HTTP 500 from the server.
----------------------------------------------------------------------------

Validate ``settings.json`` against the documented schema: :ref:`settings_schema`.

Required blocks (including ``WRITE_LOG`` and ``CREDENTIAL_DB``) must be present.
Changes are picked up automatically within a few seconds of saving (a file with
a JSON syntax error is ignored and logged, the previous configuration keeps
working) — test the Excel connection again after saving (see :doc:`excel`).

Can I store cube metadata in one ClickHouse instance and actual data in another?
----------------------------------------------------------------------------------

Yes. Connections are defined in ``settings.json`` (``CREDENTIAL_DB`` block), while cube definitions are stored in the ``olap_definition`` table.

More details:

- :ref:`database_connections`
- :ref:`cube_definition_storage`

XLTable cannot connect to ClickHouse databases.
-----------------------------------------------

Check ``CREDENTIAL_DB`` parameters (``host``, ``port``, ``secure``) using the examples in :ref:`database_connections`.

If ClickHouse accepts only TLS/HTTPS, install the correct certificate chain on the XLTable server and try again.

Where is the specific ClickHouse database configured?
-----------------------------------------------------

The target database and connection parameters are configured in ``settings.json``, in the ``CREDENTIAL_DB`` block:

- :ref:`database_connections`
- :ref:`settings_schema`

If the ``olap_definition`` table does not exist, create it as shown in :ref:`cube_definition_storage`.

How can I see SQL queries that XLTable sends to ClickHouse?
------------------------------------------------------------

Set ``WRITE_LOG=true`` in ``settings.json`` (picked up automatically, no
restart needed) and check XLTable logs:

- :ref:`enable_logging`
- :ref:`settings_schema`

You can also inspect queries in ClickHouse via ``system.query_log`` using the ``log_comment`` marker.

How do I specify multiple users in settings.json?
-------------------------------------------------

Use this format:

.. code-block:: json

   "USERS": {
     "user1": "password1",
     "user2": "password2"
   },
   "USER_GROUPS": {
     "user1": ["group_name"],
     "user2": ["group_name"]
   }

How can I view the query history of XLTable users in ClickHouse?
----------------------------------------------------------------

Use the following SQL query:

.. code-block:: sql

   SELECT
       event_time,
       query,
       user,
       query_duration_ms
   FROM system.query_log
   WHERE log_comment LIKE 'user:%, app:xltable'
   ORDER BY event_time DESC
   LIMIT 10;

Data in storage updates frequently; we need to refresh cache. Is configurable cache TTL planned?
--------------------------------------------------------------------------------------------------

The cache TTL is configurable: the ``METADATA_CACHE_TTL`` setting (600 seconds
by default) limits how long cube metadata and query results are served from
the cache before being re-read from the database. See :ref:`settings_schema`.

To refresh immediately, use two standard methods:

- Refresh in Excel (Refresh / Refresh All)
- Clear Metadata Cache in the Admin Panel

Documentation:

- :ref:`refreshing_data`
- :ref:`admin_panel`

Why are cube changes not visible to users after updating the cube?
------------------------------------------------------------------

An edited cube definition is picked up automatically within
``METADATA_CACHE_TTL`` (600 seconds by default). To apply it immediately, use
**Clear Metadata Cache** in the Admin Panel (``http://<server>/admin``) —
users stay signed in — or click Refresh in Excel for an individual user.

Excel queries run too long or timeout; a ClickHouse view is slow while a physical table is faster.
----------------------------------------------------------------------------------------------------

Enable logging first and verify the actual SQL query.
To improve performance, reduce the number of fields/dimensions in the model and PivotTable.
For heavy sources, use narrower views or materialized tables in ClickHouse.

Why is the number of rows returned by XLTable higher than in another analytics system with a similar report layout?
---------------------------------------------------------------------------------------------------------------------

Row counts may differ due to different result granularity.
XLTable can include intermediate totals, not only leaf-level rows.
Compare systems with identical dimensions, filters, and subtotal settings.

See :ref:`sql_generation_logic`.

How does XLTable generate SQL from a cube definition: are all CTEs executed or only the required ones?
-------------------------------------------------------------------------------------------------------

XLTable generates a query based on the current context of the fields selected in Excel. Only the required tables and fields are used, not the entire model.

For CTEs, only the parts actually used in the query participate in execution.

Useful documentation sections:

- :ref:`cte`
- :ref:`sql_generation_logic`

The XLTable service does not start automatically after server reboot.
----------------------------------------------------------------------

Check the service management instructions: :ref:`service_management`.

On Linux, the default setup is often supervisor. Check:

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

- :doc:`install`
- :doc:`excel`

The client is migrating from Microsoft SQL Server and SSAS. Can we avoid creating extra objects in ClickHouse?
---------------------------------------------------------------------------------------------------------------

Yes. You can reduce the number of intermediate ClickHouse objects by moving part of the logic into the XLTable cube definition (SQL + tags).

References:

- SSAS comparison: :ref:`ssas_comparison`
- Cube definition rules: :doc:`cubes`

We need to combine two attributes from different tables into one dimension, but an error occurs.
-------------------------------------------------------------------------------------------------

For attributes from different tables, create separate dimensions and join sources using LEFT JOIN in the cube definition.

Working example: :ref:`unified_example`.

ClickHouse does not allow nesting window functions inside aggregates like MDX in Microsoft tools. How can we replicate multi-step measure logic?
---------------------------------------------------------------------------------------------------------------------------------------------------

Use Jinja scripts in the cube definition for multi-step measure logic.
This allows you to inject filters and transform SQL before execution.

Documentation:

- :ref:`jinja_scripts`
- :ref:`jinja_var`

What is the license cost and trial period length?
--------------------------------------------------

Pricing information is available at:
https://xltable.com/#pricing

Is a trial installation on Microsoft Windows available? Why would a Windows server be needed?
-----------------------------------------------------------------------------------------------

Yes, a Windows Server distribution is available on request.

Installation instructions: :ref:`install_windows`.

For pilots, Linux deployment is usually simpler. Windows is typically chosen when IT policy requires IIS and Microsoft domain integration.

Can XLTable be connected from LibreOffice or OpenOffice?
----------------------------------------------------------

Currently, the service works only with Excel. Support for other clients is planned for the future.

Excel cannot connect to the server.
------------------------------------

- Verify the server address is reachable from the client machine (port 80 or 443).
- Check that Nginx is running: ``sudo service nginx status``.
- Check that XLTable is running: ``sudo supervisorctl status``.

I get an authentication error in Excel.
-----------------------------------------

- Verify the username and password in ``settings.json`` under the ``USERS`` key.
- If using Active Directory, verify the ``CREDENTIAL_ACTIVE_DIRECTORY`` settings.
- Changes to ``settings.json`` are picked up automatically within a few seconds of saving.

The Pivot Table shows no data.
--------------------------------

- Confirm the ``olap_definition`` table exists in the database and contains at least one cube definition.
- Enable logging and check the generated SQL queries for errors.
- Verify the database credentials in ``CREDENTIAL_DB`` have read access to the relevant tables.

Queries are slow.
------------------

- Enable ``WRITE_LOG`` to inspect the generated SQL and identify bottlenecks.
- Pre-aggregate data in the database where possible.
- Reduce the number of dimensions selected in the Pivot Table.

The Pivot Table reports "too many data cells".
-----------------------------------------------

- The result size limit is measured in cells of the pivoted table (rows ×
  columns × measures), 1,000,000 by default. Adjust ``MAX_CELLS`` in
  ``settings.json`` if needed (the legacy ``MAX_ROWS`` key is still accepted).
- Add filters in the Pivot Table to reduce the result set.
- A separate message appears when the columns area produces more than
  16,384 columns (the Excel sheet limit) — move fields from columns to rows
  or apply filters.

The XLTable service does not start on Linux.
---------------------------------------------

Check the Supervisor logs:

.. code-block:: bash

   sudo supervisorctl tail olap

The XLTable service does not start on Windows.
------------------------------------------------

XLTable on Windows runs under IIS (FastCGI):

- Check that the IIS application pool is started (IIS Manager → Application Pools).
- Verify the FastCGI application is registered with the correct paths to
  ``python.exe`` and ``wfastcgi.py`` (see :ref:`install_windows`).
- Check the Windows Event Log and the XLTable ``log`` folder for error output.
