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

Cube definition rules
---------------------

Cube structure is defined using SQL tags embedded in SQL scripts.

Examples:

- olap_source
- olap_measures
- olap_dimensions

See also: :ref:`sql_tags`

Measure group design
^^^^^^^^^^^^^^^^^^^^

The first step is defining the data source for a measure group.

Example:

.. code-block:: sql

   --olap_source Sales
   SELECT
   --olap_measures
       sum(sales.sale_qty) as sales_sum_qty
   FROM db.Sales sales

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

   sum(sales.sale_qty) as sales_sum_qty

Naming recommendation:

::

   <table_alias>_<aggregation>_<column>

Example:

::

   sales_sum_qty

Measure metadata tags
^^^^^^^^^^^^^^^^^^^^^

Additional tags may be defined on the same line:

- translation — display name in Excel
- format — numeric format in Pivot Tables

Example:

.. code-block:: sql

   sum(sales.sale_qty) as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`

Dimension design
^^^^^^^^^^^^^^^^

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
       stores.id as store_id,
       stores.store_name as store_name
   FROM db.Stores stores

Dimension metadata tags
^^^^^^^^^^^^^^^^^^^^^^^

Attributes may include tags such as translation.

Example:

.. code-block:: sql

   stores.store_name as store_name --translation=`Store`

Hierarchies
^^^^^^^^^^^

Hierarchy defines parent-child relationships between dimension attributes.

Example:

.. code-block:: sql

   times.year as year --hierarchy=`Dates`
   times.quarter as quarter --hierarchy=`Dates`
   times.month as month --hierarchy=`Dates`   
   times.day as day  --hierarchy=`Dates`

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

Measure groups support both direct and indirect dimension relationships. Each link must be defined on a new line.
Indirect connections occur when a dimension links to a measure group via an intermediary dimension.

Special relationship types
^^^^^^^^^^^^^^^^^^^^^^^^^^

many-to-many:

.. code-block:: sql

   LEFT JOIN db.Managers managers ON sales.store_id = managers.store_id --relationship='many-to-many'

Many-to-many relationships follow the classic Analysis Services model, where dimensions lack a unique key. Instead, a single measure group value maps to multiple dimension rows. For example, multiple managers can be assigned to the same store, causing overlapping results when filtering.

one-table:

.. code-block:: sql

   --olap_source Sales
   SELECT ...
   FROM db.sales sales
   LEFT JOIN db.sales sales --relationship='one-table'

For denormalized sources like ClickHouse, use the relationship='one-table' tag to link measures and dimensions within a single table. This bypasses the unique alias rule and the LEFT JOIN operation. The OLAP server will query the flat table directly; no ON clause or join columns are required.

Calculated fields
-----------------

Calculated fields are virtual measures computed from other measures.

Example:

.. code-block:: sql

   --olap_cube
   (sales_qty/stock_avg_qty) as turnover --translation=`Turnover`

CTE
---

CTE scripts define temporary datasets used in cube SQL.

Example:

.. code-block:: sql

   WITH calendar AS (
       SELECT ...
   )

CTEs can serve as data sources for both measure groups and dimensions.

User roles
----------

User roles control access to cube data.

Example:

.. code-block:: sql

   --olap_user_role
   --olap_user_groups
   finance_users

Visibility:

.. code-block:: sql

   --olap_calculated_fields_visible
   all
   --olap_measures_visible
   sales_sum
   --olap_dimensions_visible
   region, store

Access filters:

.. code-block:: sql

   --olap_access_filters
   region = 'EU'

SQL generation logic
--------------------

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

Enable logging in settings.json → WRITE_LOG to inspect generated SQL.

Jinja scripts
-------------

Jinja scripts allow modifying generated SQL dynamically.

Use cases:

- performance optimization
- conditional SQL logic
- advanced metrics

Execution order:

1. measure group Jinja
2. dimension Jinja
3. cube-level Jinja

See: :ref:`jinja_var`

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

Unified example
---------------
See: :ref:`unified_example`