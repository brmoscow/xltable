# XLTable cube definition — reference

Companion to `SKILL.md`. Two kinds of tags:

- **Block tags** — `--olap_<name> <value>` on its own line; the value is the
  rest of the line (spaces allowed, no quoting).
- **Inline tags** — after a field or a JOIN on the same line:
  ``--<tag>=`value` ``; several per line separated by spaces. Backticks are
  the delimiter, which is why they may never appear in the SQL itself.

## Block tags

| Tag | Where | Meaning |
|-----|-------|---------|
| `--olap_cube` | once, after the optional CTEs | Start of the cube-level block (calculated fields, cube-level Jinja). At least one line must precede it. |
| `--olap_calculated_fields <Folder>` | inside `--olap_cube` | List of calculated fields; value = folder name in Excel. Expressions reference measure aliases (from any measure group) and other calculated aliases; no cycles. |
| `--olap_jinja` | last tag of `--olap_cube` or of a measure group | Jinja template over `sql_text` / `context`. Everything below it is template. |
| `--olap_source <Name>` | one per measure group / dimension | Name shown in Excel as the folder of its fields. Followed by `SELECT` on its own line. |
| `--olap_measures` | right after `SELECT` | The fields of this block are measures (aggregates). |
| `--olap_dimensions` | right after `SELECT` | The fields of this block are dimension attributes. |
| `--olap_drillthrough` | in a measure group, after its JOINs, above `--olap_jinja` | Comma-separated aliases (or translations) of fields returned on double-click in Excel. Measures appear raw (aggregation removed); compound / conditional / uniq measures and calculated fields are skipped. |
| `--olap_user_role` | after all sources | Start of a role; repeat for each role. |
| `--olap_user_groups` | in a role | Comma-separated group names (from the authentication source). |
| `--olap_calculated_fields_visible` | in a role | Comma-separated calculated aliases, source names, or `all`. |
| `--olap_measures_visible` | in a role | Comma-separated measure aliases, measure-group names, or `all`. |
| `--olap_dimensions_visible` | in a role | Comma-separated attribute aliases, dimension names, or `all`. |
| `--olap_access_filters` | **last** in a role | One filter per line: ``alias in (`v1`, `v2`)`` or ``alias not in (`v1`)``. Lines AND-ed; values within a list OR-ed; same field in several roles/lines = union. Empty block = no filter. |
| `--olap_description` | end of file | Cube text for AI assistants: what the data is, grain, questions answered. Runs to the next `--olap_*` tag. |
| `--olap_ai_instructions` | very end of file | Free-form conventions for AI assistants. Runs to the next `--olap_*` tag or EOF. |
| `--definition_check_on` | own line, anywhere (convention: right after the first comment line) | **Required in every definition.** Server validates the definition before connecting; errors block the cube with a list of problems, warnings are reported. |

Inside role blocks a directive's value is read to the next `--`, so every
role needs all five directives (even `all` or empty).

## Inline tags (on a field line)

| Tag | Applies to | Meaning |
|-----|-----------|---------|
| ``--translation=`Name` `` | any field | Display name in Excel; unique across the cube. Without it the alias is shown. |
| ``--format=`#,##0;-#,##0` `` | measures, calculated | Excel number format, `positive;negative`. Common: `#,##0;-#,##0`, `#,##0.00;-#,##0.00`, `0%`, `0.0%`, `#,##0;(#,##0)`. |
| ``--hierarchy=`Name` `` | dimension attributes | Levels with the same name form a hierarchy, top level first, all in one source. |
| `--filter_no_parents` | one level of a hierarchy | Filter by the selected member only (no parent equality). Use only when member values are globally unique. |
| ``--folder=`Name` `` | any field | Display folder override (default = source name). |
| `--hide` | any field | Hidden from Excel for everyone (helper measures for calculated fields). |
| ``--description=`text` `` | any field | Business meaning, units, caveats — for AI assistants. |
| ``--synonyms=`a;b;c` `` | any field | Alternative names, `;`-separated — for AI assistants. |

## Inline tags (on a LEFT JOIN line)

``--relationship=`<value>` ``:

| Value | Meaning |
|-------|---------|
| *(none)* | Regular relationship: the joined table's alias must match another `--olap_source`'s `FROM <table> <alias>`; that dimension slices this measure group. Indirect paths (Sales → Stores → Regions) resolve automatically. |
| `many-to-many` | The dimension has no unique key relative to the fact (plan by category vs products; managers per region). XLTable wraps the dimension in `SELECT DISTINCT` on the join key to avoid double counting at the shared level. |
| `one-table` | Flat table: no ON clause, the join is never emitted; the dimension's expressions are pasted into the fact query unchanged. Dimensions read from the fact table use the fact's alias (`FROM db.sales sales` in both blocks); a small lookup table for filter lists is joined with the same marker and its dimension lists **bare column names** that exist identically in the fact table. |
| `part-source` | Helper join that belongs to this source only (lookup / conversion table); does not create a cube-wide source or join path. |

## Naming conventions (the syntax checker warns on violations)

- Measure alias: `<source_alias>_<aggregate>_<column>` where aggregate is one
  of `sum avg count min max countif sumif avgif minif maxif uniq uniqexact`
  (e.g. `sales_sum_qty`, `orders_uniq_order_id`, `stock_avg_qty`).
- Dimension alias: `<source_alias>_<column>` (`stores_name`, `times_year`).
- Calculated alias: any identifier; `calc_<name>` keeps them recognizable.
- A field without `AS` gets its expression with dots replaced by `_` as
  alias (`t.store_name` → `t_store_name`) — always write an explicit alias.

## Storage forms

**Database table** (default, `CUBE_SOURCE=database`): table `olap_definition`
with columns `id` (cube name) and `definition` (text). Every database that
has such a table becomes a catalog in Excel; every row a cube. Quote
escaping inside the string literal:

| Warehouse | Escaping |
|-----------|----------|
| ClickHouse, PostgreSQL / Greenplum, Trino, DuckDB, StarRocks | double the quote: `''2024''` |
| Databricks / Spark SQL | backslash: `\'2024\'` (`''` concatenates literals and drops the quote) |
| BigQuery | wrap the whole definition in `"""..."""`, no escaping |
| Snowflake | wrap in `$$...$$`, no escaping |

ClickHouse example:

```sql
INSERT INTO dwh.olap_definition (id, definition) VALUES ('sales',
'
-- Sales cube
--olap_cube
...
');
```

To change an existing cube replace its row: `UPDATE ... SET definition = '...'
WHERE id = 'sales'` where the warehouse supports it; in ClickHouse delete and
re-insert (`ALTER TABLE ... DELETE WHERE id = 'sales'` then `INSERT`), or use a
`ReplacingMergeTree` table keyed by `id`. Open Excel pivots keep the old
metadata until refreshed; new connections and MCP see the change at once.

**Folder** (`CUBE_SOURCE=folder`, the free desktop edition): one
`cubes/<name>.sql` file per cube, plain text, no escaping, re-read on every
request. The file content is byte-for-byte the definition text.

## Dialect notes for dimension expressions

Never use `EXTRACT(... FROM ...)`, `SUBSTRING(... FROM ...)`, `TRIM(... FROM
...)` in a `--olap_dimensions` list (the word `FROM` ends the field list).
Equivalents that are safe:

Give every level a label that is distinct from the other levels (`2024`,
`2024-Q1`, `2024-01`, `2024-01-15`) — a quarter labelled like its first
month is confusing in Excel.

| Warehouse | Year | Quarter label (`2024-Q1`) | Month label (`2024-01`) | Day |
|-----------|------|---------------------------|-------------------------|-----|
| ClickHouse | `toYear(d)` | `concat(toString(toYear(d)), '-Q', toString(toQuarter(d)))` | `formatDateTime(d, '%Y-%m')` | `toDate(d)` |
| PostgreSQL / Greenplum | `to_char(d, 'YYYY')` | `to_char(d, 'YYYY-"Q"Q')` | `to_char(d, 'YYYY-MM')` | `d::date` |
| BigQuery | `FORMAT_DATE('%Y', d)` | `FORMAT_DATE('%Y-Q%Q', d)` | `FORMAT_DATE('%Y-%m', d)` | `DATE(d)` |
| Snowflake | `TO_VARCHAR(d, 'YYYY')` | `TO_VARCHAR(d, 'YYYY') \|\| '-Q' \|\| QUARTER(d)` | `TO_VARCHAR(d, 'YYYY-MM')` | `TO_DATE(d)` |
| Trino | `date_format(d, '%Y')` | `date_format(d, '%Y') \|\| '-Q' \|\| cast(quarter(d) as varchar)` | `date_format(d, '%Y-%m')` | `date(d)` |
| StarRocks | `date_format(d, '%Y')` | `concat(date_format(d, '%Y'), '-Q', quarter(d))` | `date_format(d, '%Y-%m')` | `date(d)` |
| DuckDB | `strftime(d, '%Y')` | `strftime(d, '%Y') \|\| '-Q' \|\| quarter(d)` | `strftime(d, '%Y-%m')` | `d::date` |
| Databricks | `date_format(d, 'yyyy')` | `concat(date_format(d, 'yyyy'), '-Q', quarter(d))` | `date_format(d, 'yyyy-MM')` | `to_date(d)` |

Prefer a physical dates table when the warehouse has one; otherwise build the
calendar CTE from a generated series (`numbers()` in ClickHouse,
`generate_series` in PostgreSQL / DuckDB, `GENERATE_DATE_ARRAY` in BigQuery,
`sequence` in Trino / Databricks). Text labels like `2024-03` sort
correctly; a bare month number `3` mixes years — label months with the year.

## How XLTable runs the cube (for performance reasoning)

For each Excel refresh XLTable builds one SQL per measure group that is
touched, containing only the selected measures, the joins needed for the
selected dimensions, `GROUP BY` the selected attributes and `WHERE` from
filters, slicers and the user's access filters. The cube's CTEs and Jinja are
prefixed to every such SQL. Several measure groups are merged with a `FULL
JOIN` on the shared attributes. Filter dropdowns run `SELECT DISTINCT` on
the dimension source alone — which is why dimensions should be small tables
or `one-table` lookups, not scans of the fact.

Set `WRITE_LOG=true` in `settings.json` to see every generated SQL in the
log folder.
