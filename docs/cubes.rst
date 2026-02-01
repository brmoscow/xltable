Definition OLAP cubes
=====================
The structure of the OLAP cube is described using SQL queries. 
The OLAP cube is a set of SQL queries that describe the sources, measures, and dimensions of the data.

Create a table in the ClickHouse database and place the OLAP structure there. 
Example:

.. code-block:: sql

   CREATE OR REPLACE TABLE db.olap_definition 
   ENGINE = MergeTree() ORDER BY id AS

   SELECT 'myOLAPcube' AS id,
   '	
      --olap_source Sale
      SELECT
      --olap_measures
       sum(sales.sale_qty) as sale_qty --translation=`Sale Qty` --format=`#,##0;-#,##0`
      ,sum(sales.sale_sum) as sale_sum --translation=`Sale Sum` --format=`#,##0.00;-#,##0.00`
      FROM olap_test.Sales sales
      LEFT JOIN olap_test.Stores stores on sales.store = stores.id
      LEFT JOIN olap_test.Models models on sales.model = models.id
      LEFT JOIN olap_test.Times times on sales.date_sale = times.day_str

      --olap_source Stock
      SELECT
      --olap_measures
       avg(stock.stock_qty) as stock_qty --translation=`Stock Avg Qty` --format=`#,##0;-#,##0`
      FROM olap_test.Stock stock
      LEFT JOIN olap_test.Stores stores on stock.store = stores.id
      LEFT JOIN olap_test.Models models on stock.model = models.id

      --olap_source Stores
      SELECT
      --olap_dimensions
       stores.store_name as store_name --translation=`Store`
      FROM olap_test.Stores stores

      --olap_source SKU
      SELECT
      --olap_dimensions
       models.model_name as model_name --translation=`SKU`
      FROM olap_test.Models models

      --olap_source Dates
      SELECT
      --olap_dimensions
       times.year_str as year_str --hierarchy=`Date` --translation=`Year`
      ,times.month_str as month_str --hierarchy=`Date` --translation=`Month` 
      ,times.day_str as day_str --hierarchy=`Date` --translation=`Day` 
      FROM olap_test.Times times

      --olap_user_role
      --olap_user_groups
      group_name_full_access
      --olap_measures_visible
      all
      --olap_dimensions_visible
      all
      --olap_access_filters

      --olap_user_role
      --olap_user_groups
      group_name_part_access
      --olap_measures_visible
      sale_qty
      --olap_dimensions_visible
      Stores, model_name
      --olap_access_filters
      store_name in (`Store A`)
   ' AS definition

-----------------
Important points:
-----------------
- All field names (exaple: as sale_qty) in tables and their translations (exaple: --translation=`Sale Qty`) must be unique
- All table names (exaple: FROM olap_test.Sales sales) in the OLAP structure must be unique
- The definition field must contain a valid SQL query with the OLAP structure
- The definition field must be a single line, so you need to remove line breaks and indentation from the SQL query

#####################
Connection from Excel
#####################

On the Data tab in Excel, click From Other Sources, and then click From Analysis Services.
Enter the server name in format http://name_or_ip_xltable_server, enter username and password, and then select a cube.
