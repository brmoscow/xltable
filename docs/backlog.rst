Backlog
=======

This section lists features and improvements planned for development
over the next 9 months (Q2–Q4 2026).

.. list-table::
   :header-rows: 1
   :widths: 5 45 40 10

   * - #
     - Feature
     - Description
     - Status

   * - 1
     - Cube structure validation module
     - A developer-facing tool that validates cube SQL scripts before deployment:
       checks tag syntax, alias uniqueness, mandatory block order, and relationship consistency.
     - Done (2.0.11)

   * - 2
     - Collapse all
     - Ability to collapse all expanded hierarchy levels in an Excel Pivot Table with a single action.
     -

   * - 3
     - Native data types in dimension attributes
     - Currently all dimension attributes are cast to string. Planned support for integer and date types,
       allowing dimension values to be used in Excel with their native format.
     -

   * - 4
     - Drill-through
     - Ability to view the underlying detail rows behind an aggregated cell value in Excel.
     -

   * - 5
     - Sort by another field
     - Ability to sort a dimension attribute by the values of a different field
       (for example, sort month names by month number).
     -

   * - 6
     - Slicers support
     - Native support for Excel slicers connected to XLTable cube dimensions.
     -

   * - 7
     - DAX support
     - Support for DAX query language alongside MDX for cube interaction.
     -

   * - 8
     - Power BI connection
     - Support for connecting Power BI to XLTable as a data source.
     -

   * - 9
     - Free tier with limited functionality
     - A free edition of XLTable with a restricted feature set for evaluation and small-scale use.
     -

   * - 10
     - AI assistant for cube design
     - An AI-powered assistant that helps developers design cube structure,
       suggest measure and dimension definitions, and detect common mistakes.
     -

   * - 11
     - Semantic layer for AI agents
     - Expose the XLTable semantic layer (measures, dimensions, hierarchies, access rules)
       as a structured interface consumable by AI agents and LLM-based tools.
     -
