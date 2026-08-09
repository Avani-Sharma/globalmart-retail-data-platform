-- schema
use schema integrate_db.golden_mart;


-- ============================================================
-- 1. Daily Sales Fact Table
-- Load fact_daily_sales
-- Source : csv_raw_transaction
-- Join   : dim_date + dim_store + dim_product
-- ============================================================

CREATE OR REPLACE TABLE integrate_db.golden_mart.fact_daily_sales (
    sales_key         NUMBER AUTOINCREMENT PRIMARY KEY,
    transaction_id    STRING,
    date_key          NUMBER,
    store_key         NUMBER,
    product_key       NUMBER,
    quantity          NUMBER,
    unit_price        FLOAT,
    discount_pct      FLOAT,
    revenue           FLOAT,
    loyalty_points    NUMBER,
    payment_method    STRING,
    transaction_ts    TIMESTAMP,
    source_file       STRING,
    processing_time   TIMESTAMP
);


INSERT INTO integrate_db.golden_mart.fact_daily_sales (
    transaction_id,
    date_key,
    store_key,
    product_key,
    quantity,
    unit_price,
    discount_pct,
    revenue,
    loyalty_points,
    payment_method,
    transaction_ts,
    source_file,
    processing_time
)
SELECT
    s.transaction_id,
    d.date_key,
    st.store_key,
    p.product_key,
    s.quantity,
    s.unit_price,
    s.discount_pct,
    s.line_total AS revenue,
    s.loyalty_points,
    s.payment_method,
    s.transaction_ts,
    s.source_file,
    CURRENT_TIMESTAMP() AS processing_time
FROM integrate_db.staging.csv_raw_transaction s
INNER JOIN integrate_db.golden_mart.dim_date d
    ON s.transaction_date = d.transaction_date
INNER JOIN integrate_db.golden_mart.dim_store st
    ON s.store_id = st.store_id
INNER JOIN integrate_db.golden_mart.dim_product p
    ON s.product_sku = p.product_sku;




-- ============================================================
-- 2. Gross Margin Fact Table
-- Load fact_gross_margin
-- Source : csv_raw_transaction + stg_parquet_order
-- Join   : dim_date + dim_store + dim_product + dim_supplier
-- Logic  : Sales revenue - ERP total cost
-- ============================================================

CREATE OR REPLACE TABLE integrate_db.golden_mart.fact_gross_margin (
    margin_key             NUMBER AUTOINCREMENT PRIMARY KEY,
    transaction_id         STRING,
    order_id               STRING,
    date_key               NUMBER,
    store_key              NUMBER,
    product_key            NUMBER,
    supplier_key           NUMBER,
    quantity_sold          NUMBER,
    quantity_received      NUMBER,
    sales_revenue          FLOAT,
    total_cost             FLOAT,
    gross_profit           FLOAT,
    gross_margin_percent   FLOAT,
    source_file            STRING,
    processing_time        TIMESTAMP
);


INSERT INTO integrate_db.golden_mart.fact_gross_margin (
    transaction_id,
    order_id,
    date_key,
    store_key,
    product_key,
    supplier_key,
    quantity_sold,
    quantity_received,
    sales_revenue,
    total_cost,
    gross_profit,
    gross_margin_percent,
    source_file,
    processing_time
)
SELECT
    s.transaction_id,
    e.order_id,
    d.date_key,
    st.store_key,
    p.product_key,
    sup.supplier_key,
    s.quantity AS quantity_sold,
    e.quantity_received,
    s.line_total AS sales_revenue,
    e.total_cost,
    (s.line_total - e.total_cost) AS gross_profit,
    CASE
        WHEN s.line_total = 0 THEN 0
        ELSE ROUND(((s.line_total - e.total_cost) / s.line_total) * 100, 2)
    END AS gross_margin_percent,
    s.source_file,
    CURRENT_TIMESTAMP() AS processing_time
FROM integrate_db.staging.csv_raw_transaction s
INNER JOIN integrate_db.staging.stg_parquet_order e
    ON s.store_id = e.store_id
   AND s.product_sku = e.product_sku
INNER JOIN integrate_db.golden_mart.dim_date d
    ON s.transaction_date = d.transaction_date
INNER JOIN integrate_db.golden_mart.dim_store st
    ON s.store_id = st.store_id
INNER JOIN integrate_db.golden_mart.dim_product p
    ON s.product_sku = p.product_sku
INNER JOIN integrate_db.golden_mart.dim_supplier sup
    ON e.supplier_id = sup.supplier_id;




-- ============================================================
-- 3. IoT Sensor Fact Table
-- Load fact_iot_sensor
-- Source : stg_json_sensor
-- Join   : dim_date + dim_store
-- ============================================================

CREATE OR REPLACE TABLE integrate_db.golden_mart.fact_iot_sensor (
    sensor_fact_key    NUMBER AUTOINCREMENT PRIMARY KEY,
    event_id           STRING,
    date_key           NUMBER,
    store_key          NUMBER,
    sensor_name        STRING,
    sensor_value       FLOAT,
    sensor_unit        STRING,
    battery_pct        NUMBER,
    event_ts           TIMESTAMP,
    source_file        STRING,
    processing_time    TIMESTAMP
);


INSERT INTO integrate_db.golden_mart.fact_iot_sensor (
    event_id,
    date_key,
    store_key,
    sensor_name,
    sensor_value,
    sensor_unit,
    battery_pct,
    event_ts,
    source_file,
    processing_time
)
SELECT
    j.event_id,
    d.date_key,
    st.store_key,
    j.sensor_name,
    j.sensor_value,
    j.sensor_unit,
    j.battery_pct,
    j.event_ts,
    j.source_file,
    CURRENT_TIMESTAMP() AS processing_time
FROM integrate_db.staging.stg_json_sensor j
INNER JOIN integrate_db.golden_mart.dim_date d
    ON CAST(j.event_ts AS DATE) = d.transaction_date
INNER JOIN integrate_db.golden_mart.dim_store st
    ON j.store_id = st.store_id;
