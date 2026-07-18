Connecting Excel
================

XLTable exposes a standard XMLA endpoint, so connecting Excel to XLTable
is identical to connecting to Microsoft SQL Server Analysis Services (SSAS).

Any Excel feature that works with SSAS works with XLTable — Pivot Tables,
Power Query, slicers, named sets, MDX formulas and more.

------------------------------------------------------------

Adding an Analysis Services data source
----------------------------------------

1. Open Excel.
2. Go to **Data** → **Get Data** → **From Database** → **From Analysis Services**.

   In older Excel versions: **Data** → **From Other Sources** → **From Analysis Services**.

3. In the **Server name** field, enter the XLTable server address: ``http://your_server_ip``

4. In the **Log on credentials** section, select **Use the following User Name and Password**
   and enter the credentials configured in ``settings.json``.

   If Active Directory integration is enabled, select **Use Windows Authentication** —
   Excel will use the current domain session credentials automatically.

5. Click **Next**.

6. Select the database and cube from the list.

7. Click **Finish**.

Excel will create a new Pivot Table connected to XLTable.

------------------------------------------------------------

Authentication modes
---------------------

Basic authentication (username and password)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Used when ``USERS`` are defined in ``settings.json``.

Select **Use the following User Name and Password** in the connection wizard
and enter the credentials from the ``USERS`` section of ``settings.json``.

Active Directory (Windows authentication)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Used when ``CREDENTIAL_ACTIVE_DIRECTORY`` is configured in ``settings.json``.

Select **Use Windows Authentication** in the connection wizard.
Excel will use the current domain session credentials automatically —
no username or password needs to be entered manually.

------------------------------------------------------------

Connection string (advanced)
------------------------------

If you need to connect programmatically or configure the data source manually,
use the following OLEDB connection string:

.. code-block::

   Provider=MSOLAP;Data Source=http://your_server_ip;Initial Catalog=;

Replace ``http://your_server_ip`` with the actual server address.

This connection string is used by Excel through the MSOLAP provider.
XLTable currently targets Excel as its client application.

------------------------------------------------------------

.. _refreshing_data:

Refreshing data
----------------

Pivot Table data is refreshed on demand:

- Right-click the Pivot Table → **Refresh**
- Or use **Data** → **Refresh All**

XLTable executes SQL queries against the database on refresh, with two
levels of caching that reduce database load:

- each session keeps its already-built responses, so repeating the same
  report view does not re-run the query;
- SQL query results are **shared between users**: when several users look at
  the same report, the query runs in the database once per ``SQL_CACHE_TTL``
  (600 seconds by default) and the others are served from the cache within
  milliseconds.

Pressing **Refresh** always gives the pressing user fresh data: cached
results obtained before the refresh are bypassed for that user and, once
re-read from the database, updated for everyone else as well. Users who do
not press Refresh keep being served from the cache until its TTL expires.

Row-level security is unaffected by the shared cache: per-user access
filters are part of the generated SQL text, so users with different
permissions never share query results. See :ref:`settings_schema` for the
``SQL_CACHE_*`` settings.

------------------------------------------------------------

.. _excel_drillthrough:

Drill through to detail rows
----------------------------

**Double-click any value cell** in a Pivot Table to drill through. Excel opens a
new sheet listing the underlying detail rows behind that aggregated value — the
individual records that were summed into the cell.

The columns shown are configured per measure group in the cube definition with the
``olap_drillthrough`` tag (see :ref:`drillthrough`). The cell's row, column and
slicer context is applied automatically as a filter, so you only see the rows that
make up that specific cell. The number of rows is capped by the drillthrough limit
Excel sends with the request.

Drill through is available on measures. Calculated fields cannot be drilled —
double-clicking such a cell returns a message instead of data, because a calculated
field has no single set of underlying rows.

------------------------------------------------------------

Filtering by selected items
---------------------------

Besides the field filter dropdown, Pivot Table items can be filtered directly
from the selection: select one or more items in the Pivot Table, right-click and
choose **Filter** → **Keep Only Selected Items** or **Hide Selected Items**.

Both commands work the same way as with SSAS, including items of multi-level
hierarchies. Excel first asks the server for the hierarchy position of each
selected item and then applies the resulting filter to the field.

------------------------------------------------------------

Expanding and collapsing fields
-------------------------------

Nested Pivot Table fields can be expanded and collapsed the same way as with
SSAS — per item with the **+** / **−** buttons, or for the whole field at once:
right-click an item and choose **Expand/Collapse** → **Collapse Entire Field**
or **Expand Entire Field**.

All combinations are supported, both for separate nested fields and for levels
of a multi-level hierarchy: collapsing an entire field, expanding an entire
field or hierarchy level (all items at once), expanding a single item of a
collapsed field back (only that item shows the nested field), and collapsing
single items of an expanded field. A collapsed field costs nothing on the
database side — its table is not scanned or joined at all until the field is
expanded again.

The **Expand/Collapse** → **Expand To "<level name>"** command is supported as
well: a single item of a multi-level hierarchy can be expanded several levels
deep in one click — for example, a year straight down to days.

------------------------------------------------------------

Troubleshooting connection issues
-----------------------------------

See the :doc:`support` page for common connection problems and solutions.
