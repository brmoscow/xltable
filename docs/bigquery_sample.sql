-- =============================================================================
-- XLTable OLAP – BigQuery sample data script
-- =============================================================================
-- Creates all required dimension and fact tables in the `olap` dataset,
-- fills them with deterministic test data, and registers the `myOLAPcube`
-- OLAP cube definition (see reference.html#unified-example).
--
-- Prerequisites:
--   - A Google Cloud project with the BigQuery API enabled
--   - The `olap` dataset must already exist:
--       bq mk --dataset <project_id>:olap
--   - A service account (or user) with BigQuery Data Editor + Job User roles
--
-- Usage (bq CLI):
--   bq query --use_legacy_sql=false --project_id=<project_id> \
--     < bigquery_sample.sql
--
-- Usage (Cloud Console / BigQuery Studio):
--   Paste the script contents into the query editor and click Run.
-- =============================================================================


-- ─── 1. Dimension tables ─────────────────────────────────────────────────────

-- Calendar: every day of 2023 and 2024 (365 + 366 = 731 rows)
CREATE OR REPLACE TABLE `olap.Times` AS
SELECT
    FORMAT_DATE('%Y-%m-%d', day) AS day_str,
    FORMAT_DATE('%Y-%m',    day) AS month_str,
    FORMAT_DATE('%Y',       day) AS year_str
FROM UNNEST(GENERATE_DATE_ARRAY('2023-01-01', '2024-12-31')) AS day;


-- Sales regions (4 rows)
CREATE OR REPLACE TABLE `olap.Regions` AS
SELECT id, name
FROM UNNEST(ARRAY<STRUCT<id STRING, name STRING>>[
    ('R1', 'North'),
    ('R2', 'South'),
    ('R3', 'East'),
    ('R4', 'West')
]);


-- Sales managers – many-to-many with Regions (5 rows)
CREATE OR REPLACE TABLE `olap.Managers` AS
SELECT name, region
FROM UNNEST(ARRAY<STRUCT<name STRING, region STRING>>[
    ('Alice Johnson', 'R1'),
    ('Bob Smith',     'R2'),
    ('Carol White',   'R3'),
    ('David Brown',   'R4'),
    ('Emma Davis',    'R1')
]);


-- Retail stores, each in one region (8 rows)
CREATE OR REPLACE TABLE `olap.Stores` AS
SELECT id, name, region
FROM UNNEST(ARRAY<STRUCT<id STRING, name STRING, region STRING>>[
    ('S01', 'Downtown North', 'R1'),
    ('S02', 'Uptown North',   'R1'),
    ('S03', 'South Market',   'R2'),
    ('S04', 'South Center',   'R2'),
    ('S05', 'East Plaza',     'R3'),
    ('S06', 'East Mall',      'R3'),
    ('S07', 'West Gate',      'R4'),
    ('S08', 'West Park',      'R4')
]);


-- Product catalogue (8 rows)
CREATE OR REPLACE TABLE `olap.Models` AS
SELECT id, name
FROM UNNEST(ARRAY<STRUCT<id STRING, name STRING>>[
    ('M01', 'Product Alpha'),
    ('M02', 'Product Beta'),
    ('M03', 'Product Gamma'),
    ('M04', 'Product Delta'),
    ('M05', 'Product Epsilon'),
    ('M06', 'Product Zeta'),
    ('M07', 'Product Eta'),
    ('M08', 'Product Theta')
]);


-- ─── 2. Fact tables ──────────────────────────────────────────────────────────

-- Sales transactions: 3 000 rows spread across 2023–2024
-- FARM_FINGERPRINT provides deterministic pseudo-random distribution.
CREATE OR REPLACE TABLE `olap.Sales` AS
WITH
  stores_arr AS (SELECT ['S01','S02','S03','S04','S05','S06','S07','S08'] AS arr),
  models_arr AS (SELECT ['M01','M02','M03','M04','M05','M06','M07','M08'] AS arr)
SELECT
    (SELECT arr[SAFE_OFFSET(MOD(n, 8))]
     FROM stores_arr)                                                              AS store,
    (SELECT arr[SAFE_OFFSET(MOD(ABS(FARM_FINGERPRINT(CAST(n * 7  AS STRING))), 8))]
     FROM models_arr)                                                              AS model,
    FORMAT_DATE(
        '%Y-%m-%d',
        DATE_ADD(DATE '2023-01-01',
            INTERVAL MOD(ABS(FARM_FINGERPRINT(CAST(n * 3 AS STRING))), 731) DAY)) AS date_sale,
    CAST(1  + MOD(ABS(FARM_FINGERPRINT(CAST(n * 11 AS STRING))), 100)
         AS INT64)                                                                 AS qty,
    ROUND(CAST(50 + MOD(ABS(FARM_FINGERPRINT(CAST(n * 13 AS STRING))), 950)
               AS FLOAT64) * 1.5, 2)                                              AS sum
FROM UNNEST(GENERATE_ARRAY(0, 2999)) AS n;


-- Stock inventory snapshots: 500 rows
CREATE OR REPLACE TABLE `olap.Stock` AS
WITH
  stores_arr AS (SELECT ['S01','S02','S03','S04','S05','S06','S07','S08'] AS arr),
  models_arr AS (SELECT ['M01','M02','M03','M04','M05','M06','M07','M08'] AS arr)
SELECT
    (SELECT arr[SAFE_OFFSET(MOD(n, 8))]
     FROM stores_arr)                                                              AS store,
    (SELECT arr[SAFE_OFFSET(MOD(ABS(FARM_FINGERPRINT(CAST(n * 5  AS STRING))), 8))]
     FROM models_arr)                                                              AS model,
    CAST(10 + MOD(ABS(FARM_FINGERPRINT(CAST(n * 17 AS STRING))), 500)
         AS INT64)                                                                 AS qty
FROM UNNEST(GENERATE_ARRAY(0, 499)) AS n;


-- ─── 3. OLAP cube definition ─────────────────────────────────────────────────
-- XLTable reads cube definitions from the `olap_definition` table.
-- BigQuery triple-quoted strings (""") allow single quotes without escaping.

CREATE OR REPLACE TABLE `olap.olap_definition` AS
SELECT 'myOLAPcube' AS id,
"""
with calendar as (
    SELECT * FROM olap.Times WHERE year_str IN ('2023', '2024')
)

--olap_cube
--olap_calculated_fields Calculated fields
(sales_sum_qty / stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0.00;-#,##0.00`
--olap_jinja
{{ sql_text | replace("salesly.date_sale", "FORMAT_DATE('%Y-%m-%d', DATE_ADD(PARSE_DATE('%Y-%m-%d', salesly.date_sale), INTERVAL 1 YEAR))") }}

--olap_source Sales
SELECT
--olap_measures
 sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`      --format=`#,##0;-#,##0`
,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`        --format=`#,##0.00;-#,##0.00`
FROM olap.Sales sales
LEFT JOIN olap.Stores stores ON sales.store = stores.id
LEFT JOIN olap.Models models ON sales.model = models.id
LEFT JOIN calendar times ON sales.date_sale = times.day_str

--olap_source Sales last year
SELECT
--olap_measures
 sum(salesly.qty) as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
,sum(salesly.sum) as salesly_sum_sum --translation=`Sales last year Amount`   --format=`#,##0.00;-#,##0.00`
FROM olap.Sales salesly
LEFT JOIN olap.Stores stores ON salesly.store = stores.id
LEFT JOIN olap.Models models ON salesly.model = models.id
LEFT JOIN calendar times ON salesly.date_sale = times.day_str

--olap_source Stock
SELECT
--olap_measures
 avg(stock.qty) as stock_avg_qty --translation=`Average Stock Quantity`
FROM olap.Stock stock
LEFT JOIN olap.Stores stores ON stock.store = stores.id
LEFT JOIN olap.Models models ON stock.model = models.id

--olap_source Stores
SELECT
--olap_dimensions
 stores.id as store_id      --translation=`Store ID`
,stores.name as stores_name --translation=`Store`
FROM olap.Stores stores
LEFT JOIN olap.Regions regions ON stores.region = regions.id

--olap_source Regions
SELECT
--olap_dimensions
 regions.name as regions_name --translation=`Region`
FROM olap.Regions regions
LEFT JOIN olap.Managers managers ON regions.id = managers.region --relationship=`many-to-many`

--olap_source Managers
SELECT
--olap_dimensions
 managers.name as managers_name --translation=`Manager`
FROM olap.Managers managers

--olap_source Models
SELECT
--olap_dimensions
 models.name as models_name --translation=`Model`
FROM olap.Models models

--olap_source Dates
SELECT
--olap_dimensions
 times.year_str as times_year_str --hierarchy=`Dates` --translation=`Year`
,FORMAT_DATE('%Y-%m', DATE_TRUNC(DATE(times.day_str), QUARTER)) as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
,times.month_str as times_month_str --hierarchy=`Dates` --translation=`Month`
,times.day_str as times_day_str --hierarchy=`Dates` --translation=`Day`
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
""" AS definition;
