.. _ossie_export:

Export to Apache Ossie
======================

`Apache Ossie <https://github.com/apache/ossie>`_ is an open, vendor-neutral
format for semantic models — datasets, fields, metrics and relationships in
one YAML document, read by dbt, Snowflake and other tools of the modern data
stack. Since 2.1.4 XLTable exports a cube definition to this format: the
measures, dimensions, joins, descriptions and synonyms you wrote once for
Excel can be handed to another tool or to an AI agent without rewriting them.

The export is a pure function of the definition text — it runs without a
query to the warehouse and without changing the cube. Everything Ossie
cannot express (hierarchies, formats, smart measures, Jinja, roles) is kept
in the document as a vendor extension instead of being dropped, so the
export loses nothing — see :ref:`ossie_extensions`.

------------------------------------------------------------

How to get the document
-----------------------

On the :doc:`Cubes page <web_cubes>` of the web application open the cube,
switch to the **Definition** tab and click **Export → Apache Ossie (YAML)**
above the text: the browser saves ``<cube>.ossie.yaml``. The page is open to
analysts (:confval:`ANALYST_GROUPS`) and administrators, like the rest of
the cube internals.

The same document is served by the :ref:`REST API <api_cubes_page>` — for
scripts, CI pipelines and agents:

.. code-block:: bash

   curl -u analyst:secret -o Sales.ossie.yaml \
        https://xltable.company.local/api/cubes/Sales/ossie

``GET /api/cubes/<cube>/ossie`` answers with ``text/yaml`` and a
``Content-Disposition: attachment`` header. Query parameters:

.. list-table::
   :header-rows: 1
   :widths: 24 76

   * - Parameter
     - Meaning
   * - ``database``
     - The catalog with the ``olap_definition`` cube source when the
       warehouse has more than one database (as on the other endpoints).
   * - ``format=json``
     - The same document as ``application/json`` (``<cube>.ossie.json``).
   * - ``roles=1``
     - Include the cube's roles — user groups, visibility and the access
       filters of the row-level security — in the vendor extension. They
       are **left out by default**: access filters are internal to the
       company and the document is meant to leave the server.

The cube is exported from its definition text as the engine reads it,
without the expansion of :ref:`smart measures <smart_measures>`: the derived
measures (``--offset``, ``--exclude``, ``--semi``) stay single lines with
their tags in the extension, the generated twin sources do not appear. The
export works on the text, so the issues ``/issues`` reports do not stop it;
``400`` answers only what cannot be exported at all — a cube without
sources, a source without ``FROM``, a subquery in ``FROM``.

Mapping
-------

One Ossie document per cube. The document version is ``0.2.0.dev0`` — the
current Ossie core specification, the one dbt and Snowflake target.

.. list-table::
   :header-rows: 1
   :widths: 36 40 24

   * - XLTable
     - Ossie
     - Notes
   * - Cube id, :tag:`olap_description`, :tag:`olap_ai_instructions`
     - ``name``, ``description``, ``ai_context.instructions``
     -
   * - :tag:`olap_source` (a measure group or a dimension)
     - ``datasets[]``: ``name`` = the **alias** of the ``FROM`` table
       (``sales``, ``times``), ``source`` = the table (``db.sales``)
     - The dataset is named by the alias because Ossie expressions
       reference ``dataset.field`` and the cube's own expressions already
       read ``sales.qty``. The source name (``Sales``) is kept as ``label``
       in the extension.
   * - A source built on a CTE (``FROM calendar times``)
     - ``source: calendar`` plus the CTE text in the extension
     - Not portable — the CTE is SQL of the warehouse.
   * - A dimension level: ``times.month_str as times_month_str
       --translation=`Month` --date=month``
     - ``fields[]``: ``name`` = the alias, ``expression`` = ``month_str``
       (the table alias removed), ``label``, ``description``,
       ``ai_context.synonyms``; ``dimension.is_time: true`` when the level
       carries :tag:`date`
     - The grain of the :tag:`date` tag (``year``, ``month``, ``day``…) is
       kept in the extension; no ``datatype`` is guessed from SQL.
   * - The fact columns the measures read (``sales.qty``)
     - ``fields[]`` of the measure-group dataset (``qty`` →
       ``expression: qty``)
     -
   * - A measure: ``sum(sales.qty) as sales_sum_qty --translation=`Quantity`
       --format=… --description=… --synonyms=…``
     - ``metrics[]``: ``name`` = the alias, ``description`` = the display
       name, ``ai_context.instructions`` = ``--description``,
       ``ai_context.synonyms``, ``expression.dialects``
     - Ossie metrics have no label, so the display name becomes the
       ``description``. The ``--format`` string goes to the extension.
   * - The measure expression
     - ``OSSIE_SQL_2026`` when it passes the portable subset: ``SUM``,
       ``COUNT``, ``AVG``, ``MIN``, ``MAX`` (with ``DISTINCT``) over
       ``alias.column``, arithmetic, ``CASE``, ``NULLIF``, ``COALESCE``,
       literals; functions in upper case as in the Ossie examples
     - Anything else (``toQuarter(…)``, ``uniqExact(…)``) is written in the
       warehouse dialect when Ossie lists it (``SNOWFLAKE``, ``BIGQUERY``,
       ``DATABRICKS``), otherwise as ``ANSI_SQL`` with a ``non_portable``
       mark and the name of the warehouse dialect in the extension.
   * - A :ref:`calculated field <calculated_fields>`
       (``sales_sum_sum / nullif(sales_sum_qty, 0)``)
     - ``metrics[]`` with the base metrics **inlined**:
       ``SUM(sales.sum) / NULLIF(SUM(sales.qty), 0)``
     - Ossie does not define metric-to-metric references. When inlining is
       impossible (a reference to a smart measure or to Jinja) the
       expression is written as is and the extension carries
       ``calculated_field`` with the references.
   * - :tag:`offset`, :tag:`exclude`, :tag:`semi` on a measure
     - A metric with the base expression; the tag in the extension
       (``{"smart": {"offset": "-1 year"}}``) and *non-portable* in the
       description
     - The derived measure keeps its name and format.
   * - ``LEFT JOIN db.stores stores ON sales.store = stores.id`` in a
       measure group
     - ``relationships[]``: ``name: sales_to_stores``, ``from: sales``,
       ``to: stores``, ``from_columns: [store]``, ``to_columns: [id]``
     - Composite keys give several columns.
   * - ``--relationship=`many-to-many``` / ``constantly`` / ``part-source``
     - The relationship as above plus ``{"relationship": "many-to-many"}``
       in the extension
     - ``one-table`` (the same table under two aliases) produces no
       relationship.
   * - :tag:`hierarchy`, :tag:`folder`, :tag:`hide`,
       :tag:`filter_no_parents`
     - ``hierarchies``, ``folders`` and the list of ``hidden`` levels in the
       extension of the dataset; ``hidden: true`` in the extension of a
       hidden metric
     - Hierarchies are on the Ossie roadmap, not in the format yet.
   * - Roles, :tag:`olap_access_filters`, ``--olap_*_visible``
     - Not exported; with ``roles=1`` — ``roles`` in the extension of the
       document
     -
   * - :tag:`olap_jinja`
     - The script in the extension of the dataset, marked *non-portable*
     -
   * - :tag:`olap_drillthrough`
     - ``drillthrough`` in the extension of the dataset
     -

A fragment of the export of the :ref:`unified example <unified_example>`:

.. code-block:: yaml

   version: 0.2.0.dev0
   name: myOLAPcube
   description: "Sales fact cube …"
   datasets:
     - name: sales
       source: db.Sales
       fields:
         - name: qty
           expression:
             dialects:
               - dialect: OSSIE_SQL_2026
                 expression: qty
       custom_extensions:
         - vendor_name: XLTABLE
           data: "{\"label\": \"Sales\", \"drillthrough\": [\"stores_name\", …]}"
     - name: times
       source: calendar
       fields:
         - name: times_month_str
           expression:
             dialects:
               - dialect: OSSIE_SQL_2026
                 expression: month_str
           label: Month
           dimension:
             is_time: true
           custom_extensions:
             - vendor_name: XLTABLE
               data: "{\"date\": \"month\"}"
       custom_extensions:
         - vendor_name: XLTABLE
           data: "{\"label\": \"Dates\", \"cte\": \"with calendar as (…)\", \"hierarchies\": {\"Dates\": [\"times_year_str\", …]}}"
   metrics:
     - name: sales_sum_qty
       expression:
         dialects:
           - dialect: OSSIE_SQL_2026
             expression: SUM(sales.qty)
       description: Sales Quantity
       ai_context:
         synonyms:
           - quantity
           - units
           - pieces
         instructions: Units sold, pcs
       custom_extensions:
         - vendor_name: XLTABLE
           data: "{\"format\": \"#,##0;-#,##0\"}"
   relationships:
     - name: sales_to_stores
       from: sales
       to: stores
       from_columns:
         - store
       to_columns:
         - id

.. _ossie_extensions:

What goes to the vendor extension, and why
------------------------------------------

Ossie covers the core of a semantic model — datasets, fields, metrics,
relationships, descriptions and AI context — and leaves the rest to
``custom_extensions``: a list of ``{vendor_name, data}`` entries on any
object, ``data`` being a JSON string. This is how dbt marks its
non-portable metric semantics, and XLTable does the same: every object gets
at most one entry with ``vendor_name: XLTABLE``, and its ``data`` holds what
the format has no place for:

- the source name (``label``) and the ``--format`` strings — Excel
  presentation;
- ``hierarchies``, ``folders``, ``hidden`` — the field list as Excel shows it;
- ``smart`` — the :ref:`smart-measure <smart_measures>` tags of a derived
  measure (``offset``, ``exclude``, ``semi``);
- ``calculated_field`` — a calculated field that could not be inlined, with
  its references;
- ``non_portable`` (with the ``dialect`` of the warehouse) — an expression
  written in the warehouse dialect or ``ANSI_SQL`` because it is outside
  the Ossie expression language; ``date`` — the grain of a calendar level;
- ``cte``, ``jinja``, ``drillthrough`` — the SQL plumbing of a source;
- ``roles`` — only with ``roles=1``.

A tool that does not know XLTable ignores the extensions and still gets a
valid model with every dataset, field, metric and join; a tool that does can
rebuild the cube from the document.

Limitations
-----------

- **Export only.** XLTable does not import Ossie documents — the cube
  definition in SQL stays the source of truth; an importer (Ossie → draft
  cube) is planned together with the SSAS importer.
- The portable expression language of Ossie is small: aggregates over
  columns, arithmetic and ``CASE``. Warehouse functions (date arithmetic,
  ``uniqExact``, ``toStartOfMonth`` and the like) are exported in the
  warehouse dialect when Ossie names it — ``SNOWFLAKE``, ``BIGQUERY``,
  ``DATABRICKS`` — and as ``ANSI_SQL`` with a ``non_portable`` mark and
  the dialect name for ClickHouse, Trino, Greenplum, StarRocks and DuckDB.
  The text is the SQL of your warehouse either way.
- Smart measures are exported by their tags, not by the SQL the server
  generates for them: another tool sees the base measure and the intent
  (*previous period*, *without the dimension*, *value at the last date*),
  not a ready formula.
- Roles and access filters are left out unless ``roles=1``; the document
  is not a way to transfer security — set it up in the target tool.
- The format version is ``0.2.0.dev0``: Ossie is young and the
  specification still moves. The document validates against the JSON
  Schema of that version; a later XLTable release follows the format.
