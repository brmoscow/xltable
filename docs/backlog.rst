Backlog
=======

This section lists features and improvements planned for development
in 2026.

.. list-table::
   :header-rows: 1
   :widths: 5 45 40 10

   * - #
     - Feature
     - Description
     - Status

   * - 1
     - Jinja context variables
     - Support for passing custom context variables into Jinja templates at query time,
       enabling dynamic parameterization of cube SQL scripts.
     - Done (2.0.10)

   * - 2
     - StarRocks connector
     - Support for connecting XLTable to StarRocks as a data source.
     - Done (2.0.10)

   * - 3
     - Cube structure validation module
     - A developer-facing tool that validates cube SQL scripts before deployment:
       checks tag syntax, alias uniqueness, mandatory block order, and relationship consistency.
     - Done (2.0.11)

   * - 4
     - Databricks connector
     - Support for connecting XLTable to Databricks as a data source.
     - Done (2.0.11)

   * - 5
     - Windows 10 and 11 support
     - Full support for running XLTable on Windows 10 and Windows 11.
     - Done (2.0.11)

   * - 6
     - Greenplum connector
     - Support for connecting XLTable to Greenplum as a data source.
     - Done (2.0.12)

   * - 7
     - AI assistant for cube design
     - An AI-powered assistant that helps developers design cube structure,
       suggest measure and dimension definitions, and detect common mistakes.
     - Done (Beta)

   * - 8
     - Semantic layer for AI agents
     - Expose the XLTable semantic layer (measures, dimensions, hierarchies, access rules)
       as a structured interface consumable by AI agents and LLM-based tools.
     - Done (Beta)

   * - 9
     - Collapse all
     - Ability to collapse all expanded hierarchy levels in an Excel Pivot Table with a single action.
     -

   * - 10
     - Native data types in dimension attributes
     - Currently all dimension attributes are cast to string. Planned support for integer and date types,
       allowing dimension values to be used in Excel with their native format.
     -

   * - 11
     - Drill-through
     - Ability to view the underlying detail rows behind an aggregated cell value in Excel.
     -

   * - 12
     - Sort by another field
     - Ability to sort a dimension attribute by the values of a different field
       (for example, sort month names by month number).
     -

   * - 13
     - Slicers support
     - Native support for Excel slicers connected to XLTable cube dimensions.
     -

   * - 14
     - DAX support
     - Support for DAX query language alongside MDX for cube interaction.
     -

   * - 15
     - Power BI connection
     - Support for connecting Power BI to XLTable as a data source.
     -

   * - 16
     - Free tier with limited functionality
     - A free edition of XLTable with a restricted feature set for evaluation and small-scale use.
     -

   * - 17
     - Built-in Jinja functions
     - A library of built-in Jinja functions available in cube SQL templates
       for common transformations, date handling, and formatting operations.
     -
