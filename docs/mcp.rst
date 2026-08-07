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

MCP connectivity is available in both editions: the free desktop edition
connects anonymously on the local machine, the server edition requires the
user's XLTable credentials — see `Server edition`_ below.

Tools
-----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tool
     - What it does
   * - ``list_cubes``
     - Lists the cubes available on the server (the free edition reads them
       from the local cube folder).
   * - ``describe_cube``
     - Returns the cube schema in an assistant-friendly form: dimensions with
       their levels, and measures.
   * - ``query_cube``
     - Runs an aggregated pivot query: group by dimension levels, aggregate
       measures, filter rows before aggregation, limit the result size.
   * - ``list_databases``
     - Server edition with ``CUBE_SOURCE=database`` only: lists the databases
       (cube catalogs) of the warehouse.

Security roles from the cube definition apply on the MCP path the same way
they apply in Excel.

When the server reads cube definitions from the ``olap_definition`` table
(``CUBE_SOURCE=database``), the tools also accept an optional ``database``
argument — the assistant takes the name from ``list_databases``. If the
warehouse has a single database, it is selected automatically and the
argument can be omitted. In the free edition there is always exactly one
catalog (the cube folder), so neither the tool nor the argument appears.

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
  timeout in seconds; ``--user`` / ``--password`` add server-edition
  credentials (see below).
- **HTTP clients** — point the client directly at
  ``http://127.0.0.1:<port>/mcp`` (Streamable HTTP, JSON responses).

Server edition
--------------

In the server edition the ``/mcp`` endpoint requires HTTP Basic
authentication with a user from ``USERS`` in ``settings.json`` — the same
accounts, session cache and ``AUTH_CACHE_TIMEOUT`` as the Excel (XMLA)
endpoint. A request without valid credentials is answered with
``401 Unauthorized``.

Everything else is enforced by the engine, exactly as on the Excel path:

- **Row-level security.** Cube security roles are applied by user name and
  groups: the assistant sees the same cubes, fields and rows the user sees
  in Excel — nothing more.
- **Licensing.** The MCP connection occupies the user's named seat — the
  same seat as their Excel connection (one name = one seat), so connecting
  an assistant does not consume an extra license seat.
- **Cube catalogs.** Both cube sources work: the watched folder
  (``CUBE_SOURCE=folder``) and the ``olap_definition`` table
  (``CUBE_SOURCE=database``). With the database source the tools gain the
  optional ``database`` argument and the ``list_databases`` tool (see
  `Tools`_).

.. warning::

   Basic authentication sends the password with every request. Never expose
   ``/mcp`` over the network by plain HTTP — publish it through an HTTPS
   reverse proxy (IIS or nginx), the same pattern used for the XMLA
   endpoint (see :doc:`install`). Plain HTTP is acceptable only on
   ``127.0.0.1``.

Connecting to a server:

- **Claude Desktop** — install the same ``.mcpb`` extension and fill in the
  optional fields: **Server URL** (``https://your-server/mcp``), **Server
  user** and **Server password**. Claude Desktop stores the password in the
  OS keychain and hands it to the bridge through an environment variable —
  it is kept out of both the config file and the process command line.
- **stdio clients** — ``main.exe --mcp-bridge --url https://your-server/mcp
  --user <name> --password <password>``; the password can also be supplied
  via the ``XLTABLE_MCP_PASSWORD`` environment variable instead of the
  command line.
- **HTTP clients** (server platforms, MCP Inspector, …) — send a standard
  ``Authorization: Basic`` header with each request to
  ``https://your-server/mcp``.
- **Platforms whose authorization field only accepts Bearer tokens**
  (e.g. Yandex AI Studio) — pass the same credentials packed as a token:
  ``Authorization: Bearer <base64 of user:password>``. This is the same
  account checked by the same code — only the header format differs.

Privacy
-------

The connection and the server stay on your machine, and the warehouse
credentials never leave ``settings.json``. Keep in mind, however, that tool
results (cube names, schemas and query results) are sent to the AI assistant
and processed by its cloud model.
