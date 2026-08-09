-- schema
use schema integrate_db.golden_mart;


-- ============================================================
-- 1) Clustering for fact_daily_sales
-- Optimized for store/product/date-based analytics
-- ============================================================

ALTER TABLE integrate_db.golden_mart.fact_daily_sales
CLUSTER BY (date_key, store_key, product_key);



-- ============================================================
-- 2) Clustering for fact_gross_margin
-- Optimized for product/supplier/date-based profitability analysis
-- ============================================================

ALTER TABLE integrate_db.golden_mart.fact_gross_margin
CLUSTER BY (date_key, supplier_key, product_key);



-- ============================================================
-- 3) Clustering for fact_iot_sensor
-- Optimized for date/store/sensor analytics
-- ============================================================

ALTER TABLE integrate_db.golden_mart.fact_iot_sensor
CLUSTER BY (date_key, store_key, sensor_name);