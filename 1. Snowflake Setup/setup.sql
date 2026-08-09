-- ===========================================
-- Database : integrate_db
-- ===========================================
create database if not exists integrate_db;
use integrate_db;



-- ===========================================
-- Schema :
-- bronze : raw
-- silver : staging
-- gold : golden_mart
-- ===========================================

create schema if not exists integrate_db.raw;

create schema if not exists integrate_db.staging;

create schema if not exists integrate_db.golden_mart;


-- using schema raw 
use schema raw;




-- ===============================================
-- storage integration : s3_integrations
-- ===============================================
create or replace storage integration s3_integrations
    type                      = external_stage
    storage_provider          = s3
    enabled                   = true
    storage_aws_role_arn      = 'arn:aws:iam::049882582572:role/snowflake_role_s3'
    storage_allowed_locations = ('s3://globalmart-data-lakes/');

-- take details 
desc integration s3_integrations;





-- ==============================================
-- File Format :
-- csv : format_csv
-- json : format_json
-- parquet: format_parquet
-- ==============================================
create or replace file format integrate_db.raw.format_csv
    type        = csv
    skip_header = 1;

create or replace file format integrate_db.raw.format_json
    type              = json
    strip_outer_array = true;

create or replace file format integrate_db.raw.format_parquet
    type = parquet;





-- ==============================================
-- External Stage :
-- csv: s3_csv_stage
-- json: s3_json_stage
-- parquet: s3_parquet_stage
-- ==============================================
create or replace stage integrate_db.raw.s3_csv_stage
    url                = 's3://globalmart-data-lakes/file_csv/'
    storage_integration = s3_integrations
    file_format        = (format_name = 'integrate_db.raw.format_csv');  


create or replace stage integrate_db.raw.s3_json_stage
    url                 = 's3://globalmart-data-lakes/file_json/'
    storage_integration = s3_integrations
    file_format         = (format_name = 'integrate_db.raw.format_json');


create or replace stage integrate_db.raw.s3_parquet_stage
    url                 = 's3://globalmart-data-lakes/file_parquet/'
    storage_integration = s3_integrations
    file_format         = (format_name = 'integrate_db.raw.format_parquet');


-- list of files csv
list @integrate_db.raw.s3_csv_stage;

-- list of files json
list @integrate_db.raw.s3_json_stage;

-- list of files parquet
list @integrate_db.raw.s3_parquet_stage;

