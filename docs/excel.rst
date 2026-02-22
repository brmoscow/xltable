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

3. In the **Server name** field, enter the XLTable server address:

   - Basic authentication: ``http://your_server_ip``
   - Active Directory authentication: ``http://your_server_ip/ad``

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

Use the server address with the ``/ad`` suffix:

.. code-block::

   http://your_server_ip/ad

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

This connection string is compatible with Excel, Power BI Desktop,
and any other OLAP client that supports the MSOLAP provider.

------------------------------------------------------------

Refreshing data
----------------

Pivot Table data is refreshed on demand:

- Right-click the Pivot Table → **Refresh**
- Or use **Data** → **Refresh All**

XLTable will execute SQL queries against the database for each refresh.
Query result caching reduces database load for repeated requests.

------------------------------------------------------------

Troubleshooting connection issues
-----------------------------------

See the :doc:`support` page for common connection problems and solutions.
