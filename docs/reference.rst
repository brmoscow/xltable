Reference
=========

This section provides technical reference information for XLTable configuration,
SQL extensions and runtime variables.

It is intended for administrators, integrators and developers
working with cube definitions and system configuration.

------------------------------------------------------------

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

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Tag
     - Description

   * - hide
     - Hides a measure or dimension from the list of fields in Excel.

   * - olap_access_filters
     - Marks the beginning of a block defining security filters for a specific user role.

   * - olap_calculated_fields
     - Marks the beginning of a block containing the list of calculated fields. After the tag, you must specify the name of the folder calculated fields.

   * - olap_calculated_fields_visible
     - Marks the beginning of a block listing calculated fields available to a specific user role.

   * - olap_cube
     - Marks the beginning of a block describing cube properties and metadata.

   * - olap_dimensions
     - Marks the beginning of a block listing dimension attributes.

   * - olap_dimensions_visible
     - Marks the beginning of a block listing dimension attributes available to a specific user role.

   * - olap_measures
     - Marks the beginning of a block listing measures.

   * - olap_measures_visible
     - Marks the beginning of a block listing measures available to a specific user role.

   * - olap_source
     - Marks the beginning of a block defining the source dataset for measures or dimensions. After the tag, you must specify the name of the group of measures or dimension.

   * - olap_user_groups
     - Marks the beginning of a block listing security groups assigned to a user role.

   * - olap_user_role
     - Marks the beginning of a block defining a user role.

   * - relationship
     - Defines the relationship type between a measure, a group of measures and a dimension.

   * - translation
     - Defines the localized name of a measure or dimension attribute displayed in Excel.

   * - format
     - Defines the display format of a measure in Excel Pivot Tables.

Unified example
^^^^^^^^^^^^^^^

All tags listed in the table above are used together in a single cube definition example below.

This example demonstrates how SQL tags are embedded into a cube SQL script
and how they describe cube structure, measures, dimensions, security rules
and visibility settings.

The script represents a complete cube definition and can be used
as a reference when creating new OLAP cubes in XLTable.

.. code-block:: sql

    --olap_cube
    --olap_calculated_fields Calculated fields
    (sales_qty/stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0;-#,##0`
    --olap_jinja
    {{ sql_text | replace("salesly.date_sale", "addYears(salesly.date_sale, 1)") }}

    --olap_source Sales
    SELECT
    --olap_measures
     sum(sales.qty) as sales_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`
    ,sum(sales.sum) as sales_sum --translation=`Sales Amount` --format=`#,##0.00;-#,##0.00` --hide 
    FROM db.Sales sales
    LEFT JOIN db.Stores stores on sales.store = stores.id
    LEFT JOIN db.Models models on sales.model = models.id
    LEFT JOIN db.Times times on sales.date_sale = times.day_str

    --olap_source Sales last year
    SELECT
    --olap_measures
     sum(ssalesly.qty) as salesly_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
    ,sum(salesly.sum) as salesly_sum --translation=`Sales last year Amount` --format=`#,##0.00;-#,##0.00` --hide 
    FROM db.Sales salesly
    LEFT JOIN db.Stores stores on salesly.store = stores.id
    LEFT JOIN db.Models models on salesly.model = models.id
    LEFT JOIN db.Times times on salesly.date_sale = times.day_str  

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
    ,stores.name as stores_name --translation=`Store`
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
    FROM db.Times times

    --olap_user_role
    --olap_user_groups
    olap_users  
    --olap_calculated_fields_visible
    all
    --olap_measures_visible
    sales_qty, stock_avg_qty
    --olap_dimensions_visible
    all
    --olap_access_filters
    regions_name in (`North`, `South`)


------------------------------------------------------------

Jinja context variables
-----------------------

XLTable uses Jinja templating to generate dynamic SQL based on the current Excel request.

For each query, XLTable passes a dictionary called ``jinja_context`` into the Jinja template.
This dictionary contains:

- cube definition and metadata
- generated SQL fragments (SELECT/WHERE/GROUP BY parts)
- the current query context defined by the user in Excel (axes, selected levels, filters)
- generated SQL fragments per OLAP source (measure group)

Key reference
^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Key
     - Meaning

   * - cube_definition
     - Full cube definition object loaded by XLTable. Includes cube metadata, objects, sources, joins, levels, access filters, CTE and Jinja settings.

   * - select_levels
     - Dictionary of SQL fragments used to build dimension and measure expressions in the SELECT clause for the current Excel request.

   * - where_levels
     - Dictionary of SQL fragments representing filters selected by the user in Excel (WHERE conditions grouped by dimension/level).

   * - group_levels
     - Dictionary of SQL fragments representing grouping keys (GROUP BY expressions) derived from the current Excel axes.

   * - dimension_axis0_levels
     - List of dimension levels placed by the user on Excel Axis 0 (typically Rows).

   * - dimension_axis1_levels
     - List of dimension levels placed by the user on Excel Axis 1 (typically Columns).

   * - <source_key>
     - Dynamic key for each OLAP source (measure group). The key name equals the source table alias/name (for example ``sales``, ``stock``, ``stores``).
       Each source entry contains source-specific SQL fragments such as ``sql_text_select``, ``sql_text_select_inside``, ``sql_text_where``, ``sql_text_group`` and ``sql_text``.
  
   * - any
     - Copy any <source_key>. Used when the same table is used as a source of measures and dimensions.

Dynamic source keys (<source_key>)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Source keys in ``jinja_context`` are derived from the table alias
defined in the SQL query of the cube source.

For example:

.. code-block:: sql

   --olap_source Sales
   SELECT ...
   FROM db.Sales sales

In this case, the key ``sales`` will appear in ``jinja_context``:

.. code-block:: python

   jinja_context = {
       ...
       'sales': {
           'sql_text_select': '...',
           'sql_text_select_inside': '...',
           'sql_text_where': '...',
           'sql_text_group': '...',
           'sql_text': '...'
       }
   }

The key name always matches the alias used after the table name
in the FROM clause.

Each source key contains SQL fragments for that source:

- ``sql_text_select``: SELECT clause fragment for the outer query
- ``sql_text_select_inside``: SELECT clause fragment for the inner query (raw fields used for grouping/aggregation)
- ``sql_text_where``: additional WHERE conditions applied to the source
- ``sql_text_group``: GROUP BY fragment (often GROUPING SETS)
- ``sql_text``: full generated SQL for the source

------------------------------------------------------------

settings.json schema
--------------------

This section describes the main configuration parameters available
in the ``settings.json`` file.

These parameters control server behavior, authentication,
database access, caching and system limits.

Parameter reference
^^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 35 45 20

   * - Parameter
     - Description
     - Default value

   * - SERVER_DB
     - Defines the primary database used by the XLTable server for internal operations.
     - —

   * - CREDENTIAL_DB
     - Defines credentials used for accessing the server database.
     - —

   * - WRITE_LOG
     - Enables or disables logging of XLTable operations.
     - false

   * - USERS
     - Defines the list of users for local authentication.
     - —

   * - USER_GROUPS
     - Defines user groups used for role-based access control.
     - —

   * - MAX_ROWS
     - Limits the maximum number of rows returned by a query.
     - 50000

   * - LDAP_CACHE_TIMEOUT
     - Defines the lifetime of cached LDAP authorization data in seconds. 
       After this period expires, XLTable refreshes user permissions from LDAP.
     - 300

   * - CONVERT_FIELDS_TO_STRING
     - Forces conversion of certain fields to string type before returning results.
     - true

   * - CREDENTIAL_ACTIVE_DIRECTORY
     - Defines connection parameters for Active Directory authentication.
     - —

Service restart required
^^^^^^^^^^^^^^^^^^^^^^^^

After any changes to the ``settings.json`` file, the XLTable service
must be restarted for the new configuration to take effect.

Restart the service according to your deployment environment
(Linux Supervisor or Windows Service).

  