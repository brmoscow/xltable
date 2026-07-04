-- =============================================================================
-- XLTable OLAP – StarRocks sample data script
-- =============================================================================
-- Creates the `db` database, all required dimension and fact tables,
-- fills them with ~3 500 rows of deterministic test data, and registers
-- the `myOLAPcube` OLAP cube definition (see reference.html#unified-example).
--
-- Prerequisites:
--   - StarRocks 3.1+ cluster reachable from your workstation
--     (generate_series() requires 3.1; for older versions build the
--      number sequence with a helper table)
--   - A user with CREATE DATABASE, CREATE TABLE, INSERT privileges
--
-- Usage (mysql client, StarRocks FE query port 9030):
--   mysql -h <your_starrocks_host> -P 9030 -u <user> -p < starrocks_sample.sql
--
-- Note: PROPERTIES ("replication_num" = "1") is set for single-node test
--       clusters. Remove it (or set to "3") on production clusters.
-- =============================================================================


-- ─── 1. Database ─────────────────────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS db;


-- ─── 2. Drop existing tables (safe re-run) ───────────────────────────────────

DROP TABLE IF EXISTS db.olap_definition;
DROP TABLE IF EXISTS db.Sales;
DROP TABLE IF EXISTS db.Stock;
DROP TABLE IF EXISTS db.Managers;
DROP TABLE IF EXISTS db.Stores;
DROP TABLE IF EXISTS db.Regions;
DROP TABLE IF EXISTS db.Models;
DROP TABLE IF EXISTS db.Times;


-- ─── 3. Dimension tables ─────────────────────────────────────────────────────

-- Calendar: every day of 2023, 2024 and 2025 (365 + 366 + 365 = 1096 rows)
CREATE TABLE db.Times (
    day_str   VARCHAR(10),
    month_str VARCHAR(7),
    year_str  VARCHAR(4)
)
DUPLICATE KEY(day_str)
DISTRIBUTED BY HASH(day_str) BUCKETS 1
PROPERTIES ("replication_num" = "1");

INSERT INTO db.Times
SELECT
    date_format(date_add('2023-01-01', INTERVAL n DAY), '%Y-%m-%d') AS day_str,
    date_format(date_add('2023-01-01', INTERVAL n DAY), '%Y-%m')    AS month_str,
    date_format(date_add('2023-01-01', INTERVAL n DAY), '%Y')       AS year_str
FROM (SELECT generate_series AS n FROM TABLE(generate_series(0, 1095))) t;


-- Sales regions (4 rows)
CREATE TABLE db.Regions (
    id   VARCHAR(10),
    name VARCHAR(50)
)
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 1
PROPERTIES ("replication_num" = "1");

INSERT INTO db.Regions VALUES
    ('R1', 'North'),
    ('R2', 'South'),
    ('R3', 'East'),
    ('R4', 'West');


-- Sales managers – many-to-many with Regions (5 rows)
CREATE TABLE db.Managers (
    name   VARCHAR(50),
    region VARCHAR(10)
)
DUPLICATE KEY(name)
DISTRIBUTED BY HASH(name) BUCKETS 1
PROPERTIES ("replication_num" = "1");

INSERT INTO db.Managers VALUES
    ('Alice Johnson', 'R1'),
    ('Bob Smith',     'R2'),
    ('Carol White',   'R3'),
    ('David Brown',   'R4'),
    ('Emma Davis',    'R1');


-- Retail stores, each in one region (8 rows)
CREATE TABLE db.Stores (
    id     VARCHAR(10),
    name   VARCHAR(50),
    region VARCHAR(10)
)
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 1
PROPERTIES ("replication_num" = "1");

INSERT INTO db.Stores VALUES
    ('S01', 'Downtown North', 'R1'),
    ('S02', 'Uptown North',   'R1'),
    ('S03', 'South Market',   'R2'),
    ('S04', 'South Center',   'R2'),
    ('S05', 'East Plaza',     'R3'),
    ('S06', 'East Mall',      'R3'),
    ('S07', 'West Gate',      'R4'),
    ('S08', 'West Park',      'R4');


-- Product catalogue (8 rows)
CREATE TABLE db.Models (
    id   VARCHAR(10),
    name VARCHAR(50)
)
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 1
PROPERTIES ("replication_num" = "1");

INSERT INTO db.Models VALUES
    ('M01', 'Product Alpha'),
    ('M02', 'Product Beta'),
    ('M03', 'Product Gamma'),
    ('M04', 'Product Delta'),
    ('M05', 'Product Epsilon'),
    ('M06', 'Product Zeta'),
    ('M07', 'Product Eta'),
    ('M08', 'Product Theta');


-- ─── 4. Fact tables ──────────────────────────────────────────────────────────

-- Sales transactions: 3 000 rows spread across 2023–2024
-- murmur_hash3_32 provides deterministic pseudo-random distribution.
CREATE TABLE db.Sales (
    store     VARCHAR(10),
    model     VARCHAR(10),
    date_sale VARCHAR(10),
    qty       INT,
    amount    DOUBLE
)
DUPLICATE KEY(store)
DISTRIBUTED BY HASH(store) BUCKETS 1
PROPERTIES ("replication_num" = "1");

INSERT INTO db.Sales
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                                      AS store,
    CASE MOD(ABS(murmur_hash3_32(CAST(n * 7 AS VARCHAR))), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                                      AS model,
    date_format(
        date_add('2023-01-01',
            INTERVAL MOD(ABS(murmur_hash3_32(CAST(n * 3 AS VARCHAR))), 731) DAY),
        '%Y-%m-%d')                                                          AS date_sale,
    CAST(1 + MOD(ABS(murmur_hash3_32(CAST(n * 11 AS VARCHAR))), 100) AS INT) AS qty,
    ROUND((50 + MOD(ABS(murmur_hash3_32(CAST(n * 13 AS VARCHAR))), 950)) * 1.5, 2) AS amount
FROM (SELECT generate_series AS n FROM TABLE(generate_series(0, 2999))) t;


-- Stock inventory snapshots: 500 rows
CREATE TABLE db.Stock (
    store VARCHAR(10),
    model VARCHAR(10),
    qty   INT
)
DUPLICATE KEY(store)
DISTRIBUTED BY HASH(store) BUCKETS 1
PROPERTIES ("replication_num" = "1");

INSERT INTO db.Stock
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                                      AS store,
    CASE MOD(ABS(murmur_hash3_32(CAST(n * 5 AS VARCHAR))), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                                      AS model,
    CAST(10 + MOD(ABS(murmur_hash3_32(CAST(n * 17 AS VARCHAR))), 500) AS INT) AS qty
FROM (SELECT generate_series AS n FROM TABLE(generate_series(0, 499))) t;


-- ─── 5. OLAP cube definition ─────────────────────────────────────────────────
-- XLTable reads cube definitions from the `olap_definition` table.
-- Single quotes inside the definition string are escaped by doubling them ('').

CREATE TABLE db.olap_definition (
    id         VARCHAR(100),
    definition STRING
)
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 1
PROPERTIES ("replication_num" = "1");

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
{{ sql_text | replace("salesly.date_sale", "date_format(years_add(CAST(salesly.date_sale AS DATE), 1), ''%Y-%m-%d'')") }}

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
,date_format(date_trunc(''quarter'', CAST(times.day_str AS DATE)), ''%Y-%m'') as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
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
