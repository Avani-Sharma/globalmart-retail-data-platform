-- schema
use schema integrate_db.staging;
 

-- ============================================================
-- 1) GOLD DIMENSIONS TASK
-- Purpose : Refresh all dimension tables (Star Schema) after
--           new CSV + Parquet data lands in Silver.
-- Runs    : after task_load_csv_data, task_load_parquet_data
-- ============================================================

create or replace task integrate_db.staging.task_gold_dimensions
    warehouse = compute_wh
    after integrate_db.staging.task_load_csv_data, integrate_db.staging.task_load_parquet_data
as
begin

    -- ---------------------------------------------
    -- Store Dimension
    -- ---------------------------------------------
    MERGE INTO integrate_db.golden_mart.dim_store tgt
    USING (SELECT DISTINCT store_id, store_name, store_city, store_region
           FROM integrate_db.staging.csv_raw_transaction WHERE store_id IS NOT NULL) src
    ON tgt.store_id = src.store_id
    WHEN MATCHED THEN UPDATE SET tgt.store_name=src.store_name, tgt.store_city=src.store_city, tgt.store_region=src.store_region
    WHEN NOT MATCHED THEN INSERT (store_id, store_name, store_city, store_region)
    VALUES (src.store_id, src.store_name, src.store_city, src.store_region);


    -- ---------------------------------------------
    -- Product Dimension
    -- ---------------------------------------------
    MERGE INTO integrate_db.golden_mart.dim_product tgt
    USING (
        SELECT product_sku, product_name, category, subcategory
        FROM (
            SELECT product_sku, product_name, category, subcategory,
                   ROW_NUMBER() OVER (
                       PARTITION BY product_sku
                       ORDER BY load_ts DESC
                   ) AS rn
            FROM integrate_db.staging.csv_raw_transaction
            WHERE product_sku IS NOT NULL
        )
        WHERE rn = 1
    ) src
    ON tgt.product_sku = src.product_sku
    WHEN MATCHED THEN UPDATE SET tgt.product_name=src.product_name, tgt.category=src.category, tgt.subcategory=src.subcategory
    WHEN NOT MATCHED THEN INSERT (product_sku, product_name, category, subcategory)
    VALUES (src.product_sku, src.product_name, src.category, src.subcategory);


    -- ---------------------------------------------
    -- Supplier Dimension
    -- ---------------------------------------------
    MERGE INTO integrate_db.golden_mart.dim_supplier tgt
    USING (SELECT DISTINCT supplier_id, supplier_name, supplier_city
           FROM integrate_db.staging.stg_parquet_order WHERE supplier_id IS NOT NULL) src
    ON tgt.supplier_id = src.supplier_id
    WHEN MATCHED THEN UPDATE SET tgt.supplier_name=src.supplier_name, tgt.supplier_city=src.supplier_city
    WHEN NOT MATCHED THEN INSERT (supplier_id, supplier_name, supplier_city)
    VALUES (src.supplier_id, src.supplier_name, src.supplier_city);


    -- ---------------------------------------------
    -- Date Dimension
    -- ---------------------------------------------
    MERGE INTO integrate_db.golden_mart.dim_date tgt
    USING (
        SELECT DISTINCT transaction_date,
            YEAR(transaction_date)*10000 + MONTH(transaction_date)*100 + DAY(transaction_date) AS date_key,
            DAY(transaction_date) AS day_number, MONTH(transaction_date) AS month_number,
            MONTHNAME(transaction_date) AS month_name, QUARTER(transaction_date) AS quarter_number,
            YEAR(transaction_date) AS year_number, DAYNAME(transaction_date) AS day_name
        FROM integrate_db.staging.csv_raw_transaction WHERE transaction_date IS NOT NULL) src
    ON tgt.date_key = src.date_key
    WHEN MATCHED THEN UPDATE SET tgt.transaction_date=src.transaction_date, tgt.day_number=src.day_number,
        tgt.month_number=src.month_number, tgt.month_name=src.month_name, tgt.quarter_number=src.quarter_number,
        tgt.year_number=src.year_number, tgt.day_name=src.day_name
    WHEN NOT MATCHED THEN INSERT (date_key, transaction_date, day_number, month_number, month_name, quarter_number, year_number, day_name)
    VALUES (src.date_key, src.transaction_date, src.day_number, src.month_number, src.month_name, src.quarter_number,     src.year_number, src.day_name);
end;




-- ============================================================
-- 2) GOLD FACTS TASK
-- Purpose : Refresh all fact tables after dimensions are updated
--           and after sensor (JSON) data has landed in Silver.
-- Runs    : after task_gold_dimensions, task_load_sensor_data
-- Note    : Uses MERGE (not plain INSERT INTO SELECT) so re-runs
--           do not create duplicate rows.
-- ============================================================

create or replace task integrate_db.staging.task_gold_facts
    warehouse = compute_wh
    after integrate_db.staging.task_gold_dimensions, integrate_db.staging.task_load_sensor_data
as
begin
    -- fact_daily_sales : csv_raw_transaction joined with dims
    MERGE INTO integrate_db.golden_mart.fact_daily_sales tgt
    USING (
        SELECT s.transaction_id, d.date_key, st.store_key, p.product_key, s.quantity, s.unit_price,
               s.discount_pct, s.line_total AS revenue, s.loyalty_points, s.payment_method,
               s.transaction_ts, s.source_file, CURRENT_TIMESTAMP() AS processing_time
        FROM integrate_db.staging.csv_raw_transaction s
        INNER JOIN integrate_db.golden_mart.dim_date d ON s.transaction_date = d.transaction_date
        INNER JOIN integrate_db.golden_mart.dim_store st ON s.store_id = st.store_id
        INNER JOIN integrate_db.golden_mart.dim_product p ON s.product_sku = p.product_sku
    ) src
    ON tgt.transaction_id = src.transaction_id
    WHEN NOT MATCHED THEN INSERT (transaction_id, date_key, store_key, product_key, quantity, unit_price,
        discount_pct, revenue, loyalty_points, payment_method, transaction_ts, source_file, processing_time)
    VALUES (src.transaction_id, src.date_key, src.store_key, src.product_key, src.quantity, src.unit_price,
        src.discount_pct, src.revenue, src.loyalty_points, src.payment_method, src.transaction_ts, src.source_file, src.processing_time);

    -- fact_gross_margin : sales (csv) + purchase cost (parquet) joined with dims
    MERGE INTO integrate_db.golden_mart.fact_gross_margin tgt
    USING (
        SELECT s.transaction_id, e.order_id, d.date_key, st.store_key, p.product_key, sup.supplier_key,
               s.quantity AS quantity_sold, e.quantity_received, s.line_total AS sales_revenue, e.total_cost,
               (s.line_total - e.total_cost) AS gross_profit,
               CASE WHEN s.line_total = 0 THEN 0 ELSE ROUND(((s.line_total - e.total_cost)/s.line_total)*100,2) END AS gross_margin_percent,
               s.source_file, CURRENT_TIMESTAMP() AS processing_time
        FROM integrate_db.staging.csv_raw_transaction s
        INNER JOIN integrate_db.staging.stg_parquet_order e ON s.store_id = e.store_id AND s.product_sku = e.product_sku
        INNER JOIN integrate_db.golden_mart.dim_date d ON s.transaction_date = d.transaction_date
        INNER JOIN integrate_db.golden_mart.dim_store st ON s.store_id = st.store_id
        INNER JOIN integrate_db.golden_mart.dim_product p ON s.product_sku = p.product_sku
        INNER JOIN integrate_db.golden_mart.dim_supplier sup ON e.supplier_id = sup.supplier_id
    ) src
    ON tgt.transaction_id = src.transaction_id AND tgt.order_id = src.order_id
    WHEN NOT MATCHED THEN INSERT (transaction_id, order_id, date_key, store_key, product_key, supplier_key,
        quantity_sold, quantity_received, sales_revenue, total_cost, gross_profit, gross_margin_percent, source_file, processing_time)
    VALUES (src.transaction_id, src.order_id, src.date_key, src.store_key, src.product_key, src.supplier_key,
        src.quantity_sold, src.quantity_received, src.sales_revenue, src.total_cost, src.gross_profit, src.gross_margin_percent, src.source_file, src.processing_time);

    -- fact_iot_sensor : sensor events joined with dims
    MERGE INTO integrate_db.golden_mart.fact_iot_sensor tgt
    USING (
        SELECT j.event_id, j.sensor_name, d.date_key, st.store_key, j.sensor_value, j.sensor_unit,
               j.battery_pct, j.event_ts, j.source_file, CURRENT_TIMESTAMP() AS processing_time
        FROM integrate_db.staging.stg_json_sensor j
        INNER JOIN integrate_db.golden_mart.dim_date d ON CAST(j.event_ts AS DATE) = d.transaction_date
        INNER JOIN integrate_db.golden_mart.dim_store st ON j.store_id = st.store_id
    ) src
    ON tgt.event_id = src.event_id AND tgt.sensor_name = src.sensor_name
    WHEN NOT MATCHED THEN INSERT (event_id, date_key, store_key, sensor_name, sensor_value, sensor_unit,
        battery_pct, event_ts, source_file, processing_time)
    VALUES (src.event_id, src.date_key, src.store_key, src.sensor_name, src.sensor_value, src.sensor_unit,
        src.battery_pct, src.event_ts, src.source_file, src.processing_time);
end;

