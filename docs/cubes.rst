OLAP cube definition
====================

Concept
-------

An OLAP cube in XLTable consists of measure groups and dimensions.

- Measure groups contain measures (for example, sum, count, average)
- Dimensions contain attributes (for example, regions, stores, time)

To make data available in Excel Pivot Tables, you must define the OLAP cube structure:

- which measures will be included
- which dimensions will be included
- which attributes each dimension contains
- which tables store data for measures and dimensions

If you have experience designing OLAP cubes in Microsoft SQL Server Analysis Services,
the overall logic will feel familiar.

In Analysis Services, cube structure is designed in a graphical environment and then deployed.
In XLTable, cube structure is defined using SQL scripts.

Anatomy of a cube definition
----------------------------

Before diving into individual tags, keep two ideas in mind.

**Every block is a runnable SELECT.** A cube definition is a sequence of ordinary
SQL ``SELECT`` statements annotated with tags inside comments. Any single block can
be copied into a database client and executed as-is — it returns real rows. This is
the key mental model: you are writing normal SQL first, and the tags only tell
XLTable how to assemble those queries into an OLAP cube.

**A definition follows a fixed top-to-bottom order.** The blocks always appear in
this sequence:

.. code-block:: text

   WITH <cte> AS (...)            ← 1. CTEs (optional, shared by the whole cube)
   --olap_cube                    ← 2. cube-level block:
   --olap_calculated_fields ...        calculated fields and
   --olap_jinja ...                    cube-level Jinja (optional)
   --olap_source <MeasureGroup>   ← 3. measure groups (one or more)
   ...
   --olap_source <Dimension>      ← 4. dimensions (one or more)
   ...
   --olap_user_role               ← 5. user roles / access rules (optional)
   ...
   --olap_description             ← 6. semantics for AI agents (optional)
   --olap_ai_instructions              — always last, see below
   ...

By convention blocks are separated by a blank line (the parser splits the
text by the ``--olap_*`` markers themselves, so the blank line is a style
recommendation, not a syntax rule). One real positional rule: at least one
line — a comment or a CTE — must precede ``--olap_cube``; a definition that
starts with the tag on its very first line silently loses the cube-level
block. Refer back to this map as you read the sections below.

.. _cube_definition_storage:

Cube definition storage
-----------------------

A cube definition is a sequence of SQL scripts describing:

- measure groups
- dimensions
- relationships
- calculated fields
- access rules
- Jinja logic

XLTable reads definitions from one of two sources, selected by the
:confval:`CUBE_SOURCE` setting:

**Database table (default).** The scripts are stored in the analytical
database in a table named ``olap_definition``:

- ID — cube identifier
- Definition — SQL script defining cube structure

Every database that contains an ``olap_definition`` table appears in Excel
as a catalog, and every row of the table as a cube.

**Local folder** (``"CUBE_SOURCE": "folder"``). The scripts are plain
``.sql`` files in the folder set by :confval:`CUBES_FOLDER` (default
``cubes/``): one file = one cube, the file name without the extension is
the cube name. The file content is byte-for-byte the same definition text —
a file moved into the ``olap_definition`` table (or back) keeps working
unchanged. Excel sees a single catalog named ``Cubes``. Files are re-read
on every request, so saving a file in any SQL editor makes the change
visible immediately. In both modes the SQL of the cubes runs through the
same warehouse connection (:confval:`SERVER_DB` / :confval:`CREDENTIAL_DB`).

When a user connects from Excel:

1. XLTable reads cube definitions from the configured source
2. Displays available cubes
3. After selection, XLTable builds the list of measures and dimensions
4. Excel displays them in Pivot Table fields

Unified example
---------------

Follow this link for an example of creating an OLAP cube for a ClickHouse database: :ref:`unified_example` .

.. _cube_autogen:

Generating a cube automatically (autogen)
-----------------------------------------

A first-draft cube definition can be generated from a single table or view —
a working starting point that you refine by hand instead of writing the
definition from scratch.

In the **free desktop edition** the easiest way is the web wizard: open the
admin console (``http://127.0.0.1:5000/admin``) and open the **Create
cube** page of the **Cubes** section. The wizard walks the same steps in
the browser: filter the
warehouse tables by a substring and pick one, review how each column was
classified — and why, name the cube and save. If a cube file with that name
already exists, the wizard always asks — overwrite, save under another name
or cancel; nothing is ever overwritten silently. The saved cube appears on
the **Cubes** page (the live list of the cubes folder with the parse status
of each file) and in Excel immediately. The classification is applied as
proposed — to adjust a role, edit the saved ``.sql`` file in any SQL editor;
the server reloads it on save.

The same engine is also available from the command line:

.. code-block:: text

   XLTable.exe autogen                     # console wizard
   XLTable.exe autogen shop.sales          # direct: generate for a table
   XLTable.exe autogen shop.sales --full   # exact distinct counts (slower)

(on Linux: ``python main.py autogen ...``; the database connection is taken
from ``settings.json``, same as for the server.)

The web wizard, the console wizard and the direct call are fronts over one
generation engine. Another front is an AI assistant: with the
:doc:`MCP server <mcp>` connected, *“make a cube from the sales table”* runs
the same engine from the chat — see
:ref:`Creating cubes from the chat <mcp_create>`.

Autogen makes one light profiling pass over the table (row count, distinct
counts, min/max) and assigns a role to every column by rules:

- **date / datetime** columns become a ready **Year → Quarter → Month → Day**
  hierarchy;
- columns whose names signal a key or code (``id``, ``*_id``, ``code``,
  ``year`` …) become dimensions, even when numeric;
- numeric columns named like prices or rates (``price``, ``rate``,
  ``percent`` …) become **AVG** measures — summing them would be meaningless;
- other numeric columns become **SUM** measures with number formats;
- booleans and small low-cardinality integers become category dimensions;
- text columns become dimensions; near-unique text on large tables
  (comments, URLs) is excluded from the cube;
- a ``count(*)`` measure is always added;
- an empty :tag:`olap_description` block is left at the end of the file, with
  a hint inside, for you to describe the cube to AI assistants (see
  :ref:`cube_ai_semantics`). Field-level descriptions and synonyms are never
  generated — only a person knows what the columns mean.

The result is a complete, commented cube definition in a ``.sql`` file
(``cubes/<table>.sql`` by default; an existing file is never silently
overwritten). With ``"CUBE_SOURCE": "folder"`` the cube is already live —
the server reads the same folder, so it appears in Excel right away. In
the default database mode, paste the file contents into the
``olap_definition`` table (see :ref:`cube_definition_storage`). Either
way, the file is the natural place to keep refining the cube: rename
translations, arrange folders, add relationships and access rules.

``--full`` uses exact ``count(distinct)`` instead of the approximate
aggregate during profiling — more precise classification on the boundary
cases, at the cost of a slower scan of large tables.

Cube definition rules
---------------------

Cube structure is defined using SQL tags embedded in SQL scripts.

Examples:

- olap_source
- olap_measures
- olap_dimensions

See the full list of tags: :ref:`sql_tags`

How to write tag values
^^^^^^^^^^^^^^^^^^^^^^^^

A tag is written inside a SQL comment and starts with ``--``. There are two ways a
tag carries a value, depending on the tag.

**Block tags — value is the rest of the line.** For tags such as ``olap_source``,
the value is everything that follows the tag on the same line, taken literally up to
the end of the line. Spaces are part of the value, so no quoting is needed:

.. code-block:: sql

   --olap_source Sales last year

Here the source name is ``Sales last year`` — all three words.

**Inline tags — value after** ``=`` **in backticks.** Field-level tags such as
``translation``, ``format``, ``hierarchy`` and ``folder`` attach to a single field
and take their value after an ``=`` sign, wrapped in backtick characters:

.. code-block:: sql

   stores.name as stores_name --translation=`Store` --folder=`Distribution`

The backticks mark where the value begins and ends, which is what lets a value
contain spaces (``Sales Quantity``) or punctuation (``#,##0;-#,##0``). Backticks are
used deliberately instead of single or double quotes so the value never clashes with
``'...'`` and ``"..."`` string literals that may appear in the field expression
itself. Multiple inline tags can be placed on the same line, each separated by a space.

Measure group design
^^^^^^^^^^^^^^^^^^^^

The first step is defining the data source for a measure group.

Example:

.. code-block:: sql

   --olap_source Sales
   SELECT
   --olap_measures
       sum(sales.qty) as sales_sum_qty
   FROM db.Sales sales

The ``SELECT`` keyword is **mandatory**, not a stylistic choice: each
``olap_source`` block must be a complete, runnable SELECT statement. This lets you
copy any block into a database client and execute it as-is to verify it returns the
expected rows before XLTable ever uses it.

The order of blocks within an ``olap_source`` section is mandatory:

.. code-block:: text

   --olap_source <Name>         ← 1. source name
   SELECT                       ← 2. SELECT keyword (on its own line)
   --olap_measures              ← 3. section type (or --olap_dimensions)
       <field list>             ← 4. fields with aliases and tags
   FROM <table> <alias>         ← 5. main table
   LEFT JOIN ...                ← 6. joins (optional)

Important rules:

- table aliases must be unique across the cube
- the same table may be reused with a different alias

Measure definition
^^^^^^^^^^^^^^^^^^

A measure consists of:

1. source column
2. aggregation function
3. resulting column alias

Example:

.. code-block:: sql

   sum(sales.qty) as sales_sum_qty

Naming recommendation:

::

   <table_alias>_<aggregation>_<column>

Example:

::

   sales_sum_qty

Measure metadata tags
^^^^^^^^^^^^^^^^^^^^^

Additional tags may be defined on the same line:

- translation — display name in Excel (optional; if omitted, the field alias is used as the display name)
- format — numeric format in Pivot Tables

Example:

.. code-block:: sql

   sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`

Important: we place each measure on a new line, separated by commas.
Next, use the ``olap_measures`` tag before the list of measures to identify them for the OLAP cube.
This tag must be preceded by a ``SELECT`` statement, creating a standalone script that you can run in your database to see the results. 
Finally, add the ``olap_source`` tag followed by the measure group name on the same line; this tells the system whether the section contains a measure group or a dimension.


Dimension design
^^^^^^^^^^^^^^^^

We suggest reviewing the definition of measure groups first, as they are very similar to dimensions.

Dimensions define the analytical context for measures.

Typical examples:

- stores
- regions
- products
- time

Example:

.. code-block:: sql

   --olap_source Stores
   SELECT
   --olap_dimensions
       stores.id as store_id
      ,stores.store_name as store_name
   FROM db.Stores stores

Dimension metadata tags
^^^^^^^^^^^^^^^^^^^^^^^

Attributes may include tags such as translation (optional; if omitted, the field alias is used as the display name).

The ``translation`` value must be **unique within the cube** — it is the display name
Excel shows for the field, and duplicates would make two different fields
indistinguishable in the PivotTable field list.

Example:

.. code-block:: sql

   stores.store_name as store_name --translation=`Store`

Place the ``olap_dimensions`` tag before the attribute list, preceded by a SELECT statement to make the script executable. 
Above the SELECT statement, add the ``olap_source`` tag followed by the dimension name as it should appear in the Excel PivotTable. 
You can define multiple measure groups and dimensions this way, starting each with olap_source and separating the scripts with a blank line.


Hierarchies
^^^^^^^^^^^

Hierarchy defines parent-child relationships between dimension attributes.

Example:

.. code-block:: sql

   times.year as times_year --hierarchy=`Dates`
   times.quarter as times_quarter --hierarchy=`Dates`
   times.month as times_month --hierarchy=`Dates`
   times.day as times_day  --hierarchy=`Dates`

When a user selects a member deep inside a hierarchy, by default the filter
includes the whole path: picking a quarter with the year expanded produces
``year = '2024' AND quarter = 'Q2'`` in the ``WHERE`` clause. If member values
of every level are globally unique (they never repeat under different parents),
you can add the ``--filter_no_parents`` tag to any level of the hierarchy —
then only the selected member itself is filtered (``quarter = 'Q2'``), which
keeps rows whose parent has changed over time (for example, a product that
moved to another category). See :doc:`reference` for details.

.. _relationships:

Relationships
^^^^^^^^^^^^^

Relationships connect measures and dimensions.

Example:

.. code-block:: sql

   FROM db.Sales sales
   LEFT JOIN db.Stores stores ON sales.store_id = stores.id

Rules:

- always use LEFT JOIN
- joins must be explicit

A dimension is linked to a measure group through a **shared table alias**: the
alias used in the measure group's ``LEFT JOIN`` (for example ``LEFT JOIN db.Stores stores``)
must match the alias of the dimension's own source (``--olap_source Stores ... FROM db.Stores stores``).
XLTable connects the two on that identical alias, so keep aliases consistent across the cube.

Measure groups support both direct and indirect dimension relationships. Each link must be defined on a new line.
Indirect connections occur when a dimension links to a measure group via an intermediary dimension.

Special relationship types
^^^^^^^^^^^^^^^^^^^^^^^^^^

many-to-many:

.. code-block:: sql

   LEFT JOIN db.Managers managers ON sales.store_id = managers.store_id --relationship=`many-to-many`

Many-to-many relationships follow the classic Analysis Services model, where dimensions lack a unique key. Instead, a single measure group value maps to multiple dimension rows. For example, multiple managers can be assigned to the same store, causing overlapping results when filtering.

one-table:

.. code-block:: sql

   --olap_source Sales
   SELECT ...
   FROM db.sales sales
   LEFT JOIN db.sales sales --relationship=`one-table`

For denormalized sources like ClickHouse, use the relationship=`one-table` tag to link measures and dimensions within a single table. This bypasses the unique alias rule and the LEFT JOIN operation. The OLAP server will query the flat table directly; no ON clause or join columns are required.

part-source:

.. code-block:: sql

   --olap_source Sales
   SELECT ...
   FROM db.Sales sales
   LEFT JOIN db.Currencies curr on sales.currency = curr.id --relationship=`part-source`

By default, a ``LEFT JOIN`` whose alias matches another ``olap_source`` is treated as
a relationship to that other source (see :ref:`Relationships <relationships>`). Use
``relationship=`part-source``` when the joined table is **not** a separate cube source
but simply an extra table that belongs to the current source — a lookup table or a
helper join needed to compute its measures or attributes (for example attaching a
``Currencies`` reference to convert amounts).

The join is then treated as part of the current ``olap_source`` block only: it does
**not** register the table as a cube-wide source and does **not** create a new join
path that other measure groups or dimensions could connect through. Use it whenever
you need an auxiliary table inside one source without exposing it to the rest of the cube.

Calculated fields
-----------------

Calculated fields are virtual measures computed from other measures.

They are declared once for the whole cube, in a block that starts with the
``olap_cube`` tag followed by an ``olap_calculated_fields`` tag (whose value is
the folder name shown in the Excel field list).

Example:

.. code-block:: sql

   --olap_cube
   --olap_calculated_fields Calculated fields
   (sales_sum_qty/stock_avg_qty) as turnover --translation=`Turnover`

A calculated field may combine measures from **different** measure groups: the
per-group results are merged with a FULL JOIN before the expression is applied,
so any measure alias defined in the cube can be referenced here.

.. note::

   Because the inputs come from different measure groups, a measure may be
   ``NULL`` (no matching rows) or zero for a given cell. Always guard division
   against ``NULL`` and zero, for example
   ``(sales_sum_qty / nullIf(stock_avg_qty, 0)) as turnover``.

.. _drillthrough:

Drillthrough
------------

Drillthrough returns the raw detail rows behind an aggregated cell. When a user
double-clicks a value in an Excel Pivot Table, Excel sends a ``DRILLTHROUGH``
request and XLTable answers with a flat table of detail rows — the individual fact
records that were summed into that cell.

You declare which columns those detail rows contain **per measure group**, with the
``olap_drillthrough`` tag placed inside an ``olap_source`` block, after its
``LEFT JOIN`` clauses and **before** ``--olap_jinja`` if the source has one
(everything after ``--olap_jinja`` belongs to the Jinja template — a drillthrough
tag placed there would be rendered into the SQL of every query and break it):

.. code-block:: sql

   --olap_source Sales
   SELECT
   --olap_measures
    sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`
   ,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`
   FROM db.Sales sales
   LEFT JOIN db.Stores stores ON sales.store = stores.id
   LEFT JOIN db.Models models ON sales.model = models.id
   LEFT JOIN calendar times ON sales.date_sale = times.day_str
   --olap_drillthrough
   stores_name, models_name, times_day_str, sales_sum_qty, sales_sum_sum

The tag value is a **comma-separated list of fields already defined in the cube**.
Each entry may be the field's SQL alias (``stores_name``) or its ``translation``
display name (``Store``) — both resolve to the same field. Order is preserved: the
columns appear in the detail table in the order listed.

How it works:

- **Per measure group.** Each measure group has its own list, because each has its
  own granularity. Drilling a ``Sales`` cell returns Sales detail; drilling an
  ``Average Stock Quantity`` cell returns Stock detail.
- **The clicked measure picks the group.** The measure in the drilled cell selects
  which ``olap_source`` (fact table) the detail rows come from.
- **Measures are returned raw.** A measure listed here is emitted as its underlying
  column with the aggregation removed (``sum(sales.qty)`` → ``sales.qty``), so each
  row shows the individual fact value, not a total. ``count(...)`` becomes the
  literal ``1`` (one per row). This works only for measures that are a **single
  aggregate over a plain expression**: a compound expression combining several
  aggregates (``sum(sales.sum) / sum(sales.qty)``) or a conditional/uniq aggregate
  (``sumIf``, ``uniqExact``, ...) has no meaningful per-row value, so its column
  is skipped in the detail table (the syntax checker warns about such fields in
  the ``olap_drillthrough`` list).
- **Joins are resolved automatically.** Columns from related dimension tables pull
  in the necessary ``LEFT JOIN`` chain, including multi-hop paths
  (``Sales`` → ``Stores`` → ``Regions``). Relationships tagged
  ``relationship=`one-table``` produce no join, as in regular queries — the
  dimension columns are read directly from the fact table. The measure group's
  ``relationship=`part-source``` helper joins are always included, so measures
  computed through a lookup table (for example a currency conversion) drill
  through correctly.
- **Filters apply.** The cell's row, column and slicer context becomes the ``WHERE``
  clause, using the same row-level security and filtering as normal queries.
- **CTEs and Jinja apply** exactly as for regular queries (measure-group Jinja, then
  the cube CTE, then cube-level Jinja).

If a measure group has no ``olap_drillthrough`` tag, drilling a cell of that group
falls back to returning just the clicked measure as a single column.

.. note::

   Calculated fields cannot be drilled through — they are computed from measures
   that may span several measure groups and have no single set of underlying rows.
   Drilling a calculated field returns a clear message instead of data, matching
   Analysis Services behavior. A calculated field listed inside
   ``olap_drillthrough`` is skipped the same way as a compound measure.

For the end-user experience in Excel, see :ref:`excel_drillthrough`.

.. _cte:

CTE
---

CTE scripts define temporary datasets used in cube SQL.

A CTE is declared once, at the very top of the cube definition (before the
``olap_cube`` block). It is shared across the whole cube: every measure group and
dimension source can reference it, just like a real table.

Example:

.. code-block:: sql

   WITH calendar AS (
       SELECT ...
   )

CTEs can serve as data sources for both measure groups and dimensions — reference
the CTE name in a ``FROM`` or ``LEFT JOIN`` clause and give it an alias as usual
(for example ``LEFT JOIN calendar times``).

User roles
----------

User roles control access to cube data.

Example:

.. code-block:: sql

   --olap_user_role
   --olap_user_groups
   finance_users
   --olap_calculated_fields_visible
   all
   --olap_measures_visible
   sales_sum
   --olap_dimensions_visible
   region, store
   --olap_access_filters
   region in (`EU`, `NA`)
   store in (`Downtown North`, `Downtown South`)

The ``olap_user_role`` tag marks the beginning of a role definition; multiple roles can be defined.
Under ``olap_user_groups``, list the user groups that belong to this role.
Under the ``..._visible`` tags, list the measure groups, dimensions, individual measures, or dimension attributes visible to this role.
Under ``olap_access_filters``, define the row-level filters applied to this role.

Every role block must contain **all five directives**, even when a list is
empty or ``all`` — a block with a missing directive crashes cube processing.
The order of the directives inside the block is free, with one exception:
``--olap_access_filters`` must come **last** — its value is read to the end
of the role block, so any directive placed below it would be misread as a
filter line.

Each filter occupies its own line and has one of two forms:
``<alias> in ('value1', 'value2')`` — the role sees **only** the listed values,
or ``<alias> not in ('value1', 'value2')`` — the role sees everything **except**
the listed values.
The name to the left of ``in`` is the field's **alias** from the cube's SELECT section —
the name after ``AS`` (or, when the field has no ``AS``, the expression itself with dots
replaced by underscores: ``t.store_name`` becomes ``t_store_name``). Applying the
filter is case-insensitive, but write the alias in the same case as in the SELECT
section anyway: the automatic inclusion of a filtered field that is not listed
under ``..._visible`` matches the alias case-sensitively. Display names assigned
with ``--translation`` cannot be used here.

To filter by several fields in one role, put each filter on its own line. Unlike the
``..._visible`` tags, the lines are **not** separated by commas — inside this block commas
only separate the values of one ``in (...)`` list, and a stray comma at the start or end
of a line makes the filter invalid. Filters on different fields are combined with AND
(a row must satisfy all of them), while the values inside one ``in (...)`` list are
alternatives (OR). Listing the same field again — on another line, or in another role the
user belongs to — adds its values to the allowed set for ``in`` filters, and to the
excluded set for ``not in`` filters. A field referenced in an access
filter is always included in the cube for that role, even if it is not listed under
``--olap_dimensions_visible``.

Access filters are a security boundary: the server adds them to the ``WHERE``
clause of every SQL query it builds for the cube — regular pivot queries,
filter member lists, Keep Only / Hide probes and drillthrough. When a query
also filters the same field explicitly, the two conditions are intersected,
so no MDX query (including a hand-crafted one) can return rows outside the
role's allowed set; values excluded with ``not in`` never appear in results
or filter dropdowns. If a user belongs to several roles, their filters are
combined: the union of the allowed values, and the union of the excluded
values. Combining ``in`` and ``not in`` on the same field applies both
conditions (the allowed list minus the excluded values).

Do not confuse the two visibility mechanisms: the ``--hide`` tag hides a field
**globally**, for everyone (typically a helper measure used only inside calculated
fields), whereas the ``..._visible`` tags control visibility **per role** — each role
sees only the measures, dimensions and attributes listed for it.

.. _cube_ai_semantics:

Semantics for AI agents
-----------------------

A cube definition can carry a description of itself, written for an AI
assistant that queries the cube over :doc:`MCP <mcp>`. Four optional tags
hold it:

- :tag:`olap_description` — cube level: what the data is, its grain, which
  questions the cube answers;
- :tag:`olap_ai_instructions` — cube level: free-form instructions the
  assistant should follow for this cube;
- :tag:`description` — field level: business meaning, units, caveats;
- :tag:`synonyms` — field level: alternative names of the field, separated
  by ``;``.

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

The two cube-level blocks run to the next ``--olap_*`` tag or to the end of
the definition, so write them **at the very end** of the file, after the user
roles. Lines starting with ``--`` inside a block are comments and do not
become part of the text.

These tags are metadata for assistants only: Excel and the XMLA path ignore
them, the generated SQL does not change, and the file stays
connection-agnostic — the same definition works unchanged on any XLTable
server. What the assistant does with them, and how sample values of
low-cardinality dimensions are added from the live engine, is described in
:ref:`mcp_semantics`.

.. _sql_generation_logic:

SQL generation logic
--------------------

In short, XLTable works as follows: when a user selects fields in an Excel PivotTable, Excel sends an MDX query to the OLAP server. The server parses the MDX and, based on the cube's definition, generates several SQL queries to the database. To build efficient OLAP cubes, it is essential to understand how these SQL queries are constructed.

When a user selects fields in Excel:

1. Excel sends an MDX query
2. XLTable interprets selected measures and dimensions
3. SQL is generated only for selected elements
4. Queries are executed in the database
5. Results are returned to Excel Pivot Table

If multiple measure groups exist:

- SQL is generated per group
- results are merged using FULL JOIN
- shared dimension attributes are used as join keys

Put simply, SQL generation follows a basic principle: the queries executed are exactly what is defined in the cube metadata.
Enable logging in settings.json → WRITE_LOG to inspect generated SQL.

.. _validation_debugging:

Validation and debugging
------------------------

Two facilities help you confirm a cube definition is correct and inspect what
XLTable actually runs against the database.

**Check the definition before connecting** — add the ``definition_check_on`` tag to
the cube definition. When present, XLTable performs a mandatory syntax validation of
the whole definition before connecting to data; findings of severity **error** refuse
the connection with an error message, so a broken definition never reaches users
(warnings — naming style, missing translations — are only reported, the cube keeps
working).

**Inspect the generated SQL** — set ``WRITE_LOG`` to ``true`` in ``settings.json``.
XLTable then writes every generated SQL query to the log folder
(``...\xltable\log``), letting you see the exact statements produced for the user's
field selection. This is the fastest way to debug unexpected results or performance
issues. Changes to ``settings.json`` are picked up automatically within a few
seconds — no restart is needed.

A practical workflow is: run each ``olap_source`` block on its own in a database
client (every block is a runnable SELECT), then enable ``definition_check_on`` and
``WRITE_LOG`` to validate the full definition and review the final SQL.

Jinja scripts
-------------

Jinja templates let you modify the generated SQL dynamically — for performance
optimization, conditional SQL logic and advanced metrics — using the ``--olap_jinja``
tag inside the cube. Scripts receive the current SQL text and a rich ``context``
describing the request.

Jinja has its own chapter: see :doc:`jinja` for scripts, the ``context`` object
reference and template debugging.

Some examples
-------------

This section contains examples of the most common cube configuration scenarios.

Cube from a single denormalized table
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When all data resides in one flat table, use ``relationship=`one-table``` to link measures and dimensions without a real join:

.. code-block:: sql

   --olap_source Sales
   SELECT
   --olap_measures
    sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`      --format=`#,##0;-#,##0`
   ,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`        --format=`#,##0.00;-#,##0.00`
   FROM db.Sales sales
   LEFT JOIN db.Sales sales --relationship=`one-table`

   --olap_source Stores
   SELECT
   --olap_dimensions
    sales.store as sales_store --translation=`Store`
   FROM db.Sales sales 

Measures and dimensions from separate tables with one-table relationship
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Use this pattern when measures and dimensions live in different tables but the dimension data
is fully repeated in each fact row — no separate key join is needed.
The ``relationship=`one-table``` tag tells XLTable to query each table independently
and match dimension values directly from the fact rows, bypassing a traditional JOIN.

This is the recommended approach when filter value lookups (the lists of values shown in Excel slicers)
should run against a small, fast dimension table, while the main aggregation query runs against
a large denormalized fact table. Keeping the two queries separate avoids scanning the entire
fact table just to populate a filter dropdown.

.. note::

   The dimension field used for matching (``store`` in this example) must exist in both tables —
   in the dimension table for the filter lookup, and in the fact table for applying the filter to the main query.

.. code-block:: sql

   --olap_source Sales
   SELECT
   --olap_measures
    sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`      --format=`#,##0;-#,##0`
   ,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`        --format=`#,##0.00;-#,##0.00`
   FROM db.Sales sales
   LEFT JOIN db.Stores stores --relationship=`one-table`

   --olap_source Stores
   SELECT
   --olap_dimensions
   store as sales_store --translation=`Store`
   FROM db.Stores stores

------------------------------------------------------------

Cube design rules and recommendations
-------------------------------------

The first part of this section lists **required rules** — they are part of
the cube definition syntax, and a cube that violates them will not work
correctly. The second part contains **recommendations** that keep cubes
fast and maintainable.

Required rules
^^^^^^^^^^^^^^

Naming conventions:

- measures → ``<table_alias>_<aggregation>_<column>``
- dimensions → ``<table_alias>_<column>``
- aliases must be unique

Table alias rules:

- every source must have a unique alias
- aliases must remain stable

Join rules:

- always use LEFT JOIN
- define joins explicitly

Recommendations
^^^^^^^^^^^^^^^

Dimension strategy:

- use descriptive attributes
- avoid high-cardinality fields

Hierarchy design:

- build logical parent-child structures
- maintain natural ordering

Measure design:

- keep aggregations simple
- avoid nested SQL

Calculated fields:

- use only when required
- keep readable and testable

Performance:

- minimize joins
- pre-aggregate data in database
- reduce cube complexity

Cardinality:

- avoid using IDs as primary dimensions
- prefer grouped attributes

Jinja:

- use for small SQL adjustments
- avoid complex logic

Security:

- define roles early
- restrict sensitive measures

Maintainability:

- separate blocks clearly
- version control cube definitions

Design philosophy:

SQL first.

Everything in XLTable cubes is defined using SQL:

- structure
- logic
- metadata
- security

