-- =========================================================
-- 1. Validate Staging Layer Data
-- =========================================================

-- Validate CSV transaction staging table
select * from integrate_db.staging.csv_raw_transaction;

-- Validate JSON sensor staging table
select * from integrate_db.staging.stg_json_sensor;

-- Validate Parquet order staging table
select * from integrate_db.staging.stg_parquet_order;




-- =========================================================
-- 2. Manage CSV Staging Task
-- =========================================================

-- Suspend CSV data loading task
alter task integrate_db.staging.task_load_csv_data suspend;

-- Resume CSV data loading task
alter task integrate_db.staging.task_load_csv_data resume;




-- =========================================================
-- 3. Manage JSON Sensor Staging Task
-- =========================================================

-- Suspend JSON sensor data loading task
alter task integrate_db.staging.task_load_sensor_data suspend;

-- Resume JSON sensor data loading task
alter task integrate_db.staging.task_load_sensor_data resume;




-- =========================================================
-- 4. Manage Parquet Staging Task
-- =========================================================

-- Suspend Parquet order data loading task
alter task integrate_db.staging.task_load_parquet_data suspend;

-- Resume Parquet order data loading task
alter task integrate_db.staging.task_load_parquet_data resume;