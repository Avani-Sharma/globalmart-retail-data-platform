-- ============================================================
-- 1) DIMENSION TABLE ROW COUNTS
-- ============================================================

SELECT 'dim_date' AS table_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.dim_date
UNION ALL
SELECT 'dim_store' AS table_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.dim_store
UNION ALL
SELECT 'dim_product' AS table_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.dim_product
UNION ALL
SELECT 'dim_supplier' AS table_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.dim_supplier;




-- ============================================================
-- 2) FACT TABLE ROW COUNTS
-- ============================================================

SELECT 'fact_daily_sales' AS table_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.fact_daily_sales
UNION ALL
SELECT 'fact_gross_margin' AS table_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.fact_gross_margin
UNION ALL
SELECT 'fact_iot_sensor' AS table_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.fact_iot_sensor;





-- ============================================================
-- 3) MATERIALIZED VIEW ROW COUNTS
-- ============================================================

SELECT 'mv_store_sales_summary' AS object_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.mv_store_sales_summary
UNION ALL
SELECT 'mv_product_margin_summary' AS object_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.mv_product_margin_summary
UNION ALL
SELECT 'mv_iot_sensor_summary' AS object_name, COUNT(*) AS row_count
FROM integrate_db.golden_mart.mv_iot_sensor_summary;



-- ============================================================
-- 4) CHECK FOR NULL SURROGATE KEYS IN fact_daily_sales
-- ============================================================

SELECT
    COUNT_IF(date_key IS NULL)    AS null_date_key,
    COUNT_IF(store_key IS NULL)   AS null_store_key,
    COUNT_IF(product_key IS NULL) AS null_product_key
FROM integrate_db.golden_mart.fact_daily_sales;



-- ============================================================
-- 5) CHECK FOR NULL SURROGATE KEYS IN fact_gross_margin
-- ============================================================

SELECT
    COUNT_IF(date_key IS NULL)      AS null_date_key,
    COUNT_IF(store_key IS NULL)     AS null_store_key,
    COUNT_IF(product_key IS NULL)   AS null_product_key,
    COUNT_IF(supplier_key IS NULL)  AS null_supplier_key
FROM integrate_db.golden_mart.fact_gross_margin;



-- ============================================================
-- 6) CHECK FOR NULL SURROGATE KEYS IN fact_iot_sensor
-- ============================================================

SELECT
    COUNT_IF(date_key IS NULL)    AS null_date_key,
    COUNT_IF(store_key IS NULL)   AS null_store_key
FROM integrate_db.golden_mart.fact_iot_sensor;



-- ============================================================
-- 7) DAILY SALES BUSINESS METRICS CHECK
-- ============================================================

SELECT
    COUNT(*)               AS total_sales_rows,
    SUM(quantity)          AS total_quantity_sold,
    SUM(revenue)           AS total_revenue,
    SUM(loyalty_points)    AS total_loyalty_points
FROM integrate_db.golden_mart.fact_daily_sales;



-- ============================================================
-- 8) GROSS MARGIN BUSINESS METRICS CHECK
-- ============================================================

SELECT
    COUNT(*)                     AS total_margin_rows,
    SUM(quantity_sold)           AS total_quantity_sold,
    SUM(quantity_received)       AS total_quantity_received,
    SUM(sales_revenue)           AS total_sales_revenue,
    SUM(total_cost)              AS total_total_cost,
    SUM(gross_profit)            AS total_gross_profit,
    AVG(gross_margin_percent)    AS avg_gross_margin_percent
FROM integrate_db.golden_mart.fact_gross_margin;




-- ============================================================
-- 9) IOT SENSOR BUSINESS METRICS CHECK
-- ============================================================

SELECT
    COUNT(*)               AS total_sensor_rows,
    COUNT(DISTINCT event_id) AS distinct_events,
    AVG(sensor_value)      AS avg_sensor_value,
    AVG(battery_pct)       AS avg_battery_pct
FROM integrate_db.golden_mart.fact_iot_sensor;




-- ============================================================
-- 10) SAMPLE DATA PREVIEW - DIMENSIONS
-- ============================================================

SELECT * FROM integrate_db.golden_mart.dim_date LIMIT 10;
SELECT * FROM integrate_db.golden_mart.dim_store LIMIT 10;
SELECT * FROM integrate_db.golden_mart.dim_product LIMIT 10;
SELECT * FROM integrate_db.golden_mart.dim_supplier LIMIT 10;



-- ============================================================
-- 11) SAMPLE DATA PREVIEW - FACTS
-- ============================================================

SELECT * FROM integrate_db.golden_mart.fact_daily_sales LIMIT 10;
SELECT * FROM integrate_db.golden_mart.fact_gross_margin LIMIT 10;
SELECT * FROM integrate_db.golden_mart.fact_iot_sensor LIMIT 10;



-- ============================================================
-- 12) SAMPLE DATA PREVIEW - MATERIALIZED VIEWS
-- ============================================================

SELECT * FROM integrate_db.golden_mart.mv_store_sales_summary LIMIT 10;
SELECT * FROM integrate_db.golden_mart.mv_product_margin_summary LIMIT 10;
SELECT * FROM integrate_db.golden_mart.mv_iot_sensor_summary LIMIT 10;



-- ============================================================
-- 13) DUPLICATE CHECKS
-- ============================================================

-- Duplicate transaction check in fact_daily_sales
SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM integrate_db.golden_mart.fact_daily_sales
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- Duplicate event check in fact_iot_sensor
SELECT
    event_id,
    sensor_name,
    COUNT(*) AS duplicate_count
FROM integrate_db.golden_mart.fact_iot_sensor
GROUP BY event_id, sensor_name
HAVING COUNT(*) > 1;




-- ============================================================
-- 14) DATE COVERAGE CHECK
-- ============================================================

SELECT
    MIN(transaction_date) AS min_date,
    MAX(transaction_date) AS max_date,
    COUNT(*)              AS total_dates
FROM integrate_db.golden_mart.dim_date;



-- ============================================================
-- 15) FACT-TO-DIMENSION REFERENTIAL CHECKS
-- ============================================================

-- Any sales fact rows whose date_key does not exist in dim_date?
SELECT COUNT(*) AS missing_date_keys_in_sales
FROM integrate_db.golden_mart.fact_daily_sales f
LEFT JOIN integrate_db.golden_mart.dim_date d
    ON f.date_key = d.date_key
WHERE d.date_key IS NULL;


-- Any sales fact rows whose store_key does not exist in dim_store?
SELECT COUNT(*) AS missing_store_keys_in_sales
FROM integrate_db.golden_mart.fact_daily_sales f
LEFT JOIN integrate_db.golden_mart.dim_store s
    ON f.store_key = s.store_key
WHERE s.store_key IS NULL;


-- Any sales fact rows whose product_key does not exist in dim_product?
SELECT COUNT(*) AS missing_product_keys_in_sales
FROM integrate_db.golden_mart.fact_daily_sales f
LEFT JOIN integrate_db.golden_mart.dim_product p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;


-- Any gross margin fact rows whose supplier_key does not exist in dim_supplier?
SELECT COUNT(*) AS missing_supplier_keys_in_margin
FROM integrate_db.golden_mart.fact_gross_margin f
LEFT JOIN integrate_db.golden_mart.dim_supplier s
    ON f.supplier_key = s.supplier_key
WHERE s.supplier_key IS NULL;