-- =========================================
-- 1. VALIDATE BRONZE TABLES 
-- =========================================

-- check csv bronze table data
select * from integrate_db.raw.csv_raw;

-- check json bronze table data
select * from integrate_db.raw.json_raw;

-- check parquet bronze table data
select * from integrate_db.raw.parquet_raw;



-- =========================================
-- 2. VALIDATE BRONZE STREAMS 
-- =========================================

-- check csv stream definition and metadata
desc stream integrate_db.raw.csv_raw_stream;

-- check whether the csv stream contains unconsumed change records
select system$stream_has_data('integrate_db.raw.csv_raw_stream');

-- view change records captured by the csv stream
select * from integrate_db.raw.csv_raw_stream;



-- check json stream definition and metadata
desc stream integrate_db.raw.json_raw_stream;

-- check whether the json stream contains unconsumed change records
select system$stream_has_data('integrate_db.raw.json_raw_stream');

-- view change records captured by the json stream
select * from integrate_db.raw.json_raw_stream;



-- check whether the parquet stream contains unconsumed change records
select system$stream_has_data('integrate_db.raw.parquet_stream');

-- view change records captured by the parquet stream
select * from integrate_db.raw.parquet_stream;




-- =========================================
-- 3. VALIDATE SNOWPIPE STATUS
-- =========================================

-- check csv snowpipe definition and configuration
desc pipe integrate_db.raw.csv_raw_pipe;

-- check the current status of the csv snowpipe
select system$pipe_status('integrate_db.raw.csv_raw_pipe');



-- check json snowpipe definition and configuration
desc pipe integrate_db.raw.json_raw_pipe;

-- check the current status of the json snowpipe
select system$pipe_status('integrate_db.raw.json_raw_pipe');



-- check parquet snowpipe definition and configuration
desc pipe integrate_db.raw.parquet_pipe;

-- check the current status of the parquet snowpipe
select system$pipe_status('integrate_db.raw.parquet_pipe');