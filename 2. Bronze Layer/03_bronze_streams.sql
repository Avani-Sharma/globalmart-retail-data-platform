/*
stream creation : Stream captures new records from Bronze tables 
                  for incremental processing in the Silver layer.
                  
csv     : csv_raw_stream
json    : json_raw_stream
parquet : parquet_stream
*/


-- stream csv
create or replace stream integrate_db.raw.csv_raw_stream
    on table integrate_db.raw.csv_raw
    append_only = true;  


-- stream json
create or replace stream integrate_db.raw.json_raw_stream
    on table integrate_db.raw.json_raw
    append_only = true;


-- stream parquet
create or replace stream integrate_db.raw.parquet_stream
    on table integrate_db.raw.parquet_raw
    append_only = true;