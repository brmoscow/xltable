Reference
=========

This section provides technical reference information for XLTable configuration,
SQL extensions and runtime variables.

It is intended for administrators, integrators and developers
working with cube definitions and system configuration.

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

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Tag
     - Description

   * - definition_check_on
     - When present in the cube definition, enforces mandatory syntax validation
       of the cube definition before connecting to data.
       If validation fails, the connection is not established and an error is returned.

   * - hide
     - Hides a measure or dimension from the list of fields in Excel.
   
   * - hierarchy   
     - After the tag, you must specify the name of the hierarchy to which the field belongs. 
       Fields with the same hierarchy name will be grouped together in Excel.
       
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

   * - olap_drillthrough
     - Marks a block, inside an ``olap_source`` measure-group block, listing the
       detail columns returned when a user drills through a cell of that measure
       group in Excel. The value is a comma-separated list of field aliases or
       display names already defined in the cube. See :ref:`drillthrough`.

   * - olap_jinja
     - Marks the beginning of a block with Jinja template logic that modifies SQL scripts.

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
     - Defines the join type for a ``LEFT JOIN`` clause within an ``olap_source`` block.
       Valid values:

       - ``many-to-many`` — join where the dimension table relates to multiple source rows.
       - ``one-table`` — all measures are in one table; dimension columns are selected directly without a join.
       - ``part-source`` — the ``LEFT JOIN`` is treated as part of the current ``olap_source`` block rather than a cross-source relationship.
         Use this to attach extra tables (CTEs, lookup tables) that belong to the same source and should not create a new join path to other sources.

   * - translation
     - Defines the localized name of a measure or dimension attribute displayed in Excel.
       The value must be unique within the cube.

   * - folder
     - Overrides the display folder for a field in the Excel field list.
       By default, fields are grouped under a folder named after their ``olap_source``.
       Use this tag to place a field into a differently named folder.

       Syntax: ``--folder=`Folder Name```

   * - format
     - Defines the display format of a measure in Excel Pivot Tables.
       The value follows the standard **Excel number format** syntax.
       A semicolon separates the positive and negative patterns: ``positive;negative``.

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
     sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`
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
     - Enables or disables logging of XLTable operations. Log files will be located in the folder  ``...\xltable\log``.
     - false

   * - USERS
     - Defines the list of users for local authentication.
     - —

   * - USER_GROUPS
     - Defines user groups used for role-based access control.
     - —

   * - MAX_CELLS
     - Limits the size of the pivoted result returned to Excel, measured in
       cells: unique row combinations × column combinations × measures.
       Queries exceeding the limit are rejected with a message suggesting
       filters, the same way SSAS cancels oversized results
       (``RowsetSerializationLimit``). The legacy ``MAX_ROWS`` key is still
       accepted and used as ``MAX_CELLS``.
     - 1000000

   * - LDAP_CACHE_TIMEOUT
     - Defines the lifetime of cached LDAP authorization data in seconds. 
       After this period expires, XLTable refreshes user permissions from LDAP.
     - 300

   * - CONVERT_FIELDS_TO_STRING
     - Forces conversion of certain fields to string type before returning results.
     - true

   * - ADMIN_GROUPS
     - Defines user groups for accessing the admin panel (``/admin``).
     - —

   * - CREDENTIAL_ACTIVE_DIRECTORY
     - Defines connection parameters for Active Directory authentication.
     - —

Service restart required
^^^^^^^^^^^^^^^^^^^^^^^^

After any changes to the ``settings.json`` file, the XLTable service
must be restarted for the new configuration to take effect.

Restart the service according to your deployment environment
(Linux Supervisor or Windows Service).

  