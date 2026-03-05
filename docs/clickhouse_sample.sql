-- =============================================================================
-- XLTable OLAP – ClickHouse sample data script
-- =============================================================================
-- Creates the `db` database, all required dimension and fact tables,
-- fills them with ~3 500 rows of deterministic test data, and registers
-- the `myOLAPcube` OLAP cube definition (see reference.html#unified-example).
--
-- Usage (clickhouse-client):
--   clickhouse-client \
--     --host     <host> \
--     --port     9440  \
--     --secure         \
--     --user     <user>     \
--     --password <password> \
--     --multiline --multiquery \
--     < clickhouse_sample.sql
--
-- Usage (HTTP / curl):
--   curl "https://<host>:8443/" \
--     --user "<user>:<password>" \
--     --data-binary @clickhouse_sample.sql
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

-- Calendar: every day of 2023 and 2024 (365 + 366 = 731 rows)
CREATE TABLE db.Times
(
    day_str   String,   -- 'YYYY-MM-DD'
    month_str String,   -- 'YYYY-MM'
    year_str  String    -- 'YYYY'
) ENGINE = MergeTree() ORDER BY day_str;

INSERT INTO db.Times
SELECT
    formatDateTime(toDate('2023-01-01') + toUInt32(number), '%Y-%m-%d') AS day_str,
    formatDateTime(toDate('2023-01-01') + toUInt32(number), '%Y-%m')    AS month_str,
    formatDateTime(toDate('2023-01-01') + toUInt32(number), '%Y')       AS year_str
FROM numbers(731);


-- Sales regions (4 rows)
CREATE TABLE db.Regions
(
    id   String,
    name String
) ENGINE = MergeTree() ORDER BY id;

INSERT INTO db.Regions VALUES
    ('R1', 'North'),
    ('R2', 'South'),
    ('R3', 'East'),
    ('R4', 'West');


-- Sales managers – many-to-many with Regions (5 rows)
CREATE TABLE db.Managers
(
    name   String,
    region String    -- references db.Regions.id
) ENGINE = MergeTree() ORDER BY name;

INSERT INTO db.Managers VALUES
    ('Alice Johnson', 'R1'),
    ('Bob Smith',     'R2'),
    ('Carol White',   'R3'),
    ('David Brown',   'R4'),
    ('Emma Davis',    'R1');


-- Retail stores, each in one region (8 rows)
CREATE TABLE db.Stores
(
    id     String,
    name   String,
    region String    -- references db.Regions.id
) ENGINE = MergeTree() ORDER BY id;

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
CREATE TABLE db.Models
(
    id   String,
    name String
) ENGINE = MergeTree() ORDER BY id;

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
CREATE TABLE db.Sales
(
    store     String,    -- references db.Stores.id
    model     String,    -- references db.Models.id
    date_sale String,    -- references db.Times.day_str  (YYYY-MM-DD)
    qty       UInt32,
    sum       Float64
) ENGINE = MergeTree() ORDER BY (date_sale, store, model);

INSERT INTO db.Sales
SELECT
    ['S01','S02','S03','S04','S05','S06','S07','S08']
        [1 + number % 8]                                         AS store,
    ['M01','M02','M03','M04','M05','M06','M07','M08']
        [1 + intHash32(number * 7) % 8]                          AS model,
    formatDateTime(
        toDate('2023-01-01') + toUInt32(intHash32(number * 3) % 731),
        '%Y-%m-%d')                                              AS date_sale,
    1  + intHash32(number * 11) % 100                            AS qty,
    round((50 + intHash32(number * 13) % 950) * 1.5, 2)         AS sum
FROM numbers(3000);


-- Stock inventory snapshots: 500 rows
CREATE TABLE db.Stock
(
    store String,    -- references db.Stores.id
    model String,    -- references db.Models.id
    qty   UInt32
) ENGINE = MergeTree() ORDER BY (store, model);

INSERT INTO db.Stock
SELECT
    ['S01','S02','S03','S04','S05','S06','S07','S08']
        [1 + number % 8]                                         AS store,
    ['M01','M02','M03','M04','M05','M06','M07','M08']
        [1 + intHash32(number * 5) % 8]                          AS model,
    10 + intHash32(number * 17) % 500                            AS qty
FROM numbers(500);


-- ─── 5. OLAP cube definition ─────────────────────────────────────────────────
-- XLTable reads cube definitions from the `olap_definition` table.
-- The string value of the `definition` column follows the XLTable SQL tag syntax.
-- Single quotes inside the definition string are escaped by doubling them ('').

CREATE OR REPLACE TABLE db.olap_definition
ENGINE = MergeTree() ORDER BY id AS

SELECT 'myOLAPcube' AS id,
'
with calendar as (
    SELECT * FROM db.Times WHERE year_str IN (''2023'', ''2024'')
)

--olap_cube
--olap_calculated_fields Calculated fields
(sales_sum_qty / stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0.00;-#,##0.00`
--olap_jinja
{{ sql_text | replace("salesly.date_sale", "toString(toDate(salesly.date_sale) - INTERVAL 1 YEAR)") }}

--olap_source Sales
SELECT
--olap_measures
 sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`      --format=`#,##0;-#,##0`
,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`        --format=`#,##0.00;-#,##0.00`
FROM db.Sales sales
LEFT JOIN db.Stores stores ON sales.store = stores.id
LEFT JOIN db.Models models ON sales.model = models.id
LEFT JOIN calendar times ON sales.date_sale = times.day_str

--olap_source Sales last year
SELECT
--olap_measures
 sum(salesly.qty) as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
,sum(salesly.sum) as salesly_sum_sum --translation=`Sales last year Amount`   --format=`#,##0.00;-#,##0.00`
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
 stores.id as store_id    --translation=`Store ID`
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
,toQuarter(toDate(times.day_str)) as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
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
' AS definition;
