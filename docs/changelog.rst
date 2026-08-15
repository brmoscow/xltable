Version History
===============

Stay up to date with the latest releases by following us on
`Telegram <https://t.me/xltable_news>`_ or `X <https://x.com/XLTable>`_.

------------------------------------------------------------

Version 2.0.20 — upcoming
--------------------------

- **The admin console got a visual overhaul** — a calm, dense console look
  in both editions: full-width layout, compact data tables instead of
  cards, a monospaced face (IBM Plex Mono, embedded — no external
  requests) for all data values, and a live status line in the header
  written as a SQL comment — cube count, warehouse and host, serving
  address, edition and version at a glance. Every page header now carries
  a **Docs ↗** link straight to the matching section of this
  documentation, and the footer links the product site. Animations are
  reduced to a single one (the Quick start step checkmark) and the
  ``prefers-reduced-motion`` system setting is respected. Smaller touches:
  the cube list refreshes itself while the page is open (no Reload button),
  a parse error on the Cubes page is followed by a plain-words hint on what
  to do, **Save connection** checks the connection first (a failing check
  asks for a second press instead of blocking), and the Quick start
  checklist keeps only the current step expanded — the steps ahead collapse
  to their titles until it is their turn.

- **Named user seats moved to their own Seats page** — the seat registry
  (who occupies the licensed seats, with a per-seat Release button) now
  lives on the **Seats** page of the Administration section; the
  **License** page keeps the license details, the server ID and the upload
  form. The page exists in both editions — in the free desktop edition it
  explains that seats come with a server edition license. See
  :ref:`admin_panel`.

- **The desktop executable is now ``XLTable.exe``** — the Windows desktop
  binary was renamed from the anonymous ``main.exe`` and carries proper
  Windows file properties (product name, company, version, description
  "XLTable OLAP Server") in file Properties and security dialogs. If the old
  path is written anywhere — a logon shortcut or scheduled task, a batch
  file, or the Claude Desktop extension (the ``.mcpb`` file picker) — update
  it to ``XLTable.exe`` after upgrading. Server installations (Ubuntu,
  Windows Server/IIS) are not affected.

- **Server distributions are built server-only** — the Linux and Windows
  Server (IIS) distributions no longer start with ``"EDITION": "free"``:
  they refuse with a clear message pointing to the desktop distribution.
  The free edition's local-only guarantee relies on the server binding the
  socket to ``127.0.0.1`` itself, which gunicorn and IIS deployments do not
  go through — the free edition ships as the Windows desktop distribution
  only. Existing server installations are not affected (they do not set
  ``EDITION``). See :confval:`EDITION`.

- **Smoother first and repeated launch (free edition)** — a set of small
  quality-of-life fixes for the desktop server:

  - the cubes folder is created automatically at startup when missing
    (previously the server only logged a warning and served an empty list;
    in the server edition the creation of a previously missing folder is
    logged as a warning — a typo in ``CUBES_FOLDER`` no longer hides
    silently behind an empty cube list);
  - starting ``XLTable.exe`` when the server is already running no longer
    fails with a port error: the second window opens the admin console in
    your browser and quietly exits — instantly, before any heavy startup
    work; a corporate HTTP proxy no longer confuses the detection
    (the identification ping bypasses proxies for ``127.0.0.1``);
  - if the port is taken by another program (5000 is a popular dev port),
    the console prints a clear message with the port number and the path to
    ``settings.json`` where to change ``SERVER_PORT`` — instead of a
    traceback; the message also covers the case of an older XLTable
    (``main.exe``) still holding the port;
  - the server now anchors itself to its own folder at startup, so a
    shortcut without a "Start in" folder, a Task Scheduler task or a batch
    file started from another directory all find ``settings.json``, logs
    and cubes correctly;
  - if the installation folder is not writable (for example, the zip was
    unpacked into ``Program Files`` without administrator rights), or
    ``settings.json`` is missing or damaged, the server explains the
    problem in plain words and waits for Enter — instead of crashing
    silently;
  - the ``.mcpb`` Desktop Extension for Claude Desktop now ships inside the
    distribution archive next to ``XLTable.exe``, so the download button on
    the Quick start page works out of the box.

- **Step 4 of Quick start offers a choice of AI clients (free edition)** —
  the *Connect an AI agent* step of the onboarding checklist is no longer a
  single ``.mcpb`` download button: pick the client you can use at work —
  **Claude Desktop** (recommended, one-click ``.mcpb`` as before),
  **Copilot in VS Code**, **Claude Code**, a **local model** in LM Studio
  (zero egress — with a local model nothing is sent to any cloud), or any
  other MCP client with a universal JSON config. Every option comes with
  2–4 steps and a ready-to-copy config with the real server port already
  substituted; the step still turns green on the first agent request,
  whichever client it comes from. The documentation gained a matching
  :ref:`AI clients <mcp_clients>` section, including honest notes on what
  each client requires and why cloud platforms (ChatGPT, Gemini) cannot
  reach a local MCP server — that scenario is served by the server edition.

- **Quick start page and automatic first launch (free edition)** — the free
  desktop edition now guides the first run end to end: start ``XLTable.exe``
  with an empty cubes folder from an interactive console, and the browser
  opens on the new **Quick start** page of the admin console — an onboarding
  checklist of four steps (connect the warehouse → create the first cube →
  connect Excel → connect an AI agent). The status of every step is derived
  from real system facts, nothing is ticked manually: the warehouse step
  turns green after the first successful connection, the cube step when a
  valid ``.sql`` appears in the cubes folder, the Excel and AI steps on the
  first real request from Excel or an agent — live, while the page is open.
  The Excel step shows the exact connection breadcrumb (including the
  MSOLAP provider hint), the AI step offers to download ``xltable.mcpb``
  shipped next to the exe. Quick start is the default landing page until the
  checklist is complete (the pages involved in the steps link back to it);
  after that the console opens on **Cubes** and Quick start stays in the
  menu as a reference. A non-interactive start (service, scheduler) never
  opens a browser — the console always prints the admin address, the Excel
  breadcrumb and the Quick start link instead. See :ref:`start_page`.

- **Unified admin console navigation** — the admin console switched from a
  tab strip to a left-side menu of sections (**Quick start** — a standalone
  item, free desktop edition only; **Connection**: Warehouse connection;
  **Cubes**: Cubes, Create cube — free desktop edition only;
  **Administration**: Server status, License, Cache; **Help**: Resources,
  plus **Get the server edition** in the free desktop edition — what the
  server edition adds and how to get it). The menu skeleton is the same in
  both editions, so an analyst who uses the free desktop at home and the
  server edition at work always finds things in the same place; the
  editions differ only in which pages exist and in their mode (the
  **Cubes** section is absent on the server edition, the Warehouse
  connection page is read-only there). The open page is addressable via
  the URL hash (``/admin#cache``) and survives a browser reload. See
  :ref:`admin_panel`.

- **Cubes and Create cube pages in the admin console (free edition)** — the
  admin console of the free desktop edition became the analyst's main
  workspace. The new **Cubes** page lists the cubes folder live: cube name,
  description, file path, modification time and the parse status of every
  ``.sql`` file — a broken cube now shows the exact parser error in the
  browser instead of surfacing only as a failure in Excel. The new **Create
  cube** page is a web wizard over the same generation engine as
  ``XLTable.exe autogen`` and the MCP ``autogen_cube`` tool: filter the
  warehouse tables by
  a substring, pick one, review the proposed classification of every column
  (role and reason), name the cube and save it into the cubes folder — the
  server picks it up instantly. If a cube file with that name already exists,
  the wizard asks — overwrite, save under another name or cancel; nothing is
  overwritten silently. Service pages (**Server status**, **License**,
  **Cache**) live in the **Administration** section of the menu, so
  day-to-day work is not mixed with service operations. See
  :ref:`cube_autogen` and :ref:`admin_panel`.

- **Connection setup in the admin console** — the web admin console got a
  **Connection** page. In the free desktop edition it is a full connection
  editor: pick the warehouse type, fill in the form, press *Test connection*
  and save — ``settings.json`` never has to be edited by hand, the saved
  connection is applied without a restart (the query cache is cleared, so
  metadata of the previous warehouse does not linger). Saved passwords are
  write-only: they are never sent to the browser, and an empty password
  field keeps the stored value. *Test connection* checks the values entered
  in the form and answers with a clear message (host unreachable / wrong
  credentials / database not found / "found N tables") instead of a stack
  trace. On the first start of the free edition, while the connection is
  empty, the server console prints a direct link to the form. In the server
  edition the tab is read-only diagnostics behind the usual admin
  authentication: the current connection (secrets masked) plus *Test
  connection* against the saved configuration; editing stays in
  ``settings.json`` on the server. See :doc:`connection`.

------------------------------------------------------------

Version 2.0.19 — 2026-08-05
----------------------------

- **Fixed: unrelated errors no longer reported as cube syntax problems** —
  when a cube definition carried only warnings (e.g. ``--olap_drillthrough``
  referencing compound-aggregate measures or unknown fields), any unexpected
  processing error during a query was masked by the *"There are syntax
  problems in the cube definition"* message listing those warnings — looking
  like a random cube error that went away in a new workbook. Now the syntax
  problem list is shown only when the definition actually contains errors;
  otherwise the real error message is returned to Excel, and it is always
  written to the server log with a full traceback for diagnostics.

- **MCP server for AI assistants** — XLTable now speaks the Model Context
  Protocol: an AI assistant can list cubes, inspect dimensions and measures
  and run aggregated pivot queries through the same live instance, cubes and
  cache that serve Excel. Claude Desktop connects via a one-click Desktop
  Extension package (``xltable-<version>.mcpb``) that launches the built-in
  stdio bridge ``main.exe --mcp-bridge`` — no Node.js, no manual JSON
  editing; other MCP clients can use the bridge or the Streamable HTTP
  endpoint ``/mcp`` directly. The assistant works only through cubes — raw
  SQL access to the warehouse is never exposed. Available in both editions:
  the free desktop edition connects anonymously on the local machine; in
  the server edition ``/mcp`` requires Basic authentication with a user
  from ``USERS`` (same accounts and session cache as the Excel endpoint)
  and row-level security applies exactly as in Excel. MCP availability is
  a license feature flag (``"mcp": true``): a license without the flag
  disables MCP with a clear error while Excel keeps working; named seats
  stay counted per user regardless of the interface, so the MCP connection
  occupies the same seat as the user's Excel connection (one name = one
  seat). Cubes can come from the local folder or from the
  ``olap_definition`` catalog — with the database source the tools accept
  an optional ``database`` argument and a ``list_databases`` tool appears.
  Platforms whose authorization field only accepts Bearer tokens (e.g.
  Yandex AI Studio) can pass the same credentials as
  ``Bearer <base64 of user:password>``. For administrators the MCP path is
  as observable as the Excel path: with ``WRITE_LOG`` enabled each MCP
  request leaves request/response, SQL and context dumps in ``log`` and
  prints the familiar ``REQUEST``/``CONTEXT``/``SQL``/``RESULT`` blocks to
  the console; MCP queries share the SQL result cache and the metadata
  cache policy with Excel — a slice computed by the assistant opens
  instantly in Excel and vice versa. See :doc:`mcp`.

- **Cubes can be created from the chat** — with the folder cube source
  (``CUBE_SOURCE=folder``) the MCP server offers two more tools:
  ``list_warehouse_tables`` lists the tables and views of the connected
  warehouse (names only, filtered by a substring — the chat counterpart of
  the autogen wizard's table filter), and ``autogen_cube`` generates a cube
  from a single table with the same engine as ``main.exe autogen`` — the
  wizard, the direct call and the assistant are three fronts over one
  generator. The new ``.sql`` file lands in the cube folder and is live
  immediately: *“I have a table sales — make a cube and show me sales by
  month”* works in one chat, no console needed. An existing cube file is
  never overwritten silently — without an explicit ``overwrite=true`` the
  call fails and nothing changes (and MCP clients ask for confirmation
  before running the tool, since it writes). Open Pivot Tables keep the old
  cube metadata until refreshed — the assistant reminds the user to press
  **Refresh**. See :ref:`mcp_create`.

- **The assistant works alongside Excel** — because Excel and MCP share one
  live engine, the assistant sees what the user is looking at: the new
  ``get_pivot_context`` tool returns the layout of the user's last Pivot
  Table query (cube, row/column levels, measures, filters) together with a
  ready-made ``query_cube`` specification that reproduces the same slice —
  for prompts like *“explain this number”* or *“continue my analysis”*.
  The context is per user, survives closing the workbook, and is withheld
  with an explicit note if the cube or its fields have since become
  unavailable to the user (edited cube, changed security roles). Pressing
  **Refresh** in Excel now also marks the shared SQL cache as stale for the
  assistant, so after a refresh ``query_cube`` re-reads the warehouse
  instead of answering from a pre-refresh cache entry. See
  :ref:`mcp_pivot_context`.

- **Semantics for AI agents in the cube definition** — four optional tags let
  the cube author describe the model to an assistant instead of leaving it to
  guess from a bare schema: :tag:`olap_description` (what the cube is, its
  grain, the questions it answers — shown briefly by ``list_cubes`` and in
  full by ``describe_cube``), :tag:`olap_ai_instructions` (free-form
  instructions returned as written), and the field-level :tag:`description`
  (business meaning, units, caveats) and :tag:`synonyms` (alternative names
  separated by ``;``, complementing :tag:`translation`). On top of that,
  ``describe_cube`` returns **sample values of low-cardinality dimension
  levels straight from the engine** — the same query that fills a filter
  drop-down in Excel, so the values are never stale and always respect the
  user's row-level security. The tags are metadata for assistants only: Excel
  and the XMLA path ignore them, generated SQL does not change, and cube files
  stay portable between servers. Autogen now leaves an empty
  :tag:`olap_description` with a hint at the end of every generated cube.
  Cubes without the new tags work exactly as before. See
  :ref:`cube_ai_semantics` and :ref:`mcp_semantics`.

- **Free desktop edition (EDITION=free)** — a new ``"EDITION": "free"`` key
  in ``settings.json`` switches the server into the free single-user
  desktop mode: the endpoint listens on ``127.0.0.1`` only, Excel connects
  to ``http://127.0.0.1:<port>`` anonymously (no password), no license
  file is required, and cube definitions are always read from the local
  cube folder. Requests coming through a forwarded port (non-local
  ``Host`` / ``Origin``) are rejected — the free edition works only on the
  machine it runs on. Without the key the server behaves exactly as
  before. See :confval:`EDITION`.

- **Local cube definitions (CUBE_SOURCE=folder)** — the server can now read
  cube definitions from local ``.sql`` files instead of the
  ``olap_definition`` table: set ``"CUBE_SOURCE": "folder"`` in
  ``settings.json`` and put one file per cube into the folder set by
  ``CUBES_FOLDER`` (default ``cubes/`` — the same folder autogen writes to,
  so a generated cube is live immediately). The file content is the same
  definition text as in ``olap_definition`` — files move between the two
  modes unchanged, including row-level security and syntax checking. Files
  are re-read on every request: saving a file in any SQL editor makes the
  change visible in Excel right away. Excel sees a single catalog named
  ``Cubes``; cube SQL still runs through the configured warehouse
  connection. Without the new key the server behaves exactly as before.
  See :confval:`CUBE_SOURCE` and :ref:`cube_definition_storage`.

- **Fixed: number formats with several measures in one Pivot Table** — when
  two or more measures were placed in the **Values** area, cells lost the
  number formats set by the :tag:`format` tag and Excel displayed plain
  ``General`` numbers; with a single measure the format applied correctly.
  Formats now apply regardless of how many measures the report contains and
  of where the **Values** header is placed (columns or rows).

------------------------------------------------------------

Version 2.0.18 — 2026-07-29
----------------------------

- **Hierarchy filtering without parent levels (--filter_no_parents)** — by
  default, selecting a member deep inside a multi-level hierarchy filters the
  whole path: picking a quarter with the year expanded produces
  ``year = '2024' AND quarter = 'Q2'`` in the generated SQL. The new
  ``--filter_no_parents`` tag, placed on any level of a hierarchy in the cube
  definition, switches that hierarchy to filtering by the selected member
  alone (``quarter = 'Q2'``) — useful when a child member moves between
  parents over time (a product changes category, a store changes region) and
  filtering by the parent path would cut off its history. Enable it only on
  hierarchies where member values of every level are globally unique. Applies
  consistently everywhere a member filter is used: the pivot itself, report
  filters and slicers, Keep Only / Hide Selected Items, drill through and file
  export. See :doc:`reference`.

- **Export of large results to a CSV file** — when a Pivot Table layout is too
  detailed for the pivot size cap (``MAX_CELLS``), the full result can now be
  exported to a file instead: right-click → **Additional Actions** → **Export
  full table to CSV**. The browser opens a status page and the download starts
  automatically when the file is ready; the export is built in the background
  by streaming the query result straight to disk, so even multi-gigabyte
  results do not load the server memory. The file contains exactly what the
  pivot is configured to show — same fields, filters and expansions, with cube
  captions as column headers — but complete and without subtotal rows, so it
  can be safely aggregated further. Results larger than an Excel sheet
  (1,048,576 rows) are delivered as a ZIP archive. Repeated exports of an
  unchanged layout reuse the already-built file (kept 24 hours by default);
  pressing **Refresh** and exporting again rebuilds it with fresh data.
  Row-level security applies to the file the same way as to the pivot.
  Currently supported for ClickHouse. Enabled by the new ``EXPORT`` section in
  ``settings.json`` — without it, server behavior is exactly as before. See
  :ref:`excel_export` and :ref:`export_settings`.
- **Preview mode for heavy layouts (Data Output field)** — every cube of an
  export-enabled server gets a service **Data Output** field: putting it into
  the **Filters** area and selecting ``Preview: first 1000 rows`` shows the
  first rows of the detailed result while keeping the pivot fully editable —
  a way to shape a heavy layout on real data before exporting it. The preview
  returns plain data rows without totals — a faithful sample of the future
  file. See :ref:`excel_export`.
- **Cube autogeneration (autogen)** — a first-draft cube definition can be
  generated from a single table: ``main.exe autogen`` starts a console wizard
  (pick a database table, review how every column was classified and why),
  ``main.exe autogen <schema.table>`` generates without questions. Date
  columns become a ready Year→Quarter→Month→Day hierarchy, key-like and text
  columns become dimensions, numeric columns become SUM measures (price/rate
  columns — AVG), near-unique text is excluded, ``count(*)`` is always added.
  The result is a complete commented ``.sql`` definition file to paste into
  ``olap_definition`` and refine by hand. See :ref:`cube_autogen`.
- **Admin panel: export management** — the **Cache** tab shows current export
  jobs, files and their total size, with a **Clear Export Jobs and Files**
  button that also removes orphaned files and compacts the job registry. See
  :ref:`admin_panel`.

Version 2.0.17 — 2026-07-18
----------------------------

- **Named user licensing enforced with a seat registry** — the licensed user limit now counts *named* users instead of concurrent sessions. A licensed seat is assigned to a user on their first request and survives sign-outs, cache clears and server restarts; it is freed automatically after a period of inactivity defined by the license (30 days by default) or manually by an administrator. The **License** tab of the admin panel shows who occupies the seats, when each user was first and last seen, and provides a per-seat **Release** button. When all seats are taken, a new user gets a clear "Named user limit reached" message in Excel; existing users are unaffected. In multi-server deployments (``CACHE_BACKEND: redis``) the seat registry is shared by the whole cluster. See :ref:`admin_panel`.
- **Cache clearing API for ETL pipelines (POST /api/cache/clear)** — an external system can now clear the XLTable cache right after updating the warehouse data, so users get fresh numbers immediately instead of waiting out the cache TTL. Authorization by a dedicated Bearer token (new ``API_TOKENS`` setting — no admin password in pipeline scripts) or by admin credentials. The ``scope`` parameter selects what is cleared: ``sql`` (default — shared query results only, sessions and cube metadata untouched), ``metadata`` (plus cube definitions, users stay signed in) or ``all``. With ``CACHE_BACKEND: redis`` one call clears the whole cluster. See :ref:`cache_api`.
- **SQL results are cached once and shared between users** — previously query results were cached per user session, so a department opening the same dashboard sent the same SQL to the database once per user; now an identical SQL query is executed once per ``SQL_CACHE_TTL`` (600 seconds by default) and every other user gets the result from the cache within milliseconds. Excel **Refresh** keeps its meaning: the user who presses it bypasses the cached entries obtained before the refresh and — once the data is re-read — updates them for everyone; other users keep using the cache. Row-level security is unaffected: per-user access filters are part of the generated SQL text, so users with different permissions never share results. With ``CACHE_BACKEND: redis`` the cache is shared across all servers of the cluster. Cache size is capped (``SQL_CACHE_MAX_MB``, LRU eviction; ``SQL_CACHE_MAX_RESULT_MB`` per result), the feature can be turned off with ``SQL_CACHE_ENABLED: false``, and the admin panel shows entry count, size and hit rate. See :ref:`refreshing_data`.
- **Query marker in database logs for all connectors** — every SQL query now starts with a ``/* user:<name>, app:xltable */`` comment (previously only ClickHouse tagged queries, via ``log_comment``), so database administrators can find XLTable queries — and see which user requested the data — in the query history of any supported database: ClickHouse ``system.query_log``, Greenplum ``pg_stat_activity``/server log, StarRocks audit log, Trino ``system.runtime.queries``, Snowflake ``QUERY_HISTORY``, Databricks ``system.query.history``, BigQuery ``INFORMATION_SCHEMA.JOBS``. Ready-to-use history queries per database are in the FAQ. The ClickHouse ``log_comment`` marker is kept unchanged.
- **Query timeout for all connectors (query_timeout)** — the ``query_timeout`` parameter in ``CREDENTIAL_DB`` (maximum execution time of a single database query, in seconds; 300 by default) is now honored by every connection type, not only ClickHouse. Where the database supports it, the query is cancelled server-side (Snowflake ``STATEMENT_TIMEOUT_IN_SECONDS``, Databricks ``STATEMENT_TIMEOUT``, Greenplum ``statement_timeout``, Trino ``query_max_execution_time``, StarRocks ``query_timeout``, BigQuery job timeout); for embedded DuckDB the query is interrupted by XLTable itself. See :ref:`database_connections`.
- **Cancelling a running query works in all connectors** — when a refresh is interrupted in Excel (pressing ``Esc``), the server now cancels the query in the database instead of letting it run to completion. Previously only the ClickHouse connector supported this; now the query is cancelled server-side in Greenplum (``pg_cancel_backend``), StarRocks (``KILL QUERY``), Trino (``system.runtime.kill_query``), Snowflake (``SYSTEM$CANCEL_QUERY``) and BigQuery (job cancellation) — for these databases Cancel works across worker processes and servers, same as for ClickHouse. Databricks and embedded DuckDB have no server-side kill command, so the query is interrupted in-process: cancellation applies when the Cancel request reaches the same server process that runs the query.
- **Admin panel: SQL cache statistics reset** — the **Cache** tab got a **Reset stats** button that starts the hit/miss counters of the shared SQL result cache from zero without touching the cached entries. The counters deliberately survive restarts and cache clearing, so the button is the way to measure the cache hit rate over a chosen period. See :ref:`admin_panel`.
- **Snowflake key-pair authentication** — the Snowflake connector now supports the authentication method Snowflake recommends for service accounts after deprecating single-factor password sign-ins: specify ``private_key_path`` (and ``private_key_passphrase`` for an encrypted key) in ``CREDENTIAL_DB`` to authenticate with an RSA key pair. A programmatic access token (PAT) can still be passed in the ``password`` field, and existing password-based configurations keep working unchanged. See :ref:`database_connections`.

Version 2.0.16 — 2026-07-10
----------------------------

- **DuckDB Connector** — added support for DuckDB as a data source. DuckDB is embedded: the whole database is a single file next to XLTable — no database server to install, which makes it the fastest way to try XLTable or to serve small and medium datasets. Cubes can also be built directly on top of Parquet/CSV files via ``read_parquet()`` / ``read_csv()`` in the cube definition. See :doc:`duckdb_sample`.
- **Multi-server deployments (CACHE_BACKEND: redis)** — several XLTable servers can now share one cache through Redis and work behind a load balancer (e.g. nginx) with no sticky sessions: a session opened through one server is valid on all of them, a running query can be cancelled through any server, the licensed user limit is counted across the whole cluster, and cache management in the admin panel of any server applies to all. The default single-machine cache is unchanged. See :ref:`install_multi_server`.

Version 2.0.15 — 2026-07-04
----------------------------

- **Parallel worker processes on Linux (concurrency)** — the Ubuntu installer now starts several server processes behind nginx load balancing (one per CPU core, up to 4 by default; configurable with ``XLTABLE_INSTANCES``). Heavy reports from many concurrent users are built in parallel instead of queueing on a single CPU core; all processes share one cache and one ``settings.json``. Existing installations pick this up by re-running ``install_xltable.sh``.
- **Worker threads and port settings (SERVER_THREADS, SERVER_PORT)** — the number of worker threads of one server process is now configurable (default raised from 8 to 16, so more database queries stay in flight simultaneously), as is the listening port (``SERVER_PORT``, or the ``OLAP_PORT`` environment variable used by the multi-process setup).
- **Result cache size cap (RESULT_CACHE_MAX_MB)** — query results larger than the configured size (16 MB by default) are no longer stored in the shared result cache: under concurrent load, writing huge cached responses made all worker processes queue on the cache database; such results are cheaper to rebuild. Also sped up the assembly of very large XMLA responses.
- **Collapse / Expand Entire Field** — the Pivot Table context-menu commands **Expand/Collapse → Collapse Entire Field** and **Expand Entire Field** are now supported in all combinations, verified against SSAS traces, both for separate nested fields and for levels of a multi-level hierarchy: collapsing a whole nested field, expanding an entire field or hierarchy level (all items at once), expanding a single item of a collapsed field back (only that item shows the nested field) and collapsing single items of an expanded field. A collapsed field is not queried at all — its table is not scanned or joined until the field is expanded again.
- **Keep Only / Hide Selected Items** — the Pivot Table context-menu commands **Filter → Keep Only Selected Items** and **Hide Selected Items** are now supported, including items of multi-level hierarchies. Excel's service query for the hierarchy position of the selected items (``__XlItemPath`` / ``__XlSiblingCount`` / ``__XlChildCount``) is answered the same way as by SSAS.
- **Large dimension filters** — Keep Only / Hide Selected Items works on dimensions with tens of thousands of members, verified against an SSAS trace with 20,000 items: the full member list is returned to Excel (capped by the new ``MAX_FILTER_MEMBERS`` setting, 100,000 by default), member filters are generated as compact SQL ``IN (...)`` lists instead of ``OR`` chains, and the ClickHouse connector automatically raises ``max_query_size`` for oversized queries (the default 256 KB parser limit rejected large filter lists).
- **Result limit in cells (MAX_CELLS)** — the result size limit is now measured in cells of the pivoted table (row combinations × column combinations × measures) instead of rows, with a default of 100,000 — the same way SSAS limits oversized results. The legacy ``MAX_ROWS`` setting is still accepted. A separate, clear message is returned when the columns area exceeds the Excel sheet limit of 16,384 columns.
- **XMLA diagnostics (DUMP_XMLA)** — new setting that dumps every raw XMLA request and response to the ``log`` folder, for diagnosing Excel/XMLA protocol issues.
- **Automatic log cleanup (LOG_RETENTION_DAYS)** — log files older than the configured number of days (14 by default) are now removed automatically.
- **Overload protection (OVERLOAD_GUARD)** — when the server host runs out of memory, CPU or disk space (configurable thresholds), data queries are rejected with a clear "Server is overloaded" message in Excel instead of being forwarded to the database. Metadata requests still pass, so cube connections stay alive.
- **Metadata cache TTL (METADATA_CACHE_TTL)** — cached cube definitions, schema lists and query results now expire after a configurable period (600 seconds by default), so an edited cube is picked up automatically without clearing the cache.
- **Hot reload of settings.json** — configuration changes are picked up automatically within a few seconds of saving the file, without a service restart. A file with a JSON syntax error is ignored (the previous configuration keeps working) and logged.
- **Cache follows settings.json** — database credentials are no longer stored in the cache (they are read from the live configuration on every request), and the cache is cleared automatically whenever the configuration content changes — on hot reload or on service start. A service started with an incorrect configuration no longer requires a manual cache clear after the fix.
- **Authorization cache timeout (AUTH_CACHE_TIMEOUT)** — cached authorizations of local users now expire the same way as Active Directory ones; the new setting applies to both (``LDAP_CACHE_TIMEOUT`` is kept as a legacy fallback).
- **Admin panel: cache management** — new per-user cache overview with last-activity times, a **Sign out** button for a single user, and a **Clear Metadata Cache** action that applies cube changes without signing users out.

Version 2.0.14 — 2026-07-01
----------------------------

- **Drillthrough** — double-clicking a Pivot Table cell now returns the underlying detail rows. Detail columns are configured per measure group with the new ``olap_drillthrough`` tag in the cube definition.
- **New Jinja context** — expanded the Jinja rendering context available in cube definitions with additional variables for building dynamic query logic.
- **Debug console** — new debug console for inspecting rendered SQL, Jinja context and query execution, making cube development and troubleshooting easier.

Version 2.0.13 — 2026-06-18
----------------------------

- **Extended Jinja context** — Jinja templates now receive additional context variables (``user``, ``now``, ``request`` and per-source SQL fragments) for row-level security and dynamic query logic.
- **SQL and XML escaping** — hardened escaping of user names, member values and identifiers across all connectors to prevent SQL injection and malformed XMLA responses.
- **Many-to-many fix** — corrected SQL generation for ``many-to-many`` relationships.
- **Connector fixes** — multiple fixes across database connectors, including ``ILIKE`` support for BigQuery.
- **MCP connector (in development)** — early support for an MCP connector, currently under active development.

Version 2.0.12 — 2026-05-22
----------------------------

- **Greenplum Connector** — added support for Greenplum as a data source.
- **HTTP gzip compression** — server HTTP responses now support gzip compression, reducing the amount of data transferred.
- **Faster XMLA response building** — significantly improved performance when generating XMLA responses with a large number of rows.

Version 2.0.11 — 2026-04-01
----------------------------

- **Databricks Connector** — added support for Databricks as a data source.
- **OLAP cube syntax validation** — new function for validating cube definition syntax before loading.
- **Windows 10 and 11 support** — added the ability to run on Windows 10 and 11 operating systems.

Version 2.0.10 — 2026-03-19
----------------------------

- **StarRocks Connector** — added support for StarRocks as a data source.
- **Admin Panel** — new web-based interface for managing server configuration.
- **Part-source parameter** — added ``part-source`` attribute for defining tag relationships in cube configuration.
- **Jinja context variables** — cube definitions now support Jinja templating with context variables.
- **Improved logging** — enhanced diagnostic output across all supported connectors for easier troubleshooting.
