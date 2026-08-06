MCP server
==========

XLTable has a built-in `MCP <https://modelcontextprotocol.io>`_ server: an AI
assistant such as Claude can list your cubes, inspect their dimensions and
measures, and run aggregated pivot queries — through the **same live XLTable
instance, cubes and cache that serve your Excel Pivot Tables**. Ask a question
in plain language, get numbers from the same semantic layer Excel uses.

The assistant works only through cubes: it sends cube, dimension and measure
names, and XLTable builds and executes the SQL. Raw SQL access to the
warehouse is never exposed to the assistant.

.. note::

   MCP connectivity is currently available in the free desktop edition
   (``EDITION=free``). The server-edition endpoint with Basic authentication,
   licensing seats and row-level security is under development.

Tools
-----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tool
     - What it does
   * - ``list_cubes``
     - Lists the cubes available on the server (the contents of the local
       cube folder).
   * - ``describe_cube``
     - Returns the cube schema in an assistant-friendly form: dimensions with
       their levels, and measures.
   * - ``query_cube``
     - Runs an aggregated pivot query: group by dimension levels, aggregate
       measures, filter rows before aggregation, limit the result size.

Security roles from the cube definition apply on the MCP path the same way
they apply in Excel.

Claude Desktop: one-click extension
-----------------------------------

Claude Desktop connects through a Desktop Extension package,
``xltable-<version>.mcpb``, shipped alongside the XLTable distribution.
No Node.js or manual JSON editing is required.

1. Start XLTable (``main.exe``) and keep the window open — the extension
   talks to the running server.
2. Open the ``.mcpb`` file with Claude Desktop (double-click it, or drag it
   onto **Settings → Extensions**) and click **Install**.
3. When asked for **XLTable executable (main.exe)**, pick the ``main.exe``
   you run — for example ``C:\xltable\main.exe``.
4. Ask Claude a question about your data — the XLTable tools appear
   automatically. A good first prompt: *“What cubes do I have?”*

.. note::

   Claude Desktop installed from the **Microsoft Store** may fail to install
   any extension with a *“Private dir leaf redirects (junction/substitute-name
   plant)”* error — a quirk of its sandboxed file system, not of the XLTable
   package. Workaround: create two folders manually and retry —
   ``%APPDATA%\Claude\Claude Extensions`` and
   ``%APPDATA%\Claude\Claude Extensions Settings``. The regular Claude Desktop
   installer from `claude.ai/download <https://claude.ai/download>`_ is not
   affected.

Claude Desktop launches ``main.exe --mcp-bridge`` in the background: a thin
stdio bridge that forwards the MCP session to the running server at
``http://127.0.0.1:<port>/mcp`` (the port comes from ``SERVER_PORT`` in
``settings.json`` next to the executable). The bridge never starts the server
itself: if XLTable is not running, the assistant gets the error
*“XLTable is not running — start main.exe”* — open ``main.exe`` and ask again.

Other MCP clients
-----------------

Any MCP client can connect — the server follows the MCP specification and has
no client-specific dependencies:

- **stdio clients** — configure the command ``main.exe --mcp-bridge``.
  Options: ``--url`` overrides the endpoint address, ``--timeout`` the HTTP
  timeout in seconds.
- **HTTP clients** — point the client directly at
  ``http://127.0.0.1:<port>/mcp`` (Streamable HTTP, JSON responses).

Privacy
-------

The connection and the server stay on your machine, and the warehouse
credentials never leave ``settings.json``. Keep in mind, however, that tool
results (cube names, schemas and query results) are sent to the AI assistant
and processed by its cloud model.
