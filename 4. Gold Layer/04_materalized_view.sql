-- schema
use schema integrate_db.golden_mart;


-- ============================================================
-- 1) Store Sales Summary MV
-- Purpose : Store-wise sales performance
-- ============================================================

CREATE OR REPLACE MATERIALIZED VIEW integrate_db.golden_mart.mv_store_sales_summary AS
SELECT
    store_key,
    date_key, 
    COUNT(*)              AS total_transactions,
    SUM(quantity)         AS total_quantity_sold,
    SUM(revenue)          AS total_revenue,
    SUM(loyalty_points)   AS total_loyalty_points
FROM integrate_db.golden_mart.fact_daily_sales
GROUP BY store_key, date_key;



-- ============================================================
-- 2) Product Margin Summary MV
-- Purpose : Product-wise profitability analysis
-- ============================================================

CREATE OR REPLACE MATERIALIZED VIEW integrate_db.golden_mart.mv_product_margin_summary AS
SELECT
    product_key,
    supplier_key,
    date_key,
    SUM(quantity_sold)          AS total_quantity_sold,
    SUM(quantity_received)      AS total_quantity_received,
    SUM(sales_revenue)          AS total_sales_revenue,
    SUM(total_cost)             AS total_total_cost,
    SUM(gross_profit)           AS total_gross_profit,
    ROUND(
        CASE
            WHEN SUM(sales_revenue) = 0 THEN 0
            ELSE (SUM(gross_profit) / SUM(sales_revenue)) * 100
        END,
        2
    ) AS gross_margin_percent
FROM integrate_db.golden_mart.fact_gross_margin
GROUP BY product_key, supplier_key, date_key;




-- ============================================================
-- 3) IoT Sensor Summary MV
-- Purpose : Sensor analytics summary by store/date/sensor
-- ============================================================

CREATE OR REPLACE MATERIALIZED VIEW integrate_db.golden_mart.mv_iot_sensor_summary AS
SELECT
    store_key,
    date_key,
    sensor_name,
    sensor_unit,
    COUNT(*)              AS total_sensor_events,
    AVG(sensor_value)     AS avg_sensor_value,
    MIN(sensor_value)     AS min_sensor_value,
    MAX(sensor_value)     AS max_sensor_value,
    AVG(battery_pct)      AS avg_battery_pct
FROM integrate_db.golden_mart.fact_iot_sensor
GROUP BY store_key, date_key, sensor_name, sensor_unit;


