Quickstart
==========

XLTable Desktop turns your warehouse tables into Excel PivotTables — and lets
an AI assistant answer questions from the same cubes. It is free, runs
entirely on your Windows machine, and requires no license, no server to
deploy and no administrator rights; no data leaves your network.

This guide takes you to the first run; from there the product itself walks
you through the rest. For a multi-user server installation on Linux or
Windows Server, see :doc:`install`.

------------------------------------------------------------

What you need first
-------------------

- **Access to your data warehouse** — host, user and password, the same
  credentials you use in DBeaver or DataGrip. ClickHouse, BigQuery,
  Snowflake, Trino, StarRocks, Greenplum, Databricks and DuckDB are
  supported.
- **Microsoft Excel** — Microsoft 365 or Excel 2016+.
- **Windows 10 or 11.**

------------------------------------------------------------

Install
-------

Download ``XLTable-<version>-setup.exe`` and run it — a Next-Finish wizard
installs XLTable into your user profile. Administrator rights are **not**
required and no UAC elevation prompt appears.

.. note::

   The installer is digitally signed by **BR Systems LLP**. Windows may
   still show a blue *"Windows protected your PC"* (SmartScreen) dialog on
   the first run of a freshly downloaded installer while a new release
   builds up its download reputation — this is not a virus alert. Click
   the small **More info** link, check that **Publisher** names BR Systems
   LLP, then **Run anyway**. Details: :ref:`install_windows_desktop`.

Prefer a portable copy without an installer? Use the zip archive instead —
see :ref:`install_windows_zip`.

------------------------------------------------------------

First run
---------

Start XLTable from the Start menu (**XLTable Desktop**). A console window opens —
that window *is* the server: keep it open while you work, closing it stops
the server.

The browser then opens the admin console on the **Quick start** page
(``http://127.0.0.1:5000/admin``) — a checklist of four steps: connect
your warehouse, create your first cube from any table, connect Excel,
connect an AI assistant. From here, just follow the checklist in the
browser: each step leads to the page where it is completed, and the
statuses update as you go. The first PivotTable usually takes about ten
minutes.

Every detail of the first launch — what each step does, repeated launches,
what happens when the port is taken — is described in :ref:`start_page`.

------------------------------------------------------------

Next steps
----------

- :doc:`mcp` — connect an AI assistant to your cubes: Claude Desktop,
  Claude Code, Copilot in VS Code, a local model, or any other MCP client
- :doc:`cubes` — the cube definition format: measures, dimensions,
  hierarchies, and refining a generated cube by hand
- :ref:`upgrade_from_free` — when a second person needs your cubes:
  upgrading to the server edition (the cube files work there unchanged)
- :doc:`support` — troubleshooting and contact information
