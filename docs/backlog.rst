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
     - Drill-through
     - Ability to view the underlying detail rows behind an aggregated cell value in Excel.
     - Done (2.0.14)

   * - 8
     - Collapse all
     - Ability to collapse all expanded hierarchy levels in an Excel Pivot Table with a single action.
     - Done (2.0.15)

   * - 9
     - Semantic layer for AI agents
     - Expose the XLTable semantic layer (measures, dimensions, hierarchies, access rules)
       as a structured interface consumable by AI agents and LLM-based tools.
     - Done (2.0.19)

   * - 10
     - Free tier with limited functionality
     - A free edition of XLTable with a restricted feature set for evaluation and small-scale use.
     - Done (2.0.19)

   * - 11
     - AI assistant for cube design
     - An AI-powered assistant that helps developers design cube structure,
       suggest measure and dimension definitions, and detect common mistakes.
     - Done (2.1.0)

   * - 12
     - Slicers support
     - Native support for Excel slicers connected to XLTable cube dimensions.
     - Done (2.1.0)

   * - 13
     - Pre-aggregation friendly SQL
     - Generate cube SQL in a form that lets the database engine answer queries from
       its own pre-aggregated structures, such as materialized views and projections:
       aggregate over raw fact table columns first and join dimension attributes
       to the aggregated result, instead of joining and casting before aggregation.
     - Done (2.1.2)

   * - 14
     - Native data types in dimension attributes
     - Currently all dimension attributes are cast to string. Planned support for integer and date types,
       allowing dimension values to be used in Excel with their native format.
     -

   * - 15
     - Sort by another field
     - Ability to sort a dimension attribute by the values of a different field
       (for example, sort month names by month number).
     -

   * - 16
     - DAX support
     - Support for DAX query language alongside MDX for cube interaction.
     -

   * - 17
     - Built-in Jinja functions
     - A library of built-in Jinja functions available in cube SQL templates
       for common transformations, date handling, and formatting operations.
     -

   * - 18
     - Excel for Mac support
     - Ability to work with XLTable data in Excel on macOS.
     -

   * - 19
     - SQL endpoint
     - Expose XLTable cubes over the PostgreSQL wire protocol so that BI tools
       (Power BI, DataLens, Apache Superset, Metabase, Tableau and others)
       can connect to cubes as regular database tables without a dedicated connector.
       Each cube is presented as a flat virtual table with hierarchy levels
       and pre-aggregated measures as columns. Authentication, row-level security
       and the shared result cache apply the same way as for Excel and MCP.
     -

   * - 20
     - API endpoint
     - An HTTP API for querying cubes (dimensions, measures, filters, sorting, limit)
       and retrieving cube metadata, with results in JSON or CSV.
       Uses the same authentication, row-level security and result cache as Excel and MCP.
       Intended for scripts, notebooks, embedded analytics and partner integrations.
     -

   * - 21
     - Aggregate awareness
     - Support for pre-aggregated tables stored and refreshed by the database
       (for example, "sales by store by month"), which answer queries orders of magnitude
       faster than the raw fact table. Pre-aggregates are declared in the cube definition,
       and XLTable routes each query to the smallest suitable one — the semantic layer
       knows how hierarchy levels roll up (months into quarters, stores into regions)
       and which measures cannot be re-aggregated (averages, distinct counts) —
       falling back to the fact table when no pre-aggregate fits.
     -
