-- =============================================================================
-- XLTable OLAP – Databricks sample data script
-- =============================================================================
-- Creates the `db` schema, all required dimension and fact tables (Delta),
-- fills them with ~3 500 rows of deterministic test data, and registers
-- the `myOLAPcube` OLAP cube definition (see reference.html#unified-example).
--
-- The script uses two-level names (db.<table>) and runs in the current
-- catalog — `hive_metastore` by default, matching the default `catalog`
-- behaviour of XLTable. On Unity Catalog, run `USE CATALOG <name>;` first
-- and set the same catalog in settings.json.
--
-- Prerequisites:
--   - A Databricks SQL warehouse (or an all-purpose cluster)
--   - A user with CREATE SCHEMA, CREATE TABLE privileges in the catalog
--
-- Usage (SQL editor, recommended):
--   Paste the script contents into a new query in the Databricks SQL editor
--   and click Run.
--
-- Usage (Databricks SQL CLI):
--   dbsqlcli --hostname <workspace-host> --http-path <warehouse-http-path> \
--            --access-token <dapi...> -e databricks_sample.sql
-- =============================================================================


-- ─── 1. Schema ───────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS db;


-- ─── 2. Dimension tables ─────────────────────────────────────────────────────

-- Calendar: every day of 2023, 2024 and 2025 (365 + 366 + 365 = 1096 rows)
CREATE OR REPLACE TABLE db.Times AS
SELECT
    date_format(date_add(DATE'2023-01-01', CAST(id AS INT)), 'yyyy-MM-dd') AS day_str,
    date_format(date_add(DATE'2023-01-01', CAST(id AS INT)), 'yyyy-MM')    AS month_str,
    date_format(date_add(DATE'2023-01-01', CAST(id AS INT)), 'yyyy')       AS year_str
FROM range(0, 1096);


-- Sales regions (4 rows)
CREATE OR REPLACE TABLE db.Regions AS
SELECT * FROM VALUES
    ('R1', 'North'),
    ('R2', 'South'),
    ('R3', 'East'),
    ('R4', 'West')
AS t(id, name);


-- Sales managers – many-to-many with Regions (5 rows)
CREATE OR REPLACE TABLE db.Managers AS
SELECT * FROM VALUES
    ('Alice Johnson', 'R1'),
    ('Bob Smith',     'R2'),
    ('Carol White',   'R3'),
    ('David Brown',   'R4'),
    ('Emma Davis',    'R1')
AS t(name, region);


-- Retail stores, each in one region (8 rows)
CREATE OR REPLACE TABLE db.Stores AS
SELECT * FROM VALUES
    ('S01', 'Downtown North', 'R1'),
    ('S02', 'Uptown North',   'R1'),
    ('S03', 'South Market',   'R2'),
    ('S04', 'South Center',   'R2'),
    ('S05', 'East Plaza',     'R3'),
    ('S06', 'East Mall',      'R3'),
    ('S07', 'West Gate',      'R4'),
    ('S08', 'West Park',      'R4')
AS t(id, name, region);


-- Product catalogue (8 rows)
CREATE OR REPLACE TABLE db.Models AS
SELECT * FROM VALUES
    ('M01', 'Product Alpha'),
    ('M02', 'Product Beta'),
    ('M03', 'Product Gamma'),
    ('M04', 'Product Delta'),
    ('M05', 'Product Epsilon'),
    ('M06', 'Product Zeta'),
    ('M07', 'Product Eta'),
    ('M08', 'Product Theta')
AS t(id, name);


-- ─── 3. Fact tables ──────────────────────────────────────────────────────────

-- Sales transactions: 3 000 rows spread across 2023–2024
-- hash() (murmur3) with pmod() provides deterministic pseudo-random distribution.
CREATE OR REPLACE TABLE db.Sales AS
WITH seq AS (
    SELECT CAST(id AS INT) AS n FROM range(0, 3000)
)
SELECT
    CASE pmod(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                             AS store,
    CASE pmod(hash(n * 7), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                             AS model,
    date_format(
        date_add(DATE'2023-01-01', pmod(hash(n * 3), 731)),
        'yyyy-MM-dd')                                               AS date_sale,
    CAST(1 + pmod(hash(n * 11), 100) AS INT)                        AS qty,
    ROUND((50 + pmod(hash(n * 13), 950)) * 1.5, 2)                  AS amount
FROM seq;


-- Stock inventory snapshots: 500 rows
CREATE OR REPLACE TABLE db.Stock AS
WITH seq AS (
    SELECT CAST(id AS INT) AS n FROM range(0, 500)
)
SELECT
    CASE pmod(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                             AS store,
    CASE pmod(hash(n * 5), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                             AS model,
    CAST(10 + pmod(hash(n * 17), 500) AS INT)                       AS qty
FROM seq;


-- ─── 4. OLAP cube definition ─────────────────────────────────────────────────
-- XLTable reads cube definitions from the `olap_definition` table.
-- Single quotes inside the definition string are escaped by doubling them ('').

CREATE OR REPLACE TABLE db.olap_definition (
    id         STRING,
    definition STRING
);

INSERT INTO db.olap_definition VALUES (
'myOLAPcube',
'
with calendar as (
    SELECT * FROM db.Times WHERE year_str IN (''2023'', ''2024'', ''2025'')
)

--olap_cube
--olap_calculated_fields Calculated fields
(sales_sum_qty / stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0.00;-#,##0.00`
--olap_jinja
{{ sql_text | replace("salesly.date_sale", "date_format(add_months(to_date(salesly.date_sale), 12), ''yyyy-MM-dd'')") }}

--olap_source Sales
SELECT
--olap_measures
 sum(sales.qty)    as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`
,sum(sales.amount) as sales_sum_sum --translation=`Sales Amount`   --format=`#,##0.00;-#,##0.00`
FROM db.Sales sales
LEFT JOIN db.Stores stores ON sales.store = stores.id
LEFT JOIN db.Models models ON sales.model = models.id
LEFT JOIN calendar times ON sales.date_sale = times.day_str
--olap_drillthrough
stores_name, regions_name, models_name, times_day_str, sales_sum_qty, sales_sum_sum

--olap_source Sales last year
SELECT
--olap_measures
 sum(salesly.qty)    as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
,sum(salesly.amount) as salesly_sum_sum --translation=`Sales last year Amount`   --format=`#,##0.00;-#,##0.00`
FROM db.Sales salesly
LEFT JOIN db.Stores stores ON salesly.store = stores.id
LEFT JOIN db.Models models ON salesly.model = models.id
LEFT JOIN calendar times ON salesly.date_sale = times.day_str

--olap_source Stock
SELECT
--olap_measures
 avg(stock.qty) as stock_avg_qty --translation=`Average Stock Quantity`
FROM db.Stock stock
LEFT JOIN db.Stores stores ON stock.store = stores.id
LEFT JOIN db.Models models ON stock.model = models.id

--olap_source Stores
SELECT
--olap_dimensions
 stores.id   as store_id    --translation=`Store ID`
,stores.name as stores_name --translation=`Store`
FROM db.Stores stores
LEFT JOIN db.Regions regions ON stores.region = regions.id

--olap_source Regions
SELECT
--olap_dimensions
 regions.name as regions_name --translation=`Region`
FROM db.Regions regions
LEFT JOIN db.Managers managers ON regions.id = managers.region --relationship=`many-to-many`

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
,date_format(date_trunc(''QUARTER'', to_date(times.day_str)), ''yyyy-MM'') as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
,times.month_str as times_month_str --hierarchy=`Dates` --translation=`Month`
,times.day_str   as times_day_str   --hierarchy=`Dates` --translation=`Day`
FROM calendar times

--olap_user_role
--olap_user_groups
olap_users
--olap_calculated_fields_visible
all
--olap_measures_visible
all
--olap_dimensions_visible
all
--olap_access_filters
');
