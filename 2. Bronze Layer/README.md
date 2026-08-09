# Bronze Layer

## Overview
The Bronze layer is the **raw ingestion layer** of the GlobalMart data pipeline. It stores data exactly as received from source files (CSV, JSON, Parquet), with no transformation or cleaning applied. This layer acts as the single source of truth for all raw, unprocessed data landing from Amazon S3 into Snowflake.

## Data Sources
| Source | Format | Description |
|---|---|---|
| Transactions | CSV | Point-of-sale transaction records from all stores |
| Sensor Events | JSON | IoT sensor readings (temperature, humidity, footfall, etc.) from store devices |
| Purchase Orders | Parquet | Supplier purchase order and delivery data |

## Architecture
```
S3 (file_csv/, file_json/, file_parquet/)
        │
        ▼  (Snowpipe, auto_ingest = true)
Bronze Tables (raw schema)
        │
        ▼  (Streams capture change data)
   → consumed by Silver layer tasks
```

## Files in this folder

| File | Purpose |
|---|---|
| `01_bronze_tables.sql` | Creates the three raw tables: `csv_raw`, `json_raw`, `parquet_raw` |
| `02_bronze_initial_load.sql` | One-time manual `COPY INTO` to backfill any files already sitting in the S3 stage before Snowpipe was set up |
| `03_bronze_streams.sql` | Creates Snowflake Streams (`csv_raw_stream`, `json_raw_stream`, `parquet_stream`) on each raw table to track new/changed rows for the Silver layer to consume |
| `04_bronze_snowpipes.sql` | Creates Snowpipes (`csv_raw_pipe`, `json_raw_pipe`, `parquet_pipe`) with `auto_ingest = true`, so any new file dropped in the S3 stage is automatically loaded within seconds, no manual trigger needed |
| `05_validate_bronze.sql` | Row-count and spot-check queries to confirm data has landed correctly in each raw table |

## Key Tables

**`raw.csv_raw`** — transaction_id, store_id, store_name, store_city, store_region, product_sku, product_name, category, quantity, unit_price, discount_pct, total_amount, payment_method, loyalty_points, load_ts, file_name

**`raw.json_raw`** — event_id, event_type, store_id, store_name, event_ts, device_id, raw_payload (VARIANT), load_ts, source_file

**`raw.parquet_raw`** — order_id, order_date, store_id, supplier_id, product_sku, category, unit_cost, total_cost, quantity_ordered, quantity_received, order_status, expected_delivery, actual_delivery, load_ts, source_file

## How ingestion works
1. A file is uploaded to the relevant S3 folder (`file_csv/`, `file_json/`, `file_parquet/`).
2. S3 event notification fires → the matching Snowpipe picks it up automatically.
3. Snowpipe runs `COPY INTO` in the background and loads the raw rows into the bronze table.
4. The table's Stream captures these as new rows, ready for the Silver layer to process.

## Notes
- Bronze tables never get transformed or cleaned — they are an exact, auditable copy of the source files.
- Each file should use a **unique filename** on upload. Snowpipe/COPY keeps a load history and will skip a file it has already loaded, even after the target table is truncated.
- `file_name` / `source_file` columns preserve the original filename for traceability back to the source file.
