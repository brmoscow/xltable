Cube definition reference
=========================

This section provides technical reference information for cube definitions:
the SQL tags and a complete unified example.

It is intended for developers working with cube definitions. Server
configuration parameters are documented separately — see :doc:`settings`.

------------------------------------------------------------

.. _sql_tags:

SQL tags
--------

XLTable defines OLAP cubes using SQL scripts.

In addition to standard SQL syntax, cube definitions include special
inline tags embedded inside SQL comments. These tags act as keywords
that provide metadata and behavioral instructions for the XLTable engine.

SQL tags are not executed by the database.
They are parsed by XLTable before query execution and used to define:

- cube properties
- dimensions and measures
- security rules
- execution behavior
- metadata and configuration

This approach allows keeping cube definitions fully SQL-based
while extending them with OLAP semantics.

General usage
^^^^^^^^^^^^^

Tags are embedded directly into SQL scripts using comments.
During processing, XLTable reads these tags and builds
the OLAP cube structure based on them.

Tag reference
^^^^^^^^^^^^^

Every tag below has its own anchor — hover over a name and use the ¶ link
to share a direct reference to it.

.. tag:: definition_check_on

   When present in the cube definition, enforces mandatory syntax validation
   of the cube definition before connecting to data.
   If validation reports an error-severity finding, the connection is not
   established and an error is returned; warnings are only reported and do
   not block the cube.

   Example — the tag occupies a line of its own, anywhere in the definition:

   .. code-block:: sql

      --definition_check_on

.. tag:: description

   Business meaning of a single field, written for AI agents: what the value
   means, its units and any caveats. Shown by the MCP ``describe_cube`` tool
   (see :ref:`mcp_semantics`); Excel and the XMLA path ignore it entirely.
   It complements :tag:`translation`, which stays the short display name
   users see in a PivotTable.

   Syntax: ``--description=`Free text```

   Example:

   .. code-block:: sql

      sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`
          --description=`Revenue including VAT, in KZT`

.. tag:: filter_no_parents

   Placed on any level of a multi-level hierarchy, changes how the whole
   hierarchy is filtered: the ``WHERE`` clause contains only the selected
   member itself, without equality conditions on its parent levels.
   By default, selecting e.g. a quarter inside a Year → Quarter hierarchy
   produces ``year = '2024' AND quarter = 'Q2'``; with this tag only
   ``quarter = 'Q2'`` is generated.

   Enable it only on hierarchies where member values of every level are
   globally unique (do not repeat under different parents) — otherwise a
   filter would match same-named members under other parents.
   Typical use case: a child member moves between parents over time
   (a product changes category) and filtering by the parent path would
   cut off its history.

   Syntax: ``--filter_no_parents``

   Example — one tag on any level switches the whole hierarchy:

   .. code-block:: sql

      times.year as times_year --hierarchy=`Dates` --filter_no_parents
      times.quarter as times_quarter --hierarchy=`Dates`
      times.month as times_month --hierarchy=`Dates`

.. tag:: hide

   Hides a measure or dimension from the list of fields in Excel.

   Example — a helper measure used only inside calculated fields:

   .. code-block:: sql

      sum(sales.sum) as sales_sum_sum --translation=`Sales Amount` --hide

.. tag:: hierarchy

   After the tag, you must specify the name of the hierarchy to which the field belongs.
   Fields with the same hierarchy name will be grouped together in Excel.
   Allowed on dimension attributes only (measure groups have no hierarchies).

   Syntax: ``--hierarchy=`Hierarchy Name```

   Example — a Year → Quarter → Month hierarchy named ``Dates``:

   .. code-block:: sql

      times.year as times_year --hierarchy=`Dates` --translation=`Year`
      times.quarter as times_quarter --hierarchy=`Dates` --translation=`Quarter`
      times.month as times_month --hierarchy=`Dates` --translation=`Month`

.. tag:: olap_access_filters

   Marks the beginning of a block defining security filters for a specific user role.
   Each filter is written on its own line (no commas between lines) as
   ``<alias> in ('v1', 'v2')``, where ``<alias>`` is the field's alias from the cube's
   SELECT section (display names from :tag:`translation` cannot be used). Filters on
   different fields are combined with AND; the values of one list are alternatives (OR).
   The filters are enforced on every SQL query the server builds; an explicit
   filter on the same field in a query is intersected with the allowed values.

   Example:

   .. code-block:: sql

      --olap_access_filters
      regions_name in (`North`, `South`)
      stores_name in (`Downtown North`, `Downtown South`)

.. tag:: olap_ai_instructions

   Marks a cube-level block of free-form instructions for an AI agent
   querying this cube — conventions and caveats a correct answer depends on.
   The MCP ``describe_cube`` tool returns the text as written
   (see :ref:`mcp_semantics`); Excel and the XMLA path ignore the block.

   The block runs to the next ``--olap_*`` tag or to the end of the
   definition, so place it at the very end of the file. Lines starting with
   ``--`` inside the block are treated as comments and are not part of the
   text. If the tag appears more than once, the first non-empty block wins.

   Example:

   .. code-block:: sql

      --olap_ai_instructions
      Compare years only over completed months.
      "Revenue" always means Sales Amount, not Sales Quantity.

.. tag:: olap_calculated_fields

   Marks the beginning of a block containing the list of calculated fields. After the tag, you must specify the name of the folder calculated fields.

   Example:

   .. code-block:: sql

      --olap_cube
      --olap_calculated_fields Calculated fields
      (sales_sum_qty/stock_avg_qty) as turnover --translation=`Turnover`

.. tag:: olap_calculated_fields_visible

   Marks the beginning of a block listing calculated fields available to a specific user role.
   The value is a comma-separated list of calculated field aliases, or ``all``.
   A measure-group or dimension source name may be listed too, making all of its
   fields visible.

   Example:

   .. code-block:: sql

      --olap_calculated_fields_visible
      all

.. tag:: olap_cube

   Marks the beginning of a block describing cube properties and metadata.

   Example — the cube-level block holds calculated fields and cube-level Jinja:

   .. code-block:: sql

      --olap_cube
      --olap_calculated_fields Calculated fields
      (sales_sum_qty/stock_avg_qty) as turnover --translation=`Turnover`

.. tag:: olap_description

   Marks a cube-level block describing the cube for AI agents: what the data
   is, the grain (one row per what) and the questions the cube answers. The
   MCP ``list_cubes`` tool shows the first paragraph, ``describe_cube``
   returns the whole text (see :ref:`mcp_semantics`); Excel and the XMLA path
   ignore the block.

   The block runs to the next ``--olap_*`` tag or to the end of the
   definition, so place it at the very end of the file. Lines starting with
   ``--`` inside the block are treated as comments and are not part of the
   text — that is how :ref:`autogen <cube_autogen>` leaves an empty tag with
   a hint inside. If the tag appears more than once, the first non-empty
   block wins (so the empty autogen stub does not shadow a real description).

   Example:

   .. code-block:: sql

      --olap_description
      Sales fact cube, one row per sale line.

      Answers questions about revenue and quantity by store, model and period.

.. tag:: olap_dimensions

   Marks the beginning of a block listing dimension attributes.

   Example:

   .. code-block:: sql

      --olap_source Stores
      SELECT
      --olap_dimensions
       stores.id as store_id --translation=`Store ID`
      ,stores.name as stores_name --translation=`Store`
      FROM db.Stores stores

.. tag:: olap_dimensions_visible

   Marks the beginning of a block listing dimension attributes available to a specific user role.
   The value is a comma-separated list of attribute aliases, or ``all``.
   A dimension source name may be listed too, making all of its attributes visible.

   Example:

   .. code-block:: sql

      --olap_dimensions_visible
      regions_name, stores_name

.. tag:: olap_drillthrough

   Marks a block, inside an :tag:`olap_source` measure-group block, listing the
   detail columns returned when a user drills through a cell of that measure
   group in Excel. The value is a comma-separated list of field aliases or
   display names already defined in the cube. See :ref:`drillthrough`.

   Example:

   .. code-block:: sql

      --olap_drillthrough
      stores_name, models_name, times_day_str, sales_sum_qty

.. tag:: olap_jinja

   Marks the beginning of a block with Jinja template logic that modifies SQL scripts.

   Example — rewrite the generated SQL of the source (see :doc:`jinja`):

   .. code-block:: sql
      :force:

      --olap_jinja
      {{ sql_text | replace("salesly.date_sale", "addYears(salesly.date_sale, 1)") }}

.. tag:: olap_measures

   Marks the beginning of a block listing measures.

   Example:

   .. code-block:: sql

      --olap_source Sales
      SELECT
      --olap_measures
       sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`
      ,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`
      FROM db.Sales sales

.. tag:: olap_measures_visible

   Marks the beginning of a block listing measures available to a specific user role.
   The value is a comma-separated list of measure aliases, or ``all``.
   A measure-group source name may be listed too, making all of its measures visible.

   Example:

   .. code-block:: sql

      --olap_measures_visible
      sales_sum_qty, stock_avg_qty

.. tag:: olap_source

   Marks the beginning of a block defining the source dataset for measures or dimensions. After the tag, you must specify the name of the group of measures or dimension.

   Example — the value is the rest of the line, so names may contain spaces:

   .. code-block:: sql

      --olap_source Sales last year
      SELECT
      --olap_measures
       sum(salesly.qty) as salesly_sum_qty
      FROM db.Sales salesly

.. tag:: olap_user_groups

   Marks the beginning of a block listing security groups assigned to a user role.
   The value is a comma-separated list of group names.

   Example:

   .. code-block:: sql

      --olap_user_groups
      olap_users, finance_users

.. tag:: olap_user_role

   Marks the beginning of a block defining a user role.

   Example of a complete role block:

   .. code-block:: sql

      --olap_user_role
      --olap_user_groups
      olap_users
      --olap_calculated_fields_visible
      all
      --olap_measures_visible
      sales_sum_qty, stock_avg_qty
      --olap_dimensions_visible
      all
      --olap_access_filters
      regions_name in (`North`, `South`)

.. tag:: relationship

   Defines the join type for a ``LEFT JOIN`` clause within an :tag:`olap_source` block.
   Valid values:

   - ``many-to-many`` — join where the dimension table relates to multiple source rows.
   - ``one-table`` — all measures are in one table; dimension columns are selected directly without a join.
   - ``part-source`` — the ``LEFT JOIN`` is treated as part of the current ``olap_source`` block rather than a cross-source relationship.
     Use this to attach extra tables (CTEs, lookup tables) that belong to the same source and should not create a new join path to other sources.

   Syntax: ``--relationship=`value```

   Examples:

   .. code-block:: sql

      LEFT JOIN db.Managers managers ON sales.store_id = managers.store_id --relationship=`many-to-many`
      LEFT JOIN db.Sales sales --relationship=`one-table`
      LEFT JOIN db.Currencies curr ON sales.currency = curr.id --relationship=`part-source`

.. tag:: synonyms

   Alternative names of a field for AI agents — the words a person may use
   for it in a question. Returned by the MCP ``describe_cube`` tool
   (see :ref:`mcp_semantics`); Excel and the XMLA path ignore the tag. It
   complements :tag:`translation` (one display name for Excel) rather than
   replacing it.

   Syntax: ``--synonyms=`name1;name2;name3``` — items are separated by
   semicolons, surrounding spaces are trimmed.

   Example:

   .. code-block:: sql

      sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`
          --synonyms=`revenue;turnover;sales`

.. tag:: translation

   Defines the localized name of a measure or dimension attribute displayed in Excel.
   The value must be unique within the cube.

   Syntax: ``--translation=`Display Name```

   Example:

   .. code-block:: sql

      stores.name as stores_name --translation=`Store`

.. tag:: folder

   Overrides the display folder for a field in the Excel field list.
   By default, fields are grouped under a folder named after their :tag:`olap_source`.
   Use this tag to place a field into a differently named folder.

   Syntax: ``--folder=`Folder Name```

   Example:

   .. code-block:: sql

      stores.name as stores_name --translation=`Store` --folder=`Distribution`

.. tag:: format

   Defines the display format of a measure in Excel Pivot Tables.
   The value follows the standard **Excel number format** syntax.
   A semicolon separates the positive and negative patterns: ``positive;negative``.
   The tag is also accepted on dimension attributes, but the format is not
   applied to them in Excel yet — only measure cells carry a format string.

   Syntax: ``--format=`format string```

   Example:

   .. code-block:: sql

      sum(sales.qty) as sales_sum_qty --format=`#,##0;-#,##0`

   .. list-table::
      :header-rows: 1
      :widths: 38 31 31

      * - Format string
        - Positive value
        - Negative value
      * - ``#,##0;-#,##0``
        - 1,234
        - -1,234
      * - ``#,##0.00;-#,##0.00``
        - 1,234.56
        - -1,234.56
      * - ``#,##0.0;-#,##0.0``
        - 1,234.6
        - -1,234.6
      * - ``0%``
        - 56%
        - -56%
      * - ``0.0%``
        - 56.3%
        - -56.3%
      * - ``0.00%``
        - 56.34%
        - -56.34%
      * - ``#,##0;(#,##0)``
        - 1,234
        - (1,234)
      * - ``#,##0.00;(#,##0.00)``
        - 1,234.56
        - (1,234.56)

   The format string is stored in the cube definition and applied by Excel
   when the field is placed on a Pivot Table. Leaving the tag out lets
   Excel apply its default general format.

.. _unified_example:

Unified example
---------------

All tags listed in the table above are used together in a single cube definition example below.

This example demonstrates how SQL tags are embedded into a cube SQL script
and how they describe cube structure, measures, dimensions, security rules
and visibility settings.

The script represents a complete cube definition and can be used
as a reference when creating new OLAP cubes XLTable for ClickHouse.

.. code-block:: sql

    CREATE OR REPLACE TABLE db.olap_definition 
    ENGINE = MergeTree() ORDER BY id AS

    SELECT 'myOLAPcube' AS id,
    '	
    with calendar as (
        SELECT * FROM db.Times where year_str in (''2023'', ''2024'', ''2025'')
    )

    --olap_cube
    --olap_calculated_fields Calculated fields
    (sales_sum_qty/stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0;-#,##0`
    --olap_jinja
    {{ sql_text | replace("salesly.date_sale", "addYears(salesly.date_sale, 1)") }}

    --olap_source Sales
    SELECT
    --olap_measures
     sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0` --description=`Units sold, pcs` --synonyms=`quantity;units;pieces`
    ,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount` --format=`#,##0.00;-#,##0.00` --hide
    FROM db.Sales sales
    LEFT JOIN db.Stores stores on sales.store = stores.id
    LEFT JOIN db.Models models on sales.model = models.id
    LEFT JOIN calendar times on sales.date_sale = times.day_str
    LEFT JOIN db.Currencies curr on sales.currency = curr.id --relationship=`part-source`
    --olap_drillthrough
    stores_name, regions_name, models_name, times_day_str, sales_sum_qty, sales_sum_sum

    --olap_source Sales last year
    SELECT
    --olap_measures
     sum(salesly.qty) as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
    ,sum(salesly.sum) as salesly_sum_sum --translation=`Sales last year Amount` --format=`#,##0.00;-#,##0.00` --hide 
    FROM db.Sales salesly
    LEFT JOIN db.Stores stores on salesly.store = stores.id
    LEFT JOIN db.Models models on salesly.model = models.id
    LEFT JOIN calendar times on salesly.date_sale = times.day_str  

    --olap_source Stock
    SELECT
    --olap_measures
     avg(stock.qty) as stock_avg_qty --translation=`Average Stock Quantity`
    FROM db.Stock stock
    LEFT JOIN db.Stores stores on stock.store = stores.id
    LEFT JOIN db.Models models on stock.model = models.id

    --olap_source Stores
    SELECT
    --olap_dimensions
     stores.id as store_id --translation=`Store ID`
    ,stores.name as stores_name --translation=`Store` --folder=`Distribution`
    FROM db.Stores stores
    LEFT JOIN db.Regions regions on stores.region = regions.id

    --olap_source Regions
    SELECT
    --olap_dimensions
     regions.name as regions_name --translation=`Region`
    FROM db.Regions regions
    LEFT JOIN db.Managers managers on regions.id = managers.region --relationship=`many-to-many`

    --olap_source Managers
    SELECT
    --olap_dimensions
     managers.name as managers_name --translation=`Manager`
    FROM db.Managers managers

    --olap_source Models
    SELECT
    --olap_dimensions
     models.name as models_name --translation=`Model`
    FROM db.Models models

    --olap_source Dates
    SELECT
    --olap_dimensions
     times.year_str as times_year_str --hierarchy=`Dates` --translation=`Year`
    ,toQuarter(toDate(times.day_str)) as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
    ,times.month_str as times_month_str --hierarchy=`Dates` --translation=`Month` 
    ,times.day_str as times_day_str --hierarchy=`Dates` --translation=`Day` 
    FROM calendar times

    --olap_user_role
    --olap_user_groups
    olap_users  
    --olap_calculated_fields_visible
    all
    --olap_measures_visible
    sales_sum_qty, stock_avg_qty
    --olap_dimensions_visible
    all
    --olap_access_filters
    regions_name in (`North`, `South`)

    --olap_description
    Sales fact cube, one row per sale line.

    Answers questions about quantity and stock by store, region, manager,
    model and date.
    --olap_ai_instructions
    Compare years only over completed months.
    ' AS definition

------------------------------------------------------------

Jinja context variables
-----------------------

The Jinja ``context`` object handed to cube templates — its ``cube`` / ``request``
/ ``sql`` namespaces plus ``user`` and ``now`` — is documented in the
:doc:`Jinja chapter <jinja>`. See :ref:`jinja_var`.

------------------------------------------------------------

settings.json schema
--------------------

Server configuration parameters — server behavior, authentication, caching,
system limits and the ``EXPORT`` section — are documented on the
:doc:`settings` page.
