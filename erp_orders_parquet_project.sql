/*
database            : integrate_db
schema              : raw
file format         : format_parquet
external stage      : s3_parquet_stage
bronze layer table  : parquet_raw
stream              : parquet_stream
snowpipe            : parquet_pipe
silver layer schema : staging
table               : stg_parquet_order
task                : task_load_parquet_data
*/

-- database  
use integrate_db;

-- schema 
use schema raw;

-- file format parquet
create or replace file format integrate_db.raw.format_parquet
    type = parquet;


-- external stage for parquet files
create or replace stage integrate_db.raw.s3_parquet_stage
    url                 = 's3://avani-project/file_parquet/'
    storage_integration = s3_integrations
    file_format         = (format_name = 'integrate_db.raw.format_parquet');

-- files check 
list @integrate_db.raw.s3_parquet_stage;




--        #############  bronze layer #############  


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





--       ############ stream creation for cdc #########

-- stream
create or replace stream integrate_db.raw.parquet_stream
    on table integrate_db.raw.parquet_raw;

-- stream check
select system$stream_has_data('integrate_db.raw.parquet_stream');
select count(*) from integrate_db.raw.parquet_stream;





-- copy into bronze table from stage
copy into integrate_db.raw.parquet_raw (
    order_id, order_date, store_id, store_city, supplier_id, supplier_name, supplier_city,
    product_sku, category, quantity_ordered, quantity_received, unit_cost, total_cost,
    order_status, expected_delivery, actual_delivery, warehouse_id, lead_time_days, is_late,
    load_ts, source_file)
from (  
select  $1:order_id::varchar,  $1:order_date::timestamp,  $1:store_id::varchar, $1:store_city::varchar,
        $1:supplier_id::varchar, $1:supplier_name::varchar, $1:supplier_city::varchar, $1:product_sku::varchar,
        $1:category::varchar, $1:quantity_ordered::number,  $1:quantity_received::number, $1:unit_cost::float,
        $1:total_cost::float, $1:order_status::varchar, $1:expected_delivery::date, $1:actual_delivery::date,
        $1:warehouse_id::varchar, $1:lead_time_days::number, $1:is_late::boolean, current_timestamp(),    
        metadata$filename  from @integrate_db.raw.s3_parquet_stage)
file_format = (format_name = integrate_db.raw.format_parquet)
on_error    = 'continue';

-- verify bronze
select * from integrate_db.raw.parquet_raw;
select count(*) from integrate_db.raw.parquet_raw;






--      ############# snowpipe #############

-- snowpipe: parquet_pipe
create or replace pipe integrate_db.raw.parquet_pipe
auto_ingest = true  as
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

-- pipe details
desc pipe integrate_db.raw.parquet_pipe;

-- pipe status
select system$pipe_status('integrate_db.raw.parquet_pipe');






--        #############  silver layer  #############

-- schema
create schema if not exists integrate_db.staging;
use schema integrate_db.staging;

-- table
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
    source_file varchar, 
    processed_ts timestamp)
data_retention_time_in_days = 10;

-- insert from stream
insert into integrate_db.staging.stg_parquet_order
select
    order_id, order_date, store_id, store_city, supplier_id, supplier_name, supplier_city,
    product_sku, category, quantity_ordered, quantity_received, unit_cost, total_cost,
    order_status, expected_delivery, actual_delivery, warehouse_id, lead_time_days,
    is_late, source_file, current_timestamp() as processed_ts
from integrate_db.raw.parquet_stream;

-- check data 
select * from integrate_db.staging.stg_parquet_order;

-- ALTER — Retention 10 days se 7 days karo 
alter table integrate_db.staging.stg_parquet_order
set data_retention_time_in_days = 7;






--        ############# merge logic #############

merge into integrate_db.staging.stg_parquet_order as target
using (
    select *, current_timestamp() as processed_ts from integrate_db.raw.parquet_stream
) as source
on target.order_id = source.order_id
-- update (order status change hua)
when matched then update set
    target.order_status      = source.order_status,
    target.quantity_received = source.quantity_received,
    target.actual_delivery   = source.actual_delivery,
    target.is_late           = source.is_late,
    target.processed_ts      = source.processed_ts
-- new order insert
when not matched
    and source.metadata$action   = 'INSERT'
    and source.metadata$isupdate = false   then insert 
   ( order_id, order_date, store_id, store_city,
    supplier_id, supplier_name, supplier_city,
    product_sku, category,
    quantity_ordered, quantity_received,
    unit_cost, total_cost,
    order_status, expected_delivery, actual_delivery,
    warehouse_id, lead_time_days, is_late,
    source_file, processed_ts 
) values (
    source.order_id, source.order_date, source.store_id, source.store_city,
    source.supplier_id, source.supplier_name, source.supplier_city,
    source.product_sku, source.category,
    source.quantity_ordered, source.quantity_received,
    source.unit_cost, source.total_cost,
    source.order_status, source.expected_delivery, source.actual_delivery,
    source.warehouse_id, source.lead_time_days, source.is_late,
    source.source_file, source.processed_ts  
);


-- count check
select count(*) from integrate_db.staging.stg_parquet_order;

-- data dekho
select * from integrate_db.staging.stg_parquet_order;







--      ############# task automation #############


create or replace task integrate_db.staging.task_load_parquet_data
    warehouse = compute_wh
    schedule  = '1 minute'
    when system$stream_has_data('integrate_db.raw.parquet_stream')
as
merge into integrate_db.staging.stg_parquet_order as target
using (
    select * from integrate_db.raw.parquet_stream
) as source
on target.order_id = source.order_id
-- update (order status change hua)
when matched then update set
    target.order_status      = source.order_status,
    target.quantity_received = source.quantity_received,
    target.actual_delivery   = source.actual_delivery,
    target.is_late           = source.is_late,
    target.processed_ts      = source.processed_ts
-- new order insert
when not matched
    and source.metadata$action   = 'INSERT'
    and source.metadata$isupdate = false   then insert 
   ( order_id, order_date, store_id, store_city,
    supplier_id, supplier_name, supplier_city,
    product_sku, category,
    quantity_ordered, quantity_received,
    unit_cost, total_cost,
    order_status, expected_delivery, actual_delivery,
    warehouse_id, lead_time_days, is_late,
    source_file, processed_ts 
)values (
    source.order_id, source.order_date, source.store_id, source.store_city,
    source.supplier_id, source.supplier_name, source.supplier_city,
    source.product_sku, source.category,
    source.quantity_ordered, source.quantity_received,
    source.unit_cost, source.total_cost,
    source.order_status, source.expected_delivery, source.actual_delivery,
    source.warehouse_id, source.lead_time_days, source.is_late,
    source.source_file, source.processed_ts  
);


-- resume task
alter task integrate_db.staging.task_load_parquet_data resume;




--    ############ final verification ###########

-- 1. bronze count
select count(*) from integrate_db.raw.parquet_raw;

-- 2. silver count
select count(*) from integrate_db.staging.stg_parquet_order;

-- 3. stream empty hai?
select system$stream_has_data('integrate_db.raw.parquet_stream');

-- 4. task succeeded?
select *
from table(integrate_db.information_schema.task_history(
    task_name => 'task_load_parquet_data'))
order by scheduled_time desc limit 3;

-- 5. retention 7 days check
select table_name, retention_time
from integrate_db.information_schema.tables
where table_name = 'STG_PARQUET_ORDER';

-- 6. silver file wise count 
select source_file, count(*) as row_count, min(processed_ts) as processed_at
from integrate_db.staging.stg_parquet_order
group by source_file order by processed_at;

-- 7. suspend task
alter task integrate_db.staging.task_load_parquet_data suspend;

