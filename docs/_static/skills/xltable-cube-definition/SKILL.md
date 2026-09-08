---
name: xltable-cube-definition
description: Use when writing, generating or reviewing an XLTable OLAP cube definition (a row of the olap_definition table or a cubes/*.sql file) from table DDL and analytics requirements — measure groups, dimensions, hierarchies, joins, calculated fields, user roles / row-level security, AI semantics for MCP.
---

# XLTable cube definition

## Overview

A cube definition is a sequence of ordinary, runnable SQL `SELECT` statements
annotated with `--olap_*` tags inside comments. XLTable parses the text
**positionally, by substrings** — block order, keywords on their own lines and
the reserved characters are syntax, not style. Mistakes of this class are
silent: the cube loads but loses fields or returns wrong totals.

Core principle: **write SQL that runs first, then tag it.** Every
`--olap_source` block must execute as-is in the warehouse.

## Workflow

1. **Classify the inputs.** Fact tables → measure groups (one per grain).
   Reference tables → dimensions. Requested drill paths → hierarchies.
   Access rules → roles. Note the SQL dialect from the DDL.
2. **Write the skeleton** in the fixed order below, then fill the fields.
3. **Check every rule** in "Rules that break silently" and the checklist.
4. **Verify**: run each block standalone against the warehouse if you can.
   `--definition_check_on` is **mandatory** in every definition you produce
   (own line, right after the first comment line) — with it the server
   validates the definition on first use and refuses a broken cube with a
   list of problems instead of serving wrong numbers. If an XLTable MCP
   server is available, close the loop: load the definition, call
   `describe_cube`, then `query_cube` with one slice per measure group and
   per hierarchy; a result with `isError` means fix and reload.
5. **Deliver** two artifacts: the definition as a `.sql` file (the versioned
   source of truth) and, when cubes live in the database
   (`CUBE_SOURCE=database`, the default on servers), the INSERT/UPDATE
   statement for `olap_definition` with dialect-specific quote escaping (see
   `reference.md`). With `CUBE_SOURCE=folder` the `.sql` file itself is the
   deliverable — drop it into the cubes folder. Never invent access-filter
   values — take them from the requirement or ask.

## Skeleton (fixed top-to-bottom order)

```sql
-- Sales cube                                   <- at least one line BEFORE --olap_cube
--definition_check_on                           <- MANDATORY: server validates before serving
with calendar as (                              <- optional CTEs, shared by the whole cube
    select day, year, month from db.dates
)

--olap_cube
--olap_calculated_fields Calculated fields
 (sales_sum_amount / nullIf(sales_uniq_order_id, 0)) as calc_avg_check --translation=`Average check` --format=`#,##0.00;-#,##0.00`

--olap_source Sales                              <- measure group: --olap_source, SELECT, --olap_measures
SELECT
--olap_measures
 sum(sales.qty)           as sales_sum_qty      --translation=`Quantity` --format=`#,##0;-#,##0`
,sum(sales.amount)        as sales_sum_amount   --translation=`Amount`   --format=`#,##0.00;-#,##0.00` --description=`Revenue incl. VAT` --synonyms=`revenue;turnover`
,count(distinct sales.order_id) as sales_uniq_order_id --translation=`Orders`
FROM db.sales sales
LEFT JOIN db.products products ON sales.product_id = products.id     <- same table + alias as the dimension's FROM
LEFT JOIN calendar times ON sales.day = times.day
--olap_drillthrough
products_name, times_day, sales_sum_qty, sales_sum_amount

--olap_source Products                           <- dimension: --olap_source, SELECT, --olap_dimensions
SELECT
--olap_dimensions
 products.category as products_category --hierarchy=`Products` --translation=`Category`
,products.name     as products_name     --hierarchy=`Products` --translation=`Product`
FROM db.products products

--olap_source Dates
SELECT
--olap_dimensions
 times.year  as times_year  --hierarchy=`Dates` --translation=`Year`
,times.month as times_month --hierarchy=`Dates` --translation=`Month`
,times.day   as times_day   --hierarchy=`Dates` --translation=`Day`
FROM calendar times

--olap_user_role                                 <- all five directives, access_filters LAST
--olap_user_groups
analysts
--olap_calculated_fields_visible
all
--olap_measures_visible
all
--olap_dimensions_visible
all
--olap_access_filters

--olap_description                               <- always the last two blocks of the file
Sales fact cube, one row per order line. Answers questions about revenue and quantity by product and day.
--olap_ai_instructions
"Revenue" means Amount (incl. VAT), not Quantity.
```

Do not copy the `<-` annotations into a real definition.

## Rules that break silently

| Rule | What goes wrong otherwise |
|------|---------------------------|
| **No backtick (`` ` ``) anywhere in SQL** — it is the tag-value delimiter. Quote identifiers with `"..."`, strings with `'...'`. | Every backtick is replaced by `'` before parsing; SQL breaks or a tag value is cut. |
| **No word `FROM` inside a dimension expression** — `EXTRACT(YEAR FROM x)`, `SUBSTRING(x FROM 1)`, `TRIM(x FROM y)`. Use dialect functions (`toYear`, `date_trunc`, `to_char`, `FORMAT_DATE`, `strftime`). | The `--olap_dimensions` field list is cut at the first `FROM`; fields after it vanish. |
| **No `--` comments, `LEFT JOIN`, or `--olap_` text inside field lists, expressions or prose** (including the CTE zone before `--olap_cube`). | Comments become tags; `--olap_` splits the definition. |
| **One field per line, leading commas, no trailing comma.** Tags after the alias on the same line. | Field boundaries misparse. |
| **A dimension links to a measure group only through `LEFT JOIN <table> <alias>` with the same table and alias as the dimension's `FROM`**: the dimension's `FROM db.products products` must appear as `LEFT JOIN db.products products ON ...` in every fact block it slices. The `ON` condition may differ per fact (`ON orders.product_id = products.product_id` here, `ON plan.category_id = products.category_id` there). A CTE under another name (`LEFT JOIN months times` vs `FROM calendar times`) does not link. | Measures return the grand total instead of a breakdown — no error. |
| **`one-table` dimensions run their expressions inside the fact query unchanged.** Dimension columns read from the fact table use the fact's own alias (`FROM db.sales sales` in both blocks); columns of a small lookup table are written **without any alias prefix** and must exist under the same name in the fact table. See the flat-table pattern below. | SQL error "missing FROM-clause entry" / "unknown identifier" on every query. |
| **Table aliases are unique across the cube** and stable; a measure group joining the same table twice needs two aliases (and two dimensions). | Joins merge into the wrong source. |
| **All levels of one `--hierarchy` in one `--olap_source`.** Need a parent from another table? Denormalize it into the dimension's SELECT via a ``--relationship=`part-source` `` join. | The second source overwrites the first; levels disappear. |
| **Field aliases and `--translation` values are unique** across the whole cube (measures, dimensions, calculated fields). | Excel shows indistinguishable fields; last wins. |
| **Naming**: measures `<alias>_<agg>_<column>` (`sales_sum_qty`), dimensions `<alias>_<column>`, calculated `calc_<name>`. | Style warnings; role blocks reference these aliases. |
| **Role block = all five directives** (`olap_user_groups`, `olap_calculated_fields_visible`, `olap_measures_visible`, `olap_dimensions_visible`, `olap_access_filters`), `--olap_access_filters` last. Filters: one per line, ``alias in (`v1`, `v2`)`` or `alias not in (...)`, by SQL alias (never by translation), no commas between lines. Empty `--olap_access_filters` = no filter. | Missing directive crashes cube processing; a filter on a wrong alias is ignored. |
| **`--olap_description` and `--olap_ai_instructions` at the very end**; each runs to the next `--olap_*` tag. | Following blocks become part of the description text. |
| **`--olap_jinja` is the last tag of its block** (`--olap_drillthrough` and `--olap_calculated_fields` go above it). Avoid Jinja unless the task asks. | Tags below it are rendered into every SQL. |
| **Calculated fields guard division**: `x / nullIf(y, 0)` (`NULLIF` in most dialects). Inputs from different measure groups are FULL-JOINed and may be NULL. | Division by zero / NULL cells. |
| **Storage escaping**: single quotes inside the definition string doubled (`''`) in ClickHouse / PostgreSQL / Greenplum / Trino / DuckDB / StarRocks, `\'` in Databricks (Spark), or use `"""..."""` (BigQuery) / `$$...$$` (Snowflake). The definition text itself always uses plain `'`. | Quotes vanish or the INSERT fails. |

## Modeling guidance

- **Calendar**: a Dates dimension must come from a dates table or a generated
  series (`numbers()`, `generate_series`, `UNNEST(GENERATE_DATE_ARRAY ...)`),
  never from `SELECT DISTINCT date FROM <fact>` — the CTE is prefixed to
  **every** query and would rescan the fact table each time. Join facts on the
  day (`toDate(fact.ts) = times.day`); expose Year → Quarter → Month → Day as
  one hierarchy. Every fact that is sliced by time joins the same `calendar
  times`.
- **Different grains**: a monthly plan next to daily sales joins the calendar
  on the first day of its month (`plan.month = times.day`) — it then rolls
  up correctly at month/quarter/year; never join a month key to the daily
  calendar on month equality (duplicates rows).
- **Fact with a subset of a dimension's keys** (plan by category, sales by
  product): join the dimension on the shared column with
  ``--relationship=`many-to-many` ``; XLTable wraps it in `SELECT DISTINCT`, so
  totals at the shared level stay correct and finer levels repeat the value,
  as in Analysis Services.
- **Flat denormalized table** (one wide table, common in ClickHouse). The
  `one-table` marker join has no `ON` and is the single exception to "every
  block runs as-is". One marker join per table; the fact alias is reused by
  every dimension read from the fact; a small lookup table gives fast filter
  lists and its columns are written bare:

  ```sql
  --olap_source Sales
  SELECT
  --olap_measures
   sum(sw.revenue) as sw_sum_revenue --translation=`Revenue`
  FROM mart.sales_wide sw
  LEFT JOIN mart.sales_wide sw --relationship=`one-table`
  LEFT JOIN mart.dim_store st --relationship=`one-table`

  --olap_source Products
  SELECT
  --olap_dimensions
   sw.sku_category as sw_sku_category --hierarchy=`Products` --translation=`Category`
  ,sw.sku_name     as sw_sku_name     --hierarchy=`Products` --translation=`Product`
  FROM mart.sales_wide sw

  --olap_source Stores
  SELECT
  --olap_dimensions
   store_region as st_region --hierarchy=`Stores` --translation=`Region`
  ,store_name   as st_name   --hierarchy=`Stores` --translation=`Store`
  FROM mart.dim_store st
  ```

  `store_region` and `store_name` exist in both `dim_store` and
  `sales_wide`; filter dropdowns scan `dim_store`, pivots read them from the
  fact row. Never give the fact table a second alias
  (``LEFT JOIN mart.sales_wide products --relationship=`one-table` ``) — the
  join is not emitted, so `products.x` is unresolvable.
- **Lookup joins inside one source** (currency, unit conversion) →
  ``--relationship=`part-source` `` so they do not become cube-wide sources.
- **Cardinality & privacy**: do not expose ids, emails, phone numbers, free
  text or near-unique columns as dimensions; prefer grouped attributes. Keys
  stay in joins. `--hide` helper measures used only by calculated fields.
- **Dialect**: use the warehouse's own functions for dates, `count(distinct
  ...)` vs `uniqExact` (ClickHouse), `nullIf`; the definition is not
  portable across dialects and need not be.
- **AI semantics** (MCP): `--olap_description` states the data, its grain and
  the questions answered; `--olap_ai_instructions` states conventions a
  correct answer depends on ("revenue = amount incl. VAT", "compare only
  closed months"); `--description` / `--synonyms` on fields with business
  meaning, units and caveats. Excel ignores all four.
- **Roles**: `--hide` hides for everyone; `..._visible` hides per role.
  There is no "all except X" syntax — to hide one measure from a role, list
  the other measures explicitly, and list only the calculated fields that
  do not use it. Access filters and visibility are enforced on every query,
  including drillthrough — a drillthrough column the role cannot see is
  simply skipped, so one `--olap_drillthrough` list serves all roles.

## Checklist before delivery

- [ ] A comment or CTE line precedes `--olap_cube`; block order matches the skeleton.
- [ ] Each source: `--olap_source <Name>` / `SELECT` / `--olap_measures` or `--olap_dimensions` / fields / `FROM <table> <alias>` / `LEFT JOIN ...`.
- [ ] No backticks in SQL; no `FROM`, `--`, `LEFT JOIN`, `--olap_` inside expressions or prose.
- [ ] Every dimension's `FROM table alias` appears verbatim as `LEFT JOIN table alias` in each fact block that must be sliced by it.
- [ ] Hierarchy levels of one hierarchy live in one source, ordered top → bottom.
- [ ] `one-table` cubes: fact-table dimensions reuse the fact alias; lookup-table columns have no alias prefix.
- [ ] Aliases and translations unique; naming convention followed; formats on measures.
- [ ] Roles: five directives each, `--olap_access_filters` last, filters by alias, every group from the requirement covered.
- [ ] `--olap_description` and `--olap_ai_instructions` are the last blocks.
- [ ] `--definition_check_on` present on its own line — REQUIRED, never omit it.
- [ ] Delivered as a `.sql` file plus, for database-stored cubes, the INSERT/UPDATE into `olap_definition` with correct quote escaping.

## Reference

- `reference.md` — every tag with syntax, format strings, storage per
  database, dialect date functions.
- `example.sql` — complete ClickHouse example using every tag (the same
  cube as the official docs' unified example).
- Full documentation as one text file for deeper questions:
  https://xltable-olap.readthedocs.io/en/stable/llms-full.txt
