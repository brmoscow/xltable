-- XLTable example cube (ClickHouse): the unified example from the official docs.
-- Every tag is used once; each source block is a runnable SELECT.
--definition_check_on
with calendar as (
    SELECT * FROM db.Times WHERE year_str IN ('2023', '2024', '2025')
)

--olap_cube
--olap_calculated_fields Calculated fields
(sales_sum_qty / stock_avg_qty) as calc_turnover --translation=`Turnover` --format=`#,##0.00;-#,##0.00`
--olap_jinja
{{ sql_text | replace("salesly.date_sale", "toString(toDate(salesly.date_sale) + INTERVAL 1 YEAR)") }}

--olap_source Sales
SELECT
--olap_measures
 sum(sales.qty) as sales_sum_qty --translation=`Sales Quantity`      --format=`#,##0;-#,##0`         --description=`Units sold, pcs`     --synonyms=`quantity;units;pieces`
,sum(sales.sum) as sales_sum_sum --translation=`Sales Amount`        --format=`#,##0.00;-#,##0.00`    --description=`Revenue, currency units` --synonyms=`revenue;turnover;sales`
FROM db.Sales sales
LEFT JOIN db.Stores stores ON sales.store = stores.id
LEFT JOIN db.Models models ON sales.model = models.id
LEFT JOIN calendar times ON sales.date_sale = times.day_str
--olap_drillthrough
stores_name, regions_name, models_name, times_day_str, sales_sum_qty, sales_sum_sum

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
,stores.name as stores_name --translation=`Store` --description=`Retail store the sale belongs to` --synonyms=`shop;outlet;point of sale`
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

--olap_description
Sales fact cube, one row per sale line, with stock levels alongside.

Answers questions about sales quantity and amount, and average stock, by
store, region, manager, model and date (2023-2025).
--olap_ai_instructions
Compare years only over completed months.
Turnover is Sales Quantity divided by Average Stock Quantity - use the
calculated field instead of dividing the two measures yourself.
