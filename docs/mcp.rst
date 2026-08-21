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
       from the local cube folder), each with a short description when the
       cube author wrote one.
   * - ``describe_cube``
     - Returns the cube schema in an assistant-friendly form: dimensions with
       their levels, and measures — plus the semantics the cube author
       described (see `Describing cubes for AI`_).
   * - ``query_cube``
     - Runs an aggregated pivot query: group by dimension levels, aggregate
       measures, filter rows before aggregation, limit the result size.
   * - ``get_pivot_context``
     - Returns the layout of the last Pivot Table the user queried from
       Excel — see `Working alongside Excel`_.
   * - ``list_warehouse_tables``
     - Folder cube source only: lists the tables and views of the connected
       warehouse — names only, optionally filtered by a substring. The chat
       counterpart of the autogen wizard's table-filter step.
   * - ``autogen_cube``
     - Folder cube source only: generates a cube from a single warehouse
       table with the same engine as ``XLTable.exe autogen`` — see
       `Creating cubes from the chat`_.
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

.. _mcp_semantics:

Describing cubes for AI
-----------------------

An assistant answers far better when it sees *described* fields instead of a
bare schema. Four optional tags in the cube definition carry that description;
they are metadata only — Excel and the XMLA path ignore them completely, and a
cube file with them keeps working unchanged on any XLTable server.

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Tag
     - What it adds
   * - :tag:`olap_description`
     - Cube level: what the data is, its grain, which questions it answers.
       ``list_cubes`` shows the first paragraph, ``describe_cube`` returns the
       whole text.
   * - :tag:`olap_ai_instructions`
     - Cube level: free-form instructions for the assistant, returned by
       ``describe_cube`` as written.
   * - :tag:`description`
     - Field level: business meaning, units, caveats.
   * - :tag:`synonyms`
     - Field level: alternative names the user may use in a question,
       separated by ``;``. Complements :tag:`translation` (one display name
       for Excel), it does not replace it.

Cube-level blocks run to the next ``--olap_*`` tag or to the end of the file,
so write them **at the very end** of the definition. Lines starting with
``--`` inside a block are comments and are not part of the text.

.. code-block:: sql

   --olap_source Sales
   SELECT
   --olap_measures
    sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`
        --description=`Revenue including VAT, in KZT`
        --synonyms=`revenue;turnover;sales`
   FROM db.Sales sales

   --olap_description
   Sales fact cube, one row per sale line.

   Answers questions about revenue and quantity by store, model and period.
   --olap_ai_instructions
   Compare years only over completed months.

Start with :tag:`olap_description` — it is what an assistant reads first, and
:ref:`autogen <cube_autogen>` already leaves an empty one at the bottom of
every generated cube for you to fill in. Add field descriptions and synonyms
later, for the fields whose names are ambiguous on their own.

**Sample values come from the engine, not from the file.** For every
low-cardinality dimension level, ``describe_cube`` also returns the actual
list of its values, fetched live with the same query that fills a filter
drop-down in Excel — so the assistant knows to filter by ``North`` rather than
guessing ``North Region``. Values are never stored in the cube file: they
cannot go stale, and they honor row-level security — a user sees only the
values their access filters allow. Levels with more than 30 distinct values
are skipped: enumerating them for an assistant is neither useful nor cheap.

.. _mcp_pivot_context:

Working alongside Excel
-----------------------

Excel and the assistant talk to the **same live engine**, which makes them
teammates rather than parallel worlds:

- **The assistant sees what you are looking at.** Every Pivot Table query
  Excel sends is parsed by the server anyway; XLTable keeps the last parsed
  layout per user, and ``get_pivot_context`` returns it: the cube, the
  dimension levels on rows and columns, the measures and the filters — in
  the same names ``describe_cube`` uses, plus a ready-made specification
  that reproduces the same slice through ``query_cube``. Typical prompts:
  *“Explain this number”*, *“Continue my analysis”*, *“Do your figures match
  my Pivot Table?”*. If no pivot has been queried yet, the tool says so
  explicitly instead of failing. With several workbooks open, the most
  recent pivot wins; closing a workbook does not lose the context.

  The context belongs to the user: in the server edition each user gets only
  their own last pivot, and if the cube (or some of its fields) has since
  become unavailable to them — the cube was edited, or security roles
  changed — the tool returns an explicit note instead of the stale layout.

- **Refresh is honored across both paths.** Pressing **Refresh** in Excel
  marks the user's cached SQL results as stale — and the assistant respects
  the same mark: after a Refresh, ``query_cube`` re-reads the warehouse
  instead of answering from a cache entry fetched before it. The assistant
  and the Pivot Table cannot drift apart after a refresh.

- **The cache warms up in both directions.** A slice computed for the
  assistant opens instantly in Excel, and vice versa (see
  `Logging and cache`_).

The reverse direction is deliberately manual: XMLA is a pull protocol, so the
assistant cannot push a layout *into* Excel — it can only tell the user which
fields to drag where.

.. _mcp_create:

Creating cubes from the chat
----------------------------

*“I have a table sales — make a cube and show me sales by month”* works in a
single chat, no console needed. Two tools cover it when cubes are read from
the cube folder (``CUBE_SOURCE=folder`` — the free edition and folder-based
servers):

- ``list_warehouse_tables`` lists the tables and views of the connected
  warehouse, optionally narrowed by a case-insensitive substring — the same
  step as the table filter of the console wizard, for the *“I don't remember
  what the table is called”* moment. Only names are exposed: no data, no raw
  SQL.
- ``autogen_cube`` takes an exact table name from that list and runs the same
  :ref:`autogen engine <cube_autogen>` that powers ``XLTable.exe autogen``:
  profile the table, classify the columns into dimensions, date hierarchies
  and measures, write a ``.sql`` cube file into the cube folder. The server
  picks the file up immediately, so the new cube can be queried with
  ``query_cube`` — and refined by hand later, like any generated cube.

Two safety rules hold on this path:

- **An existing cube file is never overwritten silently.** It may have been
  edited by hand; without ``overwrite=true`` the call fails with an explicit
  message and changes nothing — the decision to replace a cube is always
  yours, made in the chat. ``autogen_cube`` is also marked as a *writing*
  tool, so MCP clients such as Claude Desktop ask for confirmation before
  running it.
- **The table name must match the warehouse listing exactly.** The assistant
  can only pick tables that ``list_warehouse_tables`` returned — the same
  boundary as everywhere else in the MCP surface: names in, SQL stays on the
  server.

An Excel Pivot Table that is already open keeps the previous cube metadata
until it is refreshed: after creating or overwriting a cube, press **Refresh**
in the Pivot Table (the assistant will remind you). New Excel connections and
``query_cube`` see the cube immediately.

When cube definitions live in the ``olap_definition`` table
(``CUBE_SOURCE=database``), the creation tools are not offered — the autogen
engine writes files, and there is no cube folder to write to.

.. _mcp_clients:

AI clients
----------

MCP is an open protocol, and the XLTable server has no client-specific
dependencies — pick whichever assistant you can use. In the free desktop
edition every client below talks to the same local endpoint::

   http://127.0.0.1:<port>/mcp

(Streamable HTTP; the port is ``SERVER_PORT`` from ``settings.json``, ``5000``
by default). **No authorization is required or expected**: the free edition
serves one local user and ignores ``Authorization`` headers — leave credential
fields empty, and if a client insists on a value, enter anything.

.. note::

   The walkthroughs below are written for the **free desktop edition**:
   local URL, no credentials. On the **server edition** the client steps
   are the same, but the URL is your server's HTTPS address and every
   request must be authorized — take the connection details from
   `Server edition`_ below.

Step 4 of the **Quick start** page in the admin console (see
:ref:`start_page`) offers the same choice of clients with the real port
already substituted and every config ready to copy.

.. note::

   MCP support in AI clients changes monthly. The instructions below were
   verified against each client's official documentation in August 2026 —
   if a client's menus have moved since, its own MCP page is the authority.

Claude Desktop: one-click extension
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*What you need:* Claude Desktop for Windows, signed in with any Claude
account — the free plan is enough.

Claude Desktop connects through a Desktop Extension package,
``xltable.mcpb``, shipped alongside the XLTable distribution
(``xltable-<version>.mcpb`` in releases before 2.1.0).
No Node.js or manual JSON editing is required. In the free desktop edition
the file can also be downloaded right from the **Connect Excel & AI** page
of the admin console (Help section; step 4 of the Quick start checklist
leads there, see :ref:`start_page`).

1. Start XLTable (``XLTable.exe``) and keep the window open — the extension
   talks to the running server.
2. Open the ``.mcpb`` file with Claude Desktop: double-click it, or — if
   double-clicking does not offer Claude Desktop (the Microsoft Store build
   does not register the file type, and drag & drop does not work there
   either) — use **Settings → Extensions → Advanced settings → Install
   extension…** and pick the file. Then click **Install**.
3. When asked for **XLTable executable (XLTable.exe)**, pick the ``XLTable.exe``
   you run — ``%LOCALAPPDATA%\Programs\XLTable\XLTable.exe`` when installed
   with the setup wizard, or the folder you extracted the zip to. The exact
   path with a **Copy** button is shown on the **Connect Excel & AI** page of
   the admin console — paste it into the file dialog's path bar. (The
   executable was named ``main.exe`` in releases before 2.1.0; after
   upgrading, point the extension to the new name in **Settings → Extensions
   → XLTable → Configure**.)
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

Claude Desktop launches ``XLTable.exe --mcp-bridge`` in the background: a thin
stdio bridge that forwards the MCP session to the running server at
``http://127.0.0.1:<port>/mcp`` (the port comes from ``SERVER_PORT`` in
``settings.json`` next to the executable). The bridge never starts the server
itself: if XLTable is not running, the assistant gets the error
*“XLTable is not running — start XLTable.exe”* — open ``XLTable.exe`` and ask again.

.. note::

   Do not try **Settings → Connectors → Add custom connector** for the local
   server: custom connectors are contacted *from Anthropic's cloud*, not from
   your machine, and require a public HTTPS URL — ``127.0.0.1`` is
   unreachable that way. The ``.mcpb`` extension is the supported path.

On the server edition the same extension connects remotely: fill in the
**Server URL**, **Server user** and **Server password** fields — see
`Server edition`_.

Claude Code
~~~~~~~~~~~

*What you need:* `Claude Code <https://code.claude.com>`_ installed; it works
with a Claude Pro/Max subscription or Claude Console API credits.

Add the server with one command in any terminal::

   claude mcp add --transport http xltable http://127.0.0.1:5000/mcp

(replace ``5000`` with your ``SERVER_PORT`` if you changed it). By default the
server is registered for the current project; add ``--scope user`` to have it
in every project. Verify with ``claude mcp list`` — the server should show as
connected while XLTable is running — and ask about your cubes in a session.

On the server edition, use the server URL and add a Basic authorization
header — the exact command is in `Server edition`_.

Copilot in VS Code
~~~~~~~~~~~~~~~~~~

*What you need:* VS Code 1.102 or newer, signed in to GitHub Copilot — the
free Copilot plan works. On **Copilot Business/Enterprise** an organization
administrator must enable the *“MCP servers in Copilot”* policy first: it is
**off by default**, and until then MCP servers do not work for those users.

For Microsoft-centric organizations this is often the one approved AI channel.
Save this as ``.vscode/mcp.json`` in your workspace (or run the **MCP: Add
Server** command and pick *HTTP*):

.. code-block:: json

   {
     "servers": {
       "xltable": {
         "type": "http",
         "url": "http://127.0.0.1:5000/mcp"
       }
     }
   }

Note the root key: VS Code uses ``servers``, not the ``mcpServers`` most other
clients read. Then open Copilot Chat, switch it to **Agent** mode and trust
the server when asked — the XLTable tools appear under the tools button of
the chat.

On the server edition, point ``url`` at the server and add a ``headers``
block with a Basic authorization header — the exact config is in
`Server edition`_.

Local models: LM Studio and compatible hosts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*What you need:* `LM Studio <https://lmstudio.ai>`_ (free, no account needed)
and a model marked for tool use in its catalog (the hammer icon) — for
example Qwen3 8B or Llama 3.1 8B.

A local model is the **zero-egress** option: the warehouse, the cube layer
*and* the assistant all run on your machine, and nothing — not even tool
results — is sent to any cloud.

1. In the chat's right sidebar open the **Program** tab, click
   **Install → Edit mcp.json** and add:

   .. code-block:: json

      {
        "mcpServers": {
          "xltable": {
            "url": "http://127.0.0.1:5000/mcp"
          }
        }
      }

2. Save the file — LM Studio picks it up immediately. Enable the server in
   the same tab and ask the model about your cubes; LM Studio asks for
   confirmation on each tool call.

Be honest with your expectations: **small local models handle tool calling
noticeably worse than cloud models** — LM Studio's own documentation warns
that models not trained for tool use may emit malformed calls. XLTable's
surface is deliberately friendly to them (few tools, short schemas, clear
error messages), but if answers go astray, try a larger model. Other local
MCP hosts work with the same URL — for example `Jan <https://jan.ai>`_
(Settings → MCP Servers, HTTP transport). Ollama has no official built-in
MCP client support as of this writing.

A local model can also talk to a remote server edition: use the server URL
and add an ``Authorization`` header in the same config — see
`Server edition`_.

Any other MCP client
~~~~~~~~~~~~~~~~~~~~

Any client that supports the **streamable HTTP** transport (Cursor, Windsurf,
Cherry Studio, …) connects with a config equivalent to:

.. code-block:: json

   {
     "mcpServers": {
       "xltable": {
         "type": "http",
         "url": "http://127.0.0.1:5000/mcp"
       }
     }
   }

There is no official config-file standard — this ``mcpServers`` shape is a
convention most clients follow. Known deviations: VS Code uses ``servers``
as the root key (see above), Windsurf expects ``serverUrl`` instead of
``url``, and some clients accept ``"type": "streamable-http"`` as an alias
of ``"type": "http"``. Keep the URL, adjust the keys. Do not add
``headers`` in the free edition — it needs none; the server edition does
require one (see `Server edition`_).

Clients that only speak **stdio** can use the built-in bridge instead:
configure the command ``XLTable.exe --mcp-bridge``. Options: ``--url``
overrides the endpoint address, ``--timeout`` the HTTP timeout in seconds;
``--user`` / ``--password`` add server-edition credentials (see below).

ChatGPT, Gemini and other cloud platforms
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ChatGPT, Gemini and the cloud AI platforms cannot connect to a local MCP
server at all: their connectors run in the vendor's cloud and require a
public HTTPS endpoint, so ``http://127.0.0.1`` is out of reach by design
(ChatGPT rejects plain-HTTP URLs even for localhost). This is not an XLTable
limitation to work around — it is what the **server edition** is for: a
centrally hosted XLTable with per-user authentication that remote clients
can reach. See the **Get the server edition** page in the Help section of
the admin console, or :doc:`install` for the server edition setup.

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
- **Licensing.** MCP availability is a license feature flag; named seats are
  counted per user, whatever interface the user comes through — the MCP
  connection occupies the same seat as the user's Excel connection (one name
  = one seat). See `MCP licensing`_ below.
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
- **stdio clients** — ``XLTable.exe --mcp-bridge --url https://your-server/mcp
  --user <name> --password <password>``; the password can also be supplied
  via the ``XLTABLE_MCP_PASSWORD`` environment variable instead of the
  command line.
- **Claude Code** — the same one-line registration as in `AI clients`_,
  with the server URL and a Basic header::

     claude mcp add --transport http xltable https://your-server/mcp --header "Authorization: Basic <base64 of user:password>"

- **Copilot in VS Code and other JSON-config clients** — the same config
  as in `AI clients`_, with the server URL and a ``headers`` block (the
  root key is ``servers`` in VS Code, ``mcpServers`` elsewhere):

  .. code-block:: json

     {
       "servers": {
         "xltable": {
           "type": "http",
           "url": "https://your-server/mcp",
           "headers": { "Authorization": "Basic <base64 of user:password>" }
         }
       }
     }

- **HTTP clients** (server platforms, MCP Inspector, …) — send a standard
  ``Authorization: Basic`` header with each request to
  ``https://your-server/mcp``. The ``<base64 of user:password>`` value
  above is the standard Basic scheme: ``echo -n 'user:password' | base64``
  on Linux/macOS, or in PowerShell
  ``[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('user:password'))``.
- **Platforms whose authorization field only accepts Bearer tokens**
  (e.g. Yandex AI Studio) — pass the same credentials packed as a token:
  ``Authorization: Bearer <base64 of user:password>``. This is the same
  account checked by the same code — only the header format differs.

MCP licensing
-------------

In the server edition MCP availability is controlled by the boolean ``mcp``
field of the license — a feature flag, not a separate seat count:

- **License without the flag (or with ``false``).** MCP is disabled: every
  request to ``/mcp`` — even with valid credentials — is answered with a
  clear JSON-RPC error *“MCP is not included in your license”*. Excel/XMLA
  access is not affected in any way. If your license predates MCP support,
  contact the vendor for an updated license file and upload it on the
  **License** page of the admin panel.
- **License with ``"mcp": true``.** Every licensed user may use MCP.
- **One seat pool, counted per user.** Named seats are not counted per
  interface: a user occupies one seat whether they connect from Excel, from
  an AI assistant via MCP, or both — one name = one seat. The seat is
  assigned by the first data query, exactly as on the Excel path, and is
  shown and released in the usual **Named user seats** section of the admin
  panel. Connecting an assistant does not consume an extra seat.

The free edition has no license at all, and MCP works there without any of
the above — this section applies to the server edition only.

Logging and cache
-----------------

For an administrator the MCP path behaves exactly like the Excel (XMLA)
path — same debug output, same log artifacts, same caches:

- **Console.** With :confval:`WRITE_LOG` enabled, every ``query_cube`` call
  prints the familiar debug blocks to the server console: ``REQUEST``
  (catalog and cube), ``PIVOT SPEC`` (the pivot specification sent by the
  assistant — the MCP counterpart of the ``MDX`` block), ``CONTEXT``,
  ``SQL`` and ``RESULT``.
- **Log files.** With :confval:`WRITE_LOG` enabled, each MCP request leaves
  the same artifacts in the ``log`` folder as an XMLA request: a
  request/response pair named
  ``<timestamp>_req_<user>_<id>.txt`` / ``..._res_<user>_<id>.txt`` (the
  body is the JSON-RPC message instead of XML) plus the generated SQL and
  the Jinja context dump. A failed SQL query writes an ``error_sql`` dump
  regardless of ``WRITE_LOG``, as on the Excel path. MCP request/response
  dumps are also written when :confval:`DUMP_XMLA` is enabled, so protocol
  dumps cover both paths.
- **Shared SQL cache.** MCP queries go through the same SQL result cache as
  Excel, keyed by the generated SQL text — a slice computed for the
  assistant opens instantly in Excel and vice versa (for example, the query
  that fills an Excel filter drop-down and a ``query_cube`` call for the
  same dimension level share one cache entry).
- **Metadata cache.** Cube definitions are cached with the same
  :confval:`METADATA_CACHE_TTL` policy as on the Excel path; with the
  watched-folder cube source the cache is bypassed, so an edited ``.sql``
  cube is visible to the assistant immediately (hot reload).

Privacy
-------

The connection and the server stay on your machine, and the warehouse
credentials never leave ``settings.json``. Keep in mind, however, that tool
results (cube names, schemas and query results) are sent to the AI assistant
and processed by its cloud model.
