-- =============================================================================
-- XLTable OLAP – Trino sample data script
-- =============================================================================
-- Creates the `db` schema in your Trino catalog, all required dimension and
-- fact tables, fills them with ~3 500 rows of deterministic test data, and
-- registers the `myOLAPcube` OLAP cube definition
-- (see reference.html#unified-example).
--
-- IMPORTANT: Replace `hive` throughout this script with the name of your
--            actual Trino catalog (e.g. iceberg, delta, memory).
--            Quick search-and-replace:  hive.db  →  <your_catalog>.db
--
-- Prerequisites:
--   - Trino cluster reachable from your workstation
--   - A catalog configured in Trino (e.g. hive, iceberg, delta)
--   - A Trino user with CREATE SCHEMA, CREATE TABLE, INSERT privileges
--
-- Usage (Trino CLI with TLS):
--   trino --server https://<host>:8443 \
--         --user <user> --password \
--         --file trino_sample.sql
--
-- Usage (Trino CLI without TLS):
--   trino --server http://<host>:8080 \
--         --user <user> \
--         --file trino_sample.sql
-- =============================================================================


-- ─── 1. Schema ───────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS hive.db;


-- ─── 2. Drop existing tables (safe re-run) ───────────────────────────────────

DROP TABLE IF EXISTS hive.db.olap_definition;
DROP TABLE IF EXISTS hive.db.Sales;
DROP TABLE IF EXISTS hive.db.Stock;
DROP TABLE IF EXISTS hive.db.Managers;
DROP TABLE IF EXISTS hive.db.Stores;
DROP TABLE IF EXISTS hive.db.Regions;
DROP TABLE IF EXISTS hive.db.Models;
DROP TABLE IF EXISTS hive.db.Times;


-- ─── 3. Dimension tables ─────────────────────────────────────────────────────

-- Calendar: every day of 2023 and 2024 (365 + 366 = 731 rows)
CREATE TABLE hive.db.Times (
    day_str   VARCHAR,
    month_str VARCHAR,
    year_str  VARCHAR
);

INSERT INTO hive.db.Times
SELECT
    date_format(date_add('day', n, date '2023-01-01'), '%Y-%m-%d') AS day_str,
    date_format(date_add('day', n, date '2023-01-01'), '%Y-%m')    AS month_str,
    date_format(date_add('day', n, date '2023-01-01'), '%Y')       AS year_str
FROM UNNEST(SEQUENCE(0, 730)) AS t(n);


-- Sales regions (4 rows)
CREATE TABLE hive.db.Regions (
    id   VARCHAR,
    name VARCHAR
);

INSERT INTO hive.db.Regions VALUES
    ('R1', 'North'),
    ('R2', 'South'),
    ('R3', 'East'),
    ('R4', 'West');


-- Sales managers – many-to-many with Regions (5 rows)
CREATE TABLE hive.db.Managers (
    name   VARCHAR,
    region VARCHAR
);

INSERT INTO hive.db.Managers VALUES
    ('Alice Johnson', 'R1'),
    ('Bob Smith',     'R2'),
    ('Carol White',   'R3'),
    ('David Brown',   'R4'),
    ('Emma Davis',    'R1');


-- Retail stores, each in one region (8 rows)
CREATE TABLE hive.db.Stores (
    id     VARCHAR,
    name   VARCHAR,
    region VARCHAR
);

INSERT INTO hive.db.Stores VALUES
    ('S01', 'Downtown North', 'R1'),
    ('S02', 'Uptown North',   'R1'),
    ('S03', 'South Market',   'R2'),
    ('S04', 'South Center',   'R2'),
    ('S05', 'East Plaza',     'R3'),
    ('S06', 'East Mall',      'R3'),
    ('S07', 'West Gate',      'R4'),
    ('S08', 'West Park',      'R4');


-- Product catalogue (8 rows)
CREATE TABLE hive.db.Models (
    id   VARCHAR,
    name VARCHAR
);

INSERT INTO hive.db.Models VALUES
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
-- xxhash64 provides deterministic pseudo-random distribution.
CREATE TABLE hive.db.Sales (
    store     VARCHAR,
    model     VARCHAR,
    date_sale VARCHAR,
    qty       INTEGER,
    amount    DOUBLE
);

INSERT INTO hive.db.Sales
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                                             AS store,
    CASE MOD(ABS(from_big_endian_64(xxhash64(to_utf8(CAST(n * 7  AS VARCHAR))))), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                                             AS model,
    date_format(
        date_add('day',
            MOD(ABS(from_big_endian_64(xxhash64(to_utf8(CAST(n * 3  AS VARCHAR))))), 731),
            date '2023-01-01'),
        '%Y-%m-%d')                                                                 AS date_sale,
    CAST(1  + MOD(ABS(from_big_endian_64(xxhash64(to_utf8(CAST(n * 11 AS VARCHAR))))), 100) AS INTEGER)     AS qty,
    ROUND(CAST(50 + MOD(ABS(from_big_endian_64(xxhash64(to_utf8(CAST(n * 13 AS VARCHAR))))), 950) AS DOUBLE) * 1.5, 2) AS amount
FROM UNNEST(SEQUENCE(0, 2999)) AS t(n);


-- Stock inventory snapshots: 500 rows
CREATE TABLE hive.db.Stock (
    store VARCHAR,
    model VARCHAR,
    qty   INTEGER
);

INSERT INTO hive.db.Stock
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END                                                                             AS store,
    CASE MOD(ABS(from_big_endian_64(xxhash64(to_utf8(CAST(n * 5  AS VARCHAR))))), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END                                                                             AS model,
    CAST(10 + MOD(ABS(from_big_endian_64(xxhash64(to_utf8(CAST(n * 17 AS VARCHAR))))), 500) AS INTEGER) AS qty
FROM UNNEST(SEQUENCE(0, 499)) AS t(n);


-- ─── 5. OLAP cube definition ─────────────────────────────────────────────────
-- XLTable reads cube definitions from the `olap_definition` table.
-- Single quotes inside the definition string are escaped by doubling them ('').

CREATE TABLE hive.db.olap_definition (
    id         VARCHAR,
    definition VARCHAR
);

INSERT INTO hive.db.olap_definition VALUES (
'myOLAPcube',
'
with calendar as (
    SELECT * FROM hive.db.Times WHERE year_str IN (''2023'', ''2024'')
)

--olap_cube
--olap_calculated_fields Calculated fields
(sales_sum_qty / stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0.00;-#,##0.00`
--olap_jinja
{{ sql_text | replace("salesly.date_sale", "date_format(date_add(''year'', 1, date(salesly.date_sale)), ''%Y-%m-%d'')") }}

--olap_source Sales
SELECT
--olap_measures
 sum(sales.qty)    as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`
,sum(sales.amount) as sales_sum_sum --translation=`Sales Amount`   --format=`#,##0.00;-#,##0.00`
FROM hive.db.Sales sales
LEFT JOIN hive.db.Stores stores ON sales.store = stores.id
LEFT JOIN hive.db.Models models ON sales.model = models.id
LEFT JOIN calendar times ON sales.date_sale = times.day_str

--olap_source Sales last year
SELECT
--olap_measures
 sum(salesly.qty)    as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
,sum(salesly.amount) as salesly_sum_sum --translation=`Sales last year Amount`   --format=`#,##0.00;-#,##0.00`
FROM hive.db.Sales salesly
LEFT JOIN hive.db.Stores stores ON salesly.store = stores.id
LEFT JOIN hive.db.Models models ON salesly.model = models.id
LEFT JOIN calendar times ON salesly.date_sale = times.day_str

--olap_source Stock
SELECT
--olap_measures
 avg(stock.qty) as stock_avg_qty --translation=`Average Stock Quantity`
FROM hive.db.Stock stock
LEFT JOIN hive.db.Stores stores ON stock.store = stores.id
LEFT JOIN hive.db.Models models ON stock.model = models.id

--olap_source Stores
SELECT
--olap_dimensions
 stores.id   as store_id    --translation=`Store ID`
,stores.name as stores_name --translation=`Store`
FROM hive.db.Stores stores
LEFT JOIN hive.db.Regions regions ON stores.region = regions.id

--olap_source Regions
SELECT
--olap_dimensions
 regions.name as regions_name --translation=`Region`
FROM hive.db.Regions regions
LEFT JOIN hive.db.Managers managers ON regions.id = managers.region --relationship=`many-to-many`

--olap_source Managers
SELECT
--olap_dimensions
 managers.name as managers_name --translation=`Manager`
FROM hive.db.Managers managers

--olap_source Models
SELECT
--olap_dimensions
 models.name as models_name --translation=`Model`
FROM hive.db.Models models

--olap_source Dates
SELECT
--olap_dimensions
 times.year_str as times_year_str --hierarchy=`Dates` --translation=`Year`
,date_format(date_trunc(''quarter'', date(times.day_str)), ''%Y-%m'') as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
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
