-- =============================================================================
-- XLTable OLAP – Greenplum sample data script
-- =============================================================================
-- Creates the `db` schema inside your Greenplum database, all required
-- dimension and fact tables, fills them with ~3 500 rows of deterministic
-- test data, and registers the `myOLAPcube` OLAP cube definition
-- (see reference.html#unified-example).
--
-- IMPORTANT: Replace `db.` throughout this script with your own schema name
--            if needed.  Quick search-and-replace:  db.  →  <your_schema>.
--
-- Prerequisites:
--   - Greenplum instance reachable from your workstation
--   - psql CLI installed (bundled with Greenplum / PostgreSQL client tools)
--   - A Greenplum user with CREATE SCHEMA, CREATE TABLE, INSERT privileges
--
-- Usage (psql with TLS):
--   psql "host=<host> port=5432 dbname=<database> \
--         user=<user> password=<password> sslmode=require" \
--     -f greenplum_sample.sql
--
-- Usage (psql without TLS):
--   psql "host=<host> port=5432 dbname=<database> \
--         user=<user> password=<password>" \
--     -f greenplum_sample.sql
--
-- Usage (connection URL):
--   psql postgresql://<user>:<password>@<host>:5432/<database>?sslmode=require \
--     -f greenplum_sample.sql
-- =============================================================================


-- ─── 1. Schema ───────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS db;


-- ─── 2. Drop existing tables (safe re-run) ───────────────────────────────────

DROP TABLE IF EXISTS db.olap_definition;
DROP TABLE IF EXISTS db.sales;
DROP TABLE IF EXISTS db.stock;
DROP TABLE IF EXISTS db.managers;
DROP TABLE IF EXISTS db.stores;
DROP TABLE IF EXISTS db.regions;
DROP TABLE IF EXISTS db.models;
DROP TABLE IF EXISTS db.times;


-- ─── 3. Dimension tables ─────────────────────────────────────────────────────

-- Calendar: every day of 2023, 2024 and 2025 (365 + 366 + 365 = 1096 rows)
CREATE TABLE db.times (
    day_str   TEXT,
    month_str TEXT,
    year_str  TEXT
);

INSERT INTO db.times
SELECT
    to_char(d, 'YYYY-MM-DD') AS day_str,
    to_char(d, 'YYYY-MM')    AS month_str,
    to_char(d, 'YYYY')       AS year_str
FROM generate_series('2023-01-01'::date, '2025-12-31'::date, '1 day'::interval) AS d;


-- Sales regions (4 rows)
CREATE TABLE db.regions (
    id   TEXT,
    name TEXT
);

INSERT INTO db.regions VALUES
    ('R1', 'North'),
    ('R2', 'South'),
    ('R3', 'East'),
    ('R4', 'West');


-- Sales managers – many-to-many with regions (5 rows)
CREATE TABLE db.managers (
    name   TEXT,
    region TEXT    -- references db.regions.id
);

INSERT INTO db.managers VALUES
    ('Alice Johnson', 'R1'),
    ('Bob Smith',     'R2'),
    ('Carol White',   'R3'),
    ('David Brown',   'R4'),
    ('Emma Davis',    'R1');


-- Retail stores, each in one region (8 rows)
CREATE TABLE db.stores (
    id     TEXT,
    name   TEXT,
    region TEXT    -- references db.regions.id
);

INSERT INTO db.stores VALUES
    ('S01', 'Downtown North', 'R1'),
    ('S02', 'Uptown North',   'R1'),
    ('S03', 'South Market',   'R2'),
    ('S04', 'South Center',   'R2'),
    ('S05', 'East Plaza',     'R3'),
    ('S06', 'East Mall',      'R3'),
    ('S07', 'West Gate',      'R4'),
    ('S08', 'West Park',      'R4');


-- Product catalogue (8 rows)
CREATE TABLE db.models (
    id   TEXT,
    name TEXT
);

INSERT INTO db.models VALUES
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
-- hashtext() provides deterministic pseudo-random distribution.
CREATE TABLE db.sales (
    store     TEXT,
    model     TEXT,
    date_sale TEXT,            -- YYYY-MM-DD, references db.times.day_str
    qty       INTEGER,
    amount    NUMERIC(12, 2)
);

INSERT INTO db.sales
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END AS store,
    CASE MOD(ABS(hashtext(CAST(n * 7  AS TEXT))), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END AS model,
    to_char(
        '2023-01-01'::date
            + (MOD(ABS(hashtext(CAST(n * 3  AS TEXT))), 731) || ' days')::interval,
        'YYYY-MM-DD')                                                       AS date_sale,
    1  + MOD(ABS(hashtext(CAST(n * 11 AS TEXT))), 100)                      AS qty,
    ROUND(CAST(50 + MOD(ABS(hashtext(CAST(n * 13 AS TEXT))), 950) AS NUMERIC) * 1.5, 2) AS amount
FROM generate_series(0, 2999) AS n;


-- Stock inventory snapshots: 500 rows
CREATE TABLE db.stock (
    store TEXT,
    model TEXT,
    qty   INTEGER
);

INSERT INTO db.stock
SELECT
    CASE MOD(n, 8)
        WHEN 0 THEN 'S01' WHEN 1 THEN 'S02' WHEN 2 THEN 'S03' WHEN 3 THEN 'S04'
        WHEN 4 THEN 'S05' WHEN 5 THEN 'S06' WHEN 6 THEN 'S07' ELSE      'S08'
    END AS store,
    CASE MOD(ABS(hashtext(CAST(n * 5  AS TEXT))), 8)
        WHEN 0 THEN 'M01' WHEN 1 THEN 'M02' WHEN 2 THEN 'M03' WHEN 3 THEN 'M04'
        WHEN 4 THEN 'M05' WHEN 5 THEN 'M06' WHEN 6 THEN 'M07' ELSE      'M08'
    END AS model,
    10 + MOD(ABS(hashtext(CAST(n * 17 AS TEXT))), 500)                      AS qty
FROM generate_series(0, 499) AS n;


-- ─── 5. OLAP cube definition ─────────────────────────────────────────────────
-- XLTable reads cube definitions from the `olap_definition` table.
-- Single quotes inside the definition string are escaped by doubling them ('').

CREATE TABLE db.olap_definition (
    id         TEXT,
    definition TEXT
);

INSERT INTO db.olap_definition VALUES (
'myOLAPcube',
'
with calendar as (
    SELECT * FROM db.times WHERE year_str IN (''2023'', ''2024'', ''2025'')
)

--olap_cube
--olap_calculated_fields Calculated fields
(sales_sum_qty / stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0.00;-#,##0.00`
--olap_jinja
{{ sql_text | replace("salesly.date_sale", "(salesly.date_sale::date + INTERVAL ''1 year'')::text") }}

--olap_source Sales
SELECT
--olap_measures
 sum(sales.qty)    as sales_sum_qty --translation=`Sales Quantity` --format=`#,##0;-#,##0`
,sum(sales.amount) as sales_sum_sum --translation=`Sales Amount`   --format=`#,##0.00;-#,##0.00`
FROM db.sales sales
LEFT JOIN db.stores stores ON sales.store = stores.id
LEFT JOIN db.models models ON sales.model = models.id
LEFT JOIN calendar times ON sales.date_sale = times.day_str
--olap_drillthrough
stores_name, regions_name, models_name, times_day_str, sales_sum_qty, sales_sum_sum

--olap_source Sales last year
SELECT
--olap_measures
 sum(salesly.qty)    as salesly_sum_qty --translation=`Sales last year Quantity` --format=`#,##0;-#,##0`
,sum(salesly.amount) as salesly_sum_sum --translation=`Sales last year Amount`   --format=`#,##0.00;-#,##0.00`
FROM db.sales salesly
LEFT JOIN db.stores stores ON salesly.store = stores.id
LEFT JOIN db.models models ON salesly.model = models.id
LEFT JOIN calendar times ON salesly.date_sale = times.day_str

--olap_source Stock
SELECT
--olap_measures
 avg(stock.qty) as stock_avg_qty --translation=`Average Stock Quantity`
FROM db.stock stock
LEFT JOIN db.stores stores ON stock.store = stores.id
LEFT JOIN db.models models ON stock.model = models.id

--olap_source Stores
SELECT
--olap_dimensions
 stores.id   as store_id    --translation=`Store ID`
,stores.name as stores_name --translation=`Store`
FROM db.stores stores
LEFT JOIN db.regions regions ON stores.region = regions.id

--olap_source Regions
SELECT
--olap_dimensions
 regions.name as regions_name --translation=`Region`
FROM db.regions regions
LEFT JOIN db.managers managers ON regions.id = managers.region --relationship=`many-to-many`

--olap_source Managers
SELECT
--olap_dimensions
 managers.name as managers_name --translation=`Manager`
FROM db.managers managers

--olap_source Models
SELECT
--olap_dimensions
 models.name as models_name --translation=`Model`
FROM db.models models

--olap_source Dates
SELECT
--olap_dimensions
 times.year_str  as times_year_str  --hierarchy=`Dates` --translation=`Year`
,to_char(date_trunc(''quarter'', times.day_str::date), ''YYYY-MM'') as times_quarter_str --hierarchy=`Dates` --translation=`Quarter`
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
