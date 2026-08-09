/*
silver layer tables:
schema  : staging
csv     : csv_raw_transaction
json    : stg_json_sensor
parquet : stg_parquet_order
*/


-- schema : staging 
use schema integrate_db.staging;

-- csv: stg_csv_transaction
create or replace table integrate_db.staging.csv_raw_transaction (
    transaction_id STRING,
    store_id STRING,
    store_name STRING,
    store_city STRING,
    store_region STRING,
    cashier_id STRING,
    customer_id STRING,
    transaction_date DATE,
    transaction_time TIME,
    product_name STRING,
    category STRING,
    subcategory STRING,
    quantity INT,
    unit_price FLOAT,
    discount_pct INT,
    total_amount FLOAT,
    payment_method STRING,
    loyalty_points INT,
    load_ts TIMESTAMP,
    source_file STRING,
    product_sku STRING,
    transaction_ts TIMESTAMP,
    line_total FLOAT,
    processing_time TIMESTAMP
);



-- json: stg_json_sensor
create or replace table integrate_db.staging.stg_json_sensor (
    event_id varchar,
    event_type varchar, 
    store_id varchar,
    store_name varchar,
    event_ts timestamp, 
    device_id varchar, 
    firmware varchar,
    battery_pct int, 
    signal_rssi int,
    store_floor int, 
    sensor_name varchar, 
    sensor_value  float,
    sensor_unit varchar,  
    source_file varchar, 
    processed_ts  timestamp
);



-- parquet : stg_parquet_order
create or replace table integrate_db.staging.stg_parquet_order (
    order_id varchar, 
    order_date timestamp, 
    store_id varchar, 
    store_city varchar, 
    supplier_id varchar,
    supplier_name varchar, 
    supplier_city varchar, 
    product_sku varchar, 
    category varchar,
    quantity_ordered integer,
    quantity_received integer, 
    unit_cost float, 
    total_cost float,
    order_status varchar, 
    expected_delivery date, 
    actual_delivery date, 
    warehouse_id  varchar,
    lead_time_days integer, 
    is_late boolean, 
    file_load_time TIMESTAMP,
    source_file varchar, 
    processed_ts timestamp
);
