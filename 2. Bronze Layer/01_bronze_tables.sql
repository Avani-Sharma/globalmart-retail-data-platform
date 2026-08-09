/*
table creation:=
csv     : csv_raw
json    : json_raw
parquet : parquet_raw
*/

-- using database and schema 
use integrate_db.raw;

-- create table : csv_raw
create or replace table integrate_db.raw.csv_raw (
    transaction_id varchar,  
    store_id varchar, 
    store_name varchar, 
    store_city varchar, 
    store_region varchar,
    cashier_id varchar, 
    customer_id varchar, 
    transaction_date date, 
    transaction_time time, 
    product_sku varchar,
    product_name varchar, 
    category varchar, 
    subcategory varchar, 
    quantity int, 
    unit_price float,
    discount_pct float,  
    total_amount  float, 
    payment_method varchar, 
    loyalty_points  int,
    load_ts  timestamp, 
    file_name  string 
);



-- create table : json_raw
create or replace table integrate_db.raw.json_raw (
    event_id varchar, 
    event_type varchar, 
    store_id varchar, 
    store_name varchar,
    event_ts timestamp,
    device_id varchar, 
    raw_payload  variant, 
    load_ts timestamp, 
    source_file varchar    
);



-- create table : parquet_raw
create or replace table integrate_db.raw.parquet_raw (
    order_id varchar, 
    order_date  timestamp, 
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
    warehouse_id varchar,
    lead_time_days integer,
    is_late boolean,  
    load_ts timestamp, 
    source_file varchar
);

