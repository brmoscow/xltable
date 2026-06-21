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

Blocks are separated by a blank line. Refer back to this map as you read the
sections below.

Cube definition storage
-----------------------

XLTable stores cube definitions in a database table.

Each cube definition is a sequence of SQL scripts describing:

- measure groups
- dimensions
- relationships
- calculated fields
- access rules
- Jinja logic

These scripts are written sequentially and stored in the analytical database in a table named ``olap_definition``.

Table olap_definition structure:

- ID — cube identifier
- Definition — SQL script defining cube structure

When a user connects from Excel:

1. XLTable reads cube definitions from this table
2. Displays available cubes
3. After selection, XLTable builds the list of measures and dimensions
4. Excel displays them in Pivot Table fields

Unified example
---------------

Follow this link for an example of creating an OLAP cube for a ClickHouse database: :ref:`unified_example` .

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

The ``olap_user_role`` tag marks the beginning of a role definition; multiple roles can be defined.
Under ``olap_user_groups``, list the user groups that belong to this role.
Under the ``..._visible`` tags, list the measure groups, dimensions, individual measures, or dimension attributes visible to this role.
Under ``olap_access_filters``, define the row-level filters applied to this role.

Do not confuse the two visibility mechanisms: the ``--hide`` tag hides a field
**globally**, for everyone (typically a helper measure used only inside calculated
fields), whereas the ``..._visible`` tags control visibility **per role** — each role
sees only the measures, dimensions and attributes listed for it.

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

Validation and debugging
------------------------

Two facilities help you confirm a cube definition is correct and inspect what
XLTable actually runs against the database.

**Check the definition before connecting** — add the ``definition_check_on`` tag to
the cube definition. When present, XLTable performs a mandatory syntax validation of
the whole definition before connecting to data; if validation fails, the connection
is refused and an error is returned, so a broken definition never reaches users.

**Inspect the generated SQL** — set ``WRITE_LOG`` to ``true`` in ``settings.json``.
XLTable then writes every generated SQL query to the log folder
(``...\xltable\log``), letting you see the exact statements produced for the user's
field selection. This is the fastest way to debug unexpected results or performance
issues. Remember to restart the service after changing ``settings.json``.

A practical workflow is: run each ``olap_source`` block on its own in a database
client (every block is a runnable SELECT), then enable ``definition_check_on`` and
``WRITE_LOG`` to validate the full definition and review the final SQL.

.. _jinja_scripts:

Jinja scripts
-------------

When working with Big Data, performance and database load are critical. This means your SQL queries must be both accurate and efficient. Furthermore, users often require complex metrics that exceed the standard capabilities of OLAP cube measures. Jinja templates allow you to control SQL syntax without limitations, dynamically adapting the queries based on the user's selected fields and filters in Excel.

Jinja scripts allow modifying generated SQL dynamically.

Use cases:

- performance optimization
- conditional SQL logic
- advanced metrics

Example of a Jinja script modifying SQL:

.. code-block:: sql

   --olap_jinja
   {{ sql_text | replace("salesly.date_sale", "addYears(salesly.date_sale, 1)") }}

The principle is simple: Jinja scripts are defined within the cube and applied to modify the generated SQL query. You can define scripts for specific measure groups, dimensions, or the entire cube. A script assigned to a measure group only affects its specific SQL segment, while a cube-level script applies to the overall query.

Execution order:

1. measure group Jinja
2. cube-level Jinja

Jinja scripts take the SQL query text and the context data as inputs. This context includes the cube definition, user-selected fields, active filters, and other metadata essential for modifying the query dynamically.
See: :ref:`jinja_var`

Below are some additional examples of using scripts.

Example of a Jinja script with "if-else" statement:

.. code-block:: sql

   --olap_jinja
   {% if "invoice_id" in sql_text %}
       {{ sql_text | replace("FROM db.sale_by_days", "FROM db.sale_by_invoices") }}
   {% else %}
       {{ sql_text }}
   {% endif %}

Adding conditions "where" by default:

.. code-block:: sql

   --olap_jinja
   {% set sql_where = "where sale.year=2025 " %}
   {% if context["sale"]["sql_text_where"] %}
      {% set sql_where = context["sale"]["sql_text_where"] ~ " and sale.year=2025 " %}
   {% endif %}
   {{ sql_text | replace("FROM db.sale sale", "FROM db.sale sale " ~ sql_where) }}

Row-level security by user — restrict rows to the current user when they belong to the ``managers`` group
(see :ref:`jinja_var` for the ``user`` key; always use ``user.name_sql`` to avoid SQL injection):

.. code-block:: sql

   --olap_jinja
   {% if 'managers' in context.user.groups %}
   {{ sql_text | replace("WHERE", "WHERE managers.login = " ~ context.user.name_sql ~ " AND ") }}
   {% endif %}

Relative date filtering — limit data to the current year using the ``now`` key:

.. code-block:: sql

   --olap_jinja
   {{ sql_text | replace("WHERE", "WHERE times.year_str = '" ~ context.now.year ~ "' AND ") }}

Conditional logic on the client request — add an extra column only when a specific
calculated field was requested (see the ``request`` key):

.. code-block:: sql

   --olap_jinja
   {% if 'Turnover' in context.request.calculated_fields %}
   {{ sql_text | replace("FROM", ", some_extra_column FROM") }}
   {% endif %}


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

Best practices for cube design
------------------------------

Naming conventions:

- measures → <table_alias>_<aggregation>_<column>
- dimensions → <table_alias>_<column>

Aliases must be unique.

Table alias rules:

- every source must have a unique alias
- aliases must remain stable

Dimension strategy:

- use descriptive attributes
- avoid high-cardinality fields

Hierarchy design:

- build logical parent-child structures
- maintain natural ordering

Join strategy:

- always use LEFT JOIN
- define joins explicitly

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

