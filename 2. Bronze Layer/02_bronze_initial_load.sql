/*
copy into : Run once manually for the initial load of existing S3 files.
            Future files are loaded automatically by Snowpipe.
*/


-- copy into for csv
copy into integrate_db.raw.csv_raw (
    transaction_id, store_id, store_name, store_city, store_region, cashier_id, customer_id, 
    transaction_date, transaction_time, product_sku, product_name, category, subcategory,
    quantity, unit_price, discount_pct, total_amount, payment_method, loyalty_points,
    load_ts, file_name)
from (
    select
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,  $11, $12, $13, $14, $15,
        $16, $17, $18, $19, current_timestamp(), metadata$filename
    from @integrate_db.raw.s3_csv_stage )
file_format = (format_name = 'integrate_db.raw.format_csv')
on_error   = 'continue';



-- copy into for json 
copy into integrate_db.raw.json_raw (
    event_id, event_type, store_id, store_name,
    event_ts, device_id, raw_payload, load_ts, source_file)
from ( 
select
        $1:event_id::varchar, $1:event_type::varchar, $1:store_id::varchar,
        $1:store_name::varchar, $1:timestamp::timestamp, $1:device_id::varchar,
        $1, current_timestamp(), metadata$filename        
from @integrate_db.raw.s3_json_stage)
file_format = (format_name = 'integrate_db.raw.format_json')
on_error    = 'continue';



-- copy into for parquet 
copy into integrate_db.raw.parquet_raw (
    order_id, order_date, store_id, store_city, supplier_id, supplier_name, supplier_city,
    product_sku, category, quantity_ordered, quantity_received, unit_cost, total_cost,
    order_status, expected_delivery, actual_delivery, warehouse_id, lead_time_days, is_late,
    load_ts, source_file)
from (
select 
       $1:order_id::varchar, 
       $1:order_date::timestamp, 
       $1:store_id::varchar, 
       $1:store_city::varchar,
       $1:supplier_id::varchar, 
       $1:supplier_name::varchar, 
       $1:supplier_city::varchar,
       $1:product_sku::varchar,
       $1:category::varchar, 
       $1:quantity_ordered::number,
       $1:quantity_received::number, 
       $1:unit_cost::float,
       $1:total_cost::float,
       $1:order_status::varchar,
       $1:expected_delivery::date, 
       $1:actual_delivery::date,
       $1:warehouse_id::varchar,
       $1:lead_time_days::number, 
       $1:is_late::boolean, 
       current_timestamp(),
       metadata$filename  from @integrate_db.raw.s3_parquet_stage)
file_format = (format_name = 'integrate_db.raw.format_parquet')
on_error = 'continue';


