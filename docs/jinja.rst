Jinja
=====

XLTable uses `Jinja <https://jinja.palletsprojects.com/>`_ templating to modify
the generated SQL dynamically, based on what the user selected in Excel, who the
user is and when the request runs.

When working with Big Data, performance and database load are critical: SQL
queries must be both accurate and efficient. Users also often need metrics that
exceed the standard capabilities of OLAP cube measures. Jinja templates let you
control SQL syntax without limitations, adapting the query to the user's selected
fields and filters.

This page covers:

- how Jinja scripts (``--olap_jinja``) work and in what order they run;
- the ``context`` object handed to every template (the three ``cube`` /
  ``request`` / ``sql`` namespaces, plus ``user`` and ``now``);
- how to debug templates and inspect the context.

.. _jinja_scripts:

Jinja scripts
-------------

Jinja scripts allow modifying the generated SQL dynamically.

Use cases:

- performance optimization
- conditional SQL logic
- advanced metrics

A script is defined inside the cube with the ``--olap_jinja`` tag. You can attach
a script to a specific measure group or to the whole cube. A script assigned to a
measure group only affects its own SQL segment; a cube-level script applies to the
overall query.

.. important::

   The template body is **everything after the** ``--olap_jinja`` **tag up to the
   end of its block**, so ``--olap_jinja`` must be the last tag of the section it
   belongs to. In particular, put ``--olap_drillthrough`` (and, in the
   ``--olap_cube`` block, ``--olap_calculated_fields``) *above* ``--olap_jinja``:
   a tag placed below it becomes part of the template and is rendered into the
   SQL of every query, breaking it. The cube syntax checker reports this as an
   error.

Example of a Jinja script modifying SQL:

.. code-block:: jinja

   --olap_jinja
   {{ sql_text | replace("salesly.date_sale", "addYears(salesly.date_sale, 1)") }}

Every template receives two inputs:

- ``sql_text`` — the SQL text at this stage of generation (the string you
  transform, typically with ``replace(...)``);
- ``context`` — everything about the current request (see :ref:`jinja_var`).

Execution order:

1. measure group Jinja
2. cube-level Jinja

Below are common patterns.

Conditional SQL with an ``if/else`` statement:

.. code-block:: jinja

   --olap_jinja
   {% if "invoice_id" in sql_text %}
       {{ sql_text | replace("FROM db.sale_by_days", "FROM db.sale_by_invoices") }}
   {% else %}
       {{ sql_text }}
   {% endif %}

Adding a default ``WHERE`` condition, reusing the source's own WHERE fragment
(see ``context.sql.sources`` in :ref:`jinja_var`):

.. code-block:: jinja

   --olap_jinja
   {% set sql_where = "where sale.year=2025 " %}
   {% if context.sql.sources["sale"].where_text %}
      {% set sql_where = context.sql.sources["sale"].where_text ~ " and sale.year=2025 " %}
   {% endif %}
   {{ sql_text | replace("FROM db.sale sale", "FROM db.sale sale " ~ sql_where) }}

Row-level security by user — restrict rows to the current user when they belong to
the ``managers`` group. Always use ``user.sql`` (escaped and quoted) to avoid SQL
injection:

.. code-block:: jinja

   --olap_jinja
   {% if 'managers' in context.user.groups %}
   {{ sql_text | replace("WHERE", "WHERE managers.login = " ~ context.user.sql ~ " AND ") }}
   {% endif %}

Relative date filtering — limit data to the current year using the ``now`` key:

.. code-block:: jinja

   --olap_jinja
   {{ sql_text | replace("WHERE", "WHERE times.year_str = '" ~ context.now.year ~ "' AND ") }}

Conditional logic on the client request — add an extra column only when a specific
calculated field was requested. Values in ``request.*`` are ``level_name`` values,
so match on the level name (not the localized display name):

.. code-block:: jinja

   --olap_jinja
   {% if 'calc_turnover' in context.request.calculated_fields %}
   {{ sql_text | replace("FROM", ", some_extra_column FROM") }}
   {% endif %}

.. _jinja_var:

The context object
------------------

For each query XLTable builds a ``context`` object and passes it into every Jinja
template. It is organised into three namespaces plus two top-level globals:

.. code-block:: text

   context
   ├── cube        static catalog — the cube definition, read-only
   ├── request     this request — what the user selected in Excel, read-only
   ├── sql         generated SQL artefact for this request
   ├── user        the requesting user
   └── now         server date/time of the request

The split follows two axes: lifecycle (static catalog vs per-request) and language
(cube semantics vs generated SQL). ``cube`` is static semantics, ``request`` is
per-request semantics, ``sql`` is the per-request generated SQL.

Access is dual and equivalent: ``context.request.measures`` and
``context['request']['measures']`` both work. Asking for a key that does not exist
raises a clear error (it is **not** silently swallowed into ``Undefined``), so a
typo in a template surfaces immediately.

.. note::

   Values under ``request`` (and the keys of ``request.filter_values`` and
   ``sql.measures`` / ``sql.dimensions``) are **level names** (``level_name``),
   not the localized display names shown in Excel. Use ``cube.translations`` to
   map a display name to its ``level_name``.

Full example
^^^^^^^^^^^^

.. code-block:: python

   context = {

       # --- BLOCK 1: cube — static catalog, read-only ------------------
       'cube': {
           # every field keyed by level_name
           'fields': {
               'SALES_SUM_QTY': {
                   'type': 'measure',
                   'sql': 'sum(sales.qty)',
                   'translation': 'Sales Quantity',
               },
               'STORE': {
                   'type': 'dimension',
                   'sql': 'stores.name',
                   'translation': 'Store',
                   'hierarchy': 'Geography',
                   'parent': 'REGION',
                   'child': None,
                   'table': 'stores',
               },
               # ...
           },
           # display / localized name -> level_name
           'translations': {'Sales Quantity': 'SALES_SUM_QTY', 'Store': 'STORE'},
           # source tables (alias -> table info, `sql` is the FROM expression)
           'tables': {'sales': {'sql': 'db.Sales sales'}, 'stores': {'sql': 'db.Stores stores'}},
           # join graph between tables
           'tables_joins': {'sales': {'stores': {'sql': 'sales.store_id = stores.id'}}},
       },

       # --- BLOCK 2: request — this request, values are level_name ------
       'request': {
           'measures': ['SALES_SUM_QTY', 'SALES_LY_AMOUNT'],
           'dimensions': ['STORE', 'MODEL'],
           'calculated_fields': ['CALC_TURNOVER'],
           'filters': ['YEAR', 'SUPERVISOR'],
           # each filter -> list of selected member values; '[All]' when everything is selected
           'filter_values': {'YEAR': ['2025 1', '2025 3', '2024'], 'SUPERVISOR': ['Ryan Howard']},
           'axis0': ['STORE', 'MODEL'],     # levels on Excel Axis 0 (typically Rows)
           'axis1': [],                     # levels on Excel Axis 1 (typically Columns)
       },

       # --- BLOCK 3: sql — generated SQL for this request --------------
       'sql': {
           'sql_text': 'SELECT ... FROM ...',      # the whole assembled query
           'sources': {                            # per source (measure group)
               'sales': {'sql_text': 'SELECT ...', 'where_text': 'sales.year = 2025'},
               'stock': {'sql_text': 'SELECT ...', 'where_text': ''},
           },
           # final-SELECT projection, level_name -> details
           'measures':   {'SALES_SUM_QTY': {'column': '...', 'ref': '...', 'expr': '...', 'source': 'sales'}},
           'dimensions': {'STORE': {'column': '...', 'ref': '...', 'expr': '...', 'source': 'stores'}},
       },

       # --- top-level globals ------------------------------------------
       'user': {
           'name': 'jdoe',                  # raw login (NOT SQL-safe)
           'groups': ['managers', 'all'],   # security groups
           'sql': "'jdoe'",                 # escaped + quoted, safe to embed in SQL
       },
       'now': {
           'date': '2026-06-30',
           'datetime': '2026-06-30 14:35:02',
           'year': 2026, 'quarter': 2, 'month': 6, 'day': 30,
       },
   }

cube — the catalog
^^^^^^^^^^^^^^^^^^

Static description of the cube, the same for every request.

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Key
     - Meaning
   * - ``cube.fields``
     - Every cube field keyed by ``level_name``. Each entry has ``type``
       (``measure`` / ``dimension`` / ``calculated_field``), ``sql`` (the field's
       SQL expression) and ``translation`` (display name). Dimensions also carry
       hierarchy info (``hierarchy``, ``parent``, ``child``, ``table``).
   * - ``cube.translations``
     - Maps a display / localized name to its ``level_name`` (reverse of
       ``fields[*].translation``). Use it to resolve an Excel-visible name to the
       key used across ``request`` and ``sql``.
   * - ``cube.tables``
     - Source tables keyed by alias; ``sql`` holds the ``FROM`` expression.
   * - ``cube.tables_joins``
     - Join graph between tables: ``tables_joins[a][b].sql`` is the join condition.

request — the current request
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

What the user selected in Excel for this query. All values are ``level_name``.

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Key
     - Meaning
   * - ``request.measures``
     - Selected measures.
   * - ``request.dimensions``
     - Selected dimension levels (on rows or columns).
   * - ``request.calculated_fields``
     - Selected calculated fields.
   * - ``request.filters``
     - Dimension levels the user filtered on (the ``WHERE`` conditions).
   * - ``request.filter_values``
     - Maps each filtered level to the **list** of selected member values. For a
       multi-part hierarchy member the parts are joined with a space. When the
       user selected everything, the value is ``['[All]']``.
   * - ``request.axis0``
     - Levels placed on Excel Axis 0 (typically Rows).
   * - ``request.axis1``
     - Levels placed on Excel Axis 1 (typically Columns).

.. warning::

   ``request.filter_values`` contains raw, unescaped user input. Do not insert it
   directly into SQL — use it for display / logic only, or escape it yourself.

sql — the generated query
^^^^^^^^^^^^^^^^^^^^^^^^^

The SQL artefact produced for this request. Its per-source parts are filled in as
generation proceeds, so a cube-level template sees the fully assembled query.

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Key
     - Meaning
   * - ``sql.sql_text``
     - The whole assembled query (all measure groups joined together).
   * - ``sql.sources``
     - Per source (measure group), keyed by the source alias. Each entry has
       ``sql_text`` (that source's full SQL) and ``where_text`` (its ``WHERE``
       conditions, ``''`` if none).
   * - ``sql.measures``
     - Final-SELECT projection for measures and calculated fields, keyed by
       ``level_name`` (``column`` / ``ref`` / ``expr`` / ``source``).
   * - ``sql.dimensions``
     - Same, for the selected dimensions.

The source alias equals the alias used after the table name in the source's
``FROM`` clause. For example:

.. code-block:: sql

   --olap_source Sales
   SELECT ...
   FROM db.Sales sales

produces the alias ``sales``, reachable as ``context.sql.sources["sales"]``.

user and now
^^^^^^^^^^^^

``user`` describes who runs the request — useful for row-level security:

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Key
     - Meaning
   * - ``user.name``
     - Raw user login. **Not** escaped — never insert it into SQL directly.
   * - ``user.groups``
     - List of security groups assigned to the user.
   * - ``user.sql``
     - The user name already escaped and wrapped in single quotes, ready to be
       inserted directly into SQL.

.. warning::

   When building SQL conditions from the user name, always use ``user.sql``.
   The raw ``user.name`` is not escaped and inserting it directly may lead to SQL
   injection.

``now`` is the server date/time captured when the request is processed, exposed as
ready-to-use parts: ``date``, ``datetime``, ``year``, ``quarter``, ``month`` and
``day``. Useful for relative date filtering (current year, quarter, today, ...).

Debugging templates
-------------------

Authoring a template is easier when you can see the context and the effect of each
script.

Enabling debug output
^^^^^^^^^^^^^^^^^^^^^^

Set ``WRITE_LOG`` to ``true`` in ``settings.json`` — the change is picked up
automatically within a few seconds, no restart is needed. This
raises the log level to ``DEBUG``, so XLTable logs the full detail of every request
— the incoming MDX, the context, each Jinja script's effect, the generated SQL and
a sample of the result.

Output goes to two places:

- the **log folder** (``...\xltable\log``) as plain text — the durable record;
- the **console** (stdout), where the section banners are colored (and each Jinja
  diff is shown git-style, added lines green / removed lines red) for quick reading.

.. warning::

   ``DEBUG`` logging records SQL and other sensitive request data. Enable
   ``WRITE_LOG`` for troubleshooting, not for normal production operation.

Debug sections
^^^^^^^^^^^^^^

Each request is logged as a sequence of labelled sections, in generation order:

- ``===== REQUEST: <catalog> / <cube> =====`` — start of a request;
- ``===== MDX =====`` — the incoming MDX statement, pretty-printed;
- ``===== CONTEXT =====`` — the render context (and any ``dump()`` you added);
- ``===== JINJA [<scope>] =====`` — for every script that changed the SQL: the
  template source and a before/after unified diff (``<scope>`` is the measure group
  or ``cube``). Passthrough templates that change nothing are skipped;
- ``===== SQL =====`` — the final SQL sent to the database;
- ``===== RESULT (first 20 rows) =====`` — a sample of the returned rows.

Example log excerpt for a cube-level script that shifts last year's dates:

.. code-block:: text

   2026-06-30 14:35:02 DEBUG ===== REQUEST: olap / myOLAPcube =====
   2026-06-30 14:35:02 DEBUG ===== MDX =====
   SELECT
       NON EMPTY Hierarchize(...) ON COLUMNS,
       NON EMPTY Hierarchize(...) ON ROWS
   FROM [myOLAPcube]
   WHERE ([Dates].[Year].&[2025])

   2026-06-30 14:35:02 DEBUG ===== JINJA [source: Sales last year] =====
   --- template ---
   {{ sql_text | replace("salesly.date_sale", "addYears(salesly.date_sale, 1)") }}
   --- diff ---
   --- before
   +++ after
   @@ -8,1 +8,1 @@
   -LEFT JOIN calendar times ON salesly.date_sale = times.day_str
   +LEFT JOIN calendar times ON addYears(salesly.date_sale, 1) = times.day_str

   2026-06-30 14:35:02 DEBUG ===== SQL =====
   SELECT ... FROM ( ... ) sales FULL JOIN ( ... ) salesly ...

   2026-06-30 14:35:03 DEBUG ===== RESULT (first 20 rows) =====
   Store | Model | Sales Quantity | Sales last year Amount
   ...

If a script does not appear in the log, it changed nothing — check that its
``replace(...)`` target actually occurs in ``sql_text``.

Dump the context from a template
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Every template also gets a callable ``dump()`` that logs a view of the current
``context`` (under a ``===== CONTEXT dump(...) =====`` banner) and emits nothing
into the SQL, so you can leave it in place while iterating:

.. code-block:: jinja

   --olap_jinja
   {{ dump() }}                        {# whole context as a key tree #}
   {{ dump('request') }}               {# only the request branch #}
   {{ dump('cube.fields', depth=1) }}  {# one branch, limited depth #}
   {{ dump(mode='sql') }}             {# just the generated SQL fragments #}
   {{ dump(mode='full') }}            {# full dump as JSON #}
   {{ sql_text }}

``dump(root=None, depth=None, mode='tree')``:

- ``mode='tree'`` (default) — key tree with types and sizes, **no values**;
  ``root`` limits the dump to one branch (e.g. ``'request'`` or ``'cube.fields'``)
  and ``depth`` limits how deep it expands.
- ``mode='full'`` — the full context as valid JSON (UTF-8 preserved).
- ``mode='sql'`` — only the SQL fields (``sql.sql_text`` and
  ``sql.sources[*].sql_text``), lightly formatted.

``dump()`` also needs ``WRITE_LOG`` enabled to reach the log.

For general cube validation (``definition_check_on``) and inspecting the final SQL,
see :ref:`validation_debugging`.
