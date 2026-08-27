Support
=======

If you have any questions or problems, please use these contacts:

- Telegram: https://t.me/XLTable
- Email: help@xltable.com

Prefer asking an AI assistant? Feed it the whole documentation as a single
file — see :doc:`ai`.

When reporting a problem, quote the full version string from the admin
console header, e.g. ``v2.1.0 (2026-08-27 6b9eeb4)``. The part in
brackets is the build stamp — the build date and source commit — and it
identifies your build exactly, even when several builds share a version
number. The same string is the first line of every log file.

------------------------------------------------------------

Troubleshooting
---------------

.. _enable_logging:

Enable logging
^^^^^^^^^^^^^^

To diagnose issues, enable logging in ``settings.json``:

.. code-block:: json

   "WRITE_LOG": true

Log files are written to the ``xltable/log`` folder.
The setting is picked up automatically within a few seconds — reproduce the
issue, then inspect the log files.

For Excel connectivity issues, support may additionally ask you to set
``"DUMP_XMLA": true`` — this dumps every raw XMLA request/response to the
``log`` folder. Turn it off after collecting the files.

Old log files are removed automatically after ``LOG_RETENTION_DAYS``
(14 days by default).
