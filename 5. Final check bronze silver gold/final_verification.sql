/*
Full pipeline verification script.
Use this AFTER uploading CSV, JSON, and Parquet file to S3.
*/


-- ============================================================
-- STEP 1 : START THE FULL DAG (run this first, before/after upload)
-- ============================================================

select system$task_dependents_enable('integrate_db.staging.task_root');

-- confirm every task is 'started'
show tasks in schema integrate_db.staging;



-- ============================================================
-- STEP 2 : BRONZE LAYER CHECK (did snowpipe load the raw file?)
-- ============================================================

select 'csv_raw' as table_name, count(*) as row_count from integrate_db.raw.csv_raw
union all
select 'json_raw', count(*) from integrate_db.raw.json_raw
union all
select 'parquet_raw', count(*) from integrate_db.raw.parquet_raw;


-- pipe status: check pendingFileCount / lastIngestedTimestamp
select system$pipe_status('integrate_db.raw.csv_raw_pipe')      as csv_pipe_status;
select system$pipe_status('integrate_db.raw.json_raw_pipe')     as json_pipe_status;
select system$pipe_status('integrate_db.raw.parquet_pipe')  as parquet_pipe_status;




-- ============================================================
-- STEP 3 : STREAM CHECK (has the change data been consumed by tasks yet?)
-- TRUE  = stream still has unconsumed data (task hasn't picked it up yet)
-- FALSE = task has already consumed it (normal after ~1 min)
-- ============================================================

select system$stream_has_data('integrate_db.raw.csv_raw_stream')     as csv_stream_pending;
select system$stream_has_data('integrate_db.raw.json_raw_stream')    as json_stream_pending;
select system$stream_has_data('integrate_db.raw.parquet_stream')     as parquet_stream_pending;



-- ============================================================
-- STEP 4 : TASK EXECUTION HISTORY (did every task succeed?)
-- ============================================================

select
    name as task_name,
    state,
    error_message,
    scheduled_time,
    completed_time
from table(information_schema.task_history(
    scheduled_time_range_start => dateadd('minute', -10, current_timestamp())
))
where name in (
    'TASK_ROOT','TASK_LOAD_CSV_DATA','TASK_LOAD_SENSOR_DATA',
    'TASK_LOAD_PARQUET_DATA','TASK_GOLD_DIMENSIONS','TASK_GOLD_FACTS'
)
order by scheduled_time desc
limit 30;



-- ============================================================
-- STEP 5 : SILVER LAYER CHECK
-- ============================================================

select 'csv_raw_transaction' as table_name, count(*) as row_count from integrate_db.staging.csv_raw_transaction
union all
select 'stg_json_sensor', count(*) from integrate_db.staging.stg_json_sensor
union all
select 'stg_parquet_order', count(*) from integrate_db.staging.stg_parquet_order;



-- ============================================================
-- STEP 6 : GOLD LAYER CHECK - DIMENSIONS
-- ============================================================

select 'dim_store' as table_name, count(*) as row_count from integrate_db.golden_mart.dim_store
union all
select 'dim_product', count(*) from integrate_db.golden_mart.dim_product
union all
select 'dim_supplier', count(*) from integrate_db.golden_mart.dim_supplier
union all
select 'dim_date', count(*) from integrate_db.golden_mart.dim_date;



-- ============================================================
-- STEP 7 : GOLD LAYER CHECK - FACTS
-- ============================================================

select 'fact_daily_sales' as table_name, count(*) as row_count from integrate_db.golden_mart.fact_daily_sales
union all
select 'fact_gross_margin', count(*) from integrate_db.golden_mart.fact_gross_margin
union all
select 'fact_iot_sensor', count(*) from integrate_db.golden_mart.fact_iot_sensor;




-- ============================================================
-- STEP 8 : MATERIALIZED VIEWS CHECK (background auto-refresh, may lag slightly)
-- ============================================================

select 'mv_store_sales_summary' as mv_name, count(*) as row_count from integrate_db.golden_mart.mv_store_sales_summary
union all
select 'mv_product_margin_summary', count(*) from integrate_db.golden_mart.mv_product_margin_summary
union all
select 'mv_iot_sensor_summary', count(*) from integrate_db.golden_mart.mv_iot_sensor_summary;





-- ============================================================
-- STEP 9(OPTIONAL) : STOP ALL TASKS
-- ============================================================

alter task integrate_db.staging.task_root suspend;
alter task integrate_db.staging.task_load_csv_data suspend;
alter task integrate_db.staging.task_load_sensor_data suspend;
alter task integrate_db.staging.task_load_parquet_data suspend;
alter task integrate_db.staging.task_gold_dimensions suspend;
alter task integrate_db.staging.task_gold_facts suspend;

-- confirm all suspended
show tasks in schema integrate_db.staging;