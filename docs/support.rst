Support
=======

If you have any questions or problems, please use these contacts:

- Telegram: https://t.me/XLTable
- Email: help@xltable.com

------------------------------------------------------------

Troubleshooting
---------------

Enable logging
^^^^^^^^^^^^^^

To diagnose issues, enable logging in ``settings.json``:

.. code-block:: json

   "WRITE_LOG": true

Log files are written to the ``xltable/xml`` folder.
After enabling, restart the service and reproduce the issue, then inspect the log files.

Excel connection issues
^^^^^^^^^^^^^^^^^^^^^^^

**Excel cannot connect to the server**

- Verify the server address is reachable from the client machine (port 80 or 443).
- Check that Nginx is running: ``sudo service nginx status``.
- Check that XLTable is running: ``sudo supervisorctl status``.

**Authentication error in Excel**

- Verify the username and password in ``settings.json`` under the ``USERS`` key.
- If using Active Directory, verify the ``CREDENTIAL_ACTIVE_DIRECTORY`` settings.
- After any changes to ``settings.json``, restart the service.

**Pivot Table shows no data**

- Confirm the ``olap_definition`` table exists in the database and contains at least one cube definition.
- Enable logging and check the generated SQL queries for errors.
- Verify the database credentials in ``CREDENTIAL_DB`` have read access to the relevant tables.

Query and performance issues
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Queries are slow**

- Enable ``WRITE_LOG`` to inspect the generated SQL and identify bottlenecks.
- Pre-aggregate data in the database where possible.
- Reduce the number of dimensions selected in the Pivot Table.

**Too many rows returned**

- The default row limit is 50,000. Adjust ``MAX_ROWS`` in ``settings.json`` if needed.
- Add filters in the Pivot Table to reduce the result set.

Service issues
^^^^^^^^^^^^^^

**XLTable service does not start (Linux)**

Check the Supervisor logs:

.. code-block:: bash

   sudo supervisorctl tail olap

**XLTable service does not start (Windows)**

Check the Windows Event Log or run the service binary directly from a command prompt
to see the error output:

.. code-block:: bash

   C:\olap\xltable\main.exe
