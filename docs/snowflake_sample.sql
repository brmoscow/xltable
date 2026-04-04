-- =============================================================================
-- XLTable OLAP – Snowflake sample data script
-- =============================================================================
-- Creates the `olap` database, all required dimension and fact tables,
-- fills them with deterministic test data, and registers the `myOLAPcube`
-- OLAP cube definition (see reference.html#unified-example).
--
-- Prerequisites:
--   - A Snowflake account with SYSADMIN or equivalent role
--   - A warehouse (e.g. COMPUTE_WH) available
--   - A user with CREATE DATABASE, CREATE TABLE, INSERT privileges
--
-- Usage (SnowSQL CLI):
--   snowsql -a <account> -u <user> -f snowflake_sample.sql
--
-- Usage (Snowflake Worksheets):
--   Paste the script contents into a worksheet and click Run All.
-- =============================================================================


-- ─── 1. Database & schema ────────────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS olap;
USE DATABASE olap;
CREATE SCHEMA IF NOT EXISTS public;
USE SCHEMA public;


-- ─── 2. Dimension tables ─────────────────────────────────────────────────────

-- Calendar: every day of 2023 and 2024 (365 + 366 = 731 rows)
CREATE OR REPLACE TABLE olap.public.Times AS
WITH seq AS (
    SELECT SEQ4() AS n FROM TABLE(GENERATOR(ROWCOUNT => 731))
)
SELECT
    TO_VARCHAR(DATEADD(DAY, n, '2023-01-01'), 'YYYY-MM-DD') AS day_str,
    TO_VARCHAR(DATEADD(DAY, n, '2023-01-01'), 'YYYY-MM')    AS month_str,
    TO_VARCHAR(DATEADD(DAY, n, '2023-01-01'), 'YYYY')       AS year_str
FROM seq;


-- Sales regions (4 rows)
CREATE OR REPLACE TABLE olap.public.Regions AS
SELECT * FROM VALUES
    ('R1', 'North'),
    ('R2', 'South'),
    ('R3', 'East'),
    ('R4', 'West')
AS t(id, name);


-- Sales managers – many-to-many with Regions (5 rows)
CREATE OR REPLACE TABLE olap.public.Managers AS
SELECT * FROM VALUES
    ('Alice Johnson', 'R1'),
    ('Bob Smith',     'R2'),
    ('Carol White',   'R3'),
    ('David Brown',   'R4'),
    ('Emma Davis',    'R1')
AS t(name, region);


-- Retail stores, each in one region (8 rows)
CREATE OR REPLACE TABLE olap.public.Stores AS
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
CREATE OR REPLACE TABLE olap.public.Models AS
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
-- HASH() provides deterministic pseudo-random distribution.
CREATE OR REPLACE TABLE olap.public.Sales AS
WITH seq AS (
    SELECT SEQ4() AS n FROM TABLE(GENERATOR(ROWCOUNT => 3000))
)
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                                          AS store,
    CASE MOD(ABS(HASH(n * 7)), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                                          AS model,
    TO_VARCHAR(
        DATEADD(DAY, MOD(ABS(HASH(n * 3)), 731), '2023-01-01'),
        'YYYY-MM-DD')                                                            AS date_sale,
    CAST(1  + MOD(ABS(HASH(n * 11)), 100) AS INTEGER)                           AS qty,
    ROUND(CAST(50 + MOD(ABS(HASH(n * 13)), 950) AS FLOAT) * 1.5, 2)            AS sum
FROM seq;


-- Stock inventory snapshots: 500 rows
CREATE OR REPLACE TABLE olap.public.Stock AS
WITH seq AS (
    SELECT SEQ4() AS n FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                                          AS store,
    CASE MOD(ABS(HASH(n * 5)), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                                          AS model,
    CAST(10 + MOD(ABS(HASH(n * 17)), 500) AS INTEGER)                           AS qty
FROM seq;


-- ─── 4. OLAP cube definition ─────────────────────────────────────────────────
-- XLTable reads cube definitions from the `olap_definition` table.
-- Snowflake dollar-quoting ($$) allows single quotes without escaping.

CREATE OR REPLACE TABLE olap.public.olap_definition AS
SELECT 'myOLAPcube' AS id,
$$
with calendar as (
    SELECT * FROM olap.public.Times WHERE year_str IN ('2023', '2024')
)

--olap_cube
--olap_calculated_fields Calculated fields
(sales_sum_qty / stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0.00;-#,##0.00`
--olap_jinja
{{ sql_text | replace("salesly.date_sale", "TO_VARCHAR(DATEADD(YEAR, 1, TO_DATE(salesly.date_sale)), 'YYYY-MM-DD')") }}

--olap_source Sales
SELECT
--olap_measures
 sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`      --format=`#,##0;-#,##0`
,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`        --format=`#,##0.00;-#,##0.00`
FROM olap.public.Sales sales
LEFT JOIN olap.public.Stores stores ON sales.store = stores.id
LEFT JOIN olap.public.Models models ON sales.model = models.id
LEFT JOIN calendar times ON sales.date_sale = times.day_str

--olap_source Sales last year
SELECT
--olap_measures
 sum(salesly.qty) as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
,sum(salesly.sum) as salesly_sum_sum --translation=`Sales last year Amount`   --format=`#,##0.00;-#,##0.00`
FROM olap.public.Sales salesly
LEFT JOIN olap.public.Stores stores ON salesly.store = stores.id
LEFT JOIN olap.public.Models models ON salesly.model = models.id
LEFT JOIN calendar times ON salesly.date_sale = times.day_str

--olap_source Stock
SELECT
--olap_measures
 avg(stock.qty) as stock_avg_qty --translation=`Average Stock Quantity`
FROM olap.public.Stock stock
LEFT JOIN olap.public.Stores stores ON stock.store = stores.id
LEFT JOIN olap.public.Models models ON stock.model = models.id

--olap_source Stores
SELECT
--olap_dimensions
 stores.id as store_id      --translation=`Store ID`
,stores.name as stores_name --translation=`Store`
FROM olap.public.Stores stores
LEFT JOIN olap.public.Regions regions ON stores.region = regions.id

--olap_source Regions
SELECT
--olap_dimensions
 regions.name as regions_name --translation=`Region`
FROM olap.public.Regions regions
LEFT JOIN olap.public.Managers managers ON regions.id = managers.region --relationship=`many-to-many`

--olap_source Managers
SELECT
--olap_dimensions
 managers.name as managers_name --translation=`Manager`
FROM olap.public.Managers managers

--olap_source Models
SELECT
--olap_dimensions
 models.name as models_name --translation=`Model`
FROM olap.public.Models models

--olap_source Dates
SELECT
--olap_dimensions
 times.year_str as times_year_str --hierarchy=`Dates` --translation=`Year`
,TO_VARCHAR(DATE_TRUNC('QUARTER', TO_DATE(times.day_str)), 'YYYY-MM') as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
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
$$ AS definition;
