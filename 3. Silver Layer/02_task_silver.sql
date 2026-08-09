/*
task in silver layer :
csv     : task_load_csv_data
json    : task_load_sensor_data
parquet : task_load_parquet_data
*/


-- schema : staging 
use schema integrate_db.staging;

-- ============================================================
-- 1) ROOT TASK
-- Purpose : Acts as the DAG's single scheduled trigger.
--           Does nothing itself (SELECT 1); every 1 minute it fires
--           and cascades to all child tasks below.
-- ============================================================
 
create or replace task integrate_db.staging.task_root
    warehouse = compute_wh
    schedule  = '1 minute'
as
select 1;


-- task : task_load_csv_data
create or replace task integrate_db.staging.task_load_csv_data
    warehouse = compute_wh
    after integrate_db.staging.task_root
as
merge into integrate_db.staging.csv_raw_transaction AS s
using( 
    select 
        transaction_id,
        store_id,
        store_name,
        store_city,
        store_region,
        cashier_id,
        customer_id,
        transaction_date,
        transaction_time,
        product_sku,
        product_name,
        UPPER(category) AS category,
        subcategory,
        CASE
            WHEN quantity > 0 THEN quantity
            ELSE 0
        END AS quantity,
        
        CASE
            WHEN unit_price > 0 THEN unit_price
            ELSE 0
        END AS unit_price,
        
        CASE
            WHEN discount_pct >= 0 THEN discount_pct
            ELSE 0
        END AS discount_pct,
        total_amount,
        
        CASE
            WHEN UPPER(payment_method)='CREDIT CARD' THEN 'CC'
            WHEN UPPER(payment_method)='DEBIT CARD' THEN 'DC'
            ELSE payment_method
        END AS payment_method,
        loyalty_points,
        load_ts,
        file_name AS source_file,
        TO_TIMESTAMP(CONCAT(transaction_date, ' ', transaction_time) ) AS transaction_ts,
        quantity * (unit_price - (unit_price * discount_pct /100) ) AS line_total,
        CURRENT_TIMESTAMP() AS processing_time,
        METADATA$ACTION, METADATA$ISUPDATE
FROM integrate_db.raw.csv_raw_stream) st
ON s.transaction_id=st.transaction_id
WHEN MATCHED
    AND st.METADATA$ACTION='INSERT'
    AND st.METADATA$ISUPDATE='TRUE'
THEN UPDATE SET
        s.store_id=st.store_id,
        s.store_name=st.store_name,
        s.store_city=st.store_city,
        s.store_region=st.store_region,
        s.cashier_id=st.cashier_id,
        s.customer_id=st.customer_id,
        s.transaction_date=st.transaction_date,
        s.transaction_time=st.transaction_time,
        s.transaction_ts=st.transaction_ts,
        s.product_sku=st.product_sku,
        s.product_name=st.product_name,
        s.category=st.category,
        s.subcategory=st.subcategory,
        s.quantity=st.quantity,
        s.unit_price=st.unit_price,
        s.discount_pct=st.discount_pct,
        s.total_amount=st.total_amount,
        s.line_total=st.line_total,
        s.payment_method=st.payment_method,
        s.loyalty_points=st.loyalty_points,
        s.load_ts=st.load_ts,
        s.source_file=st.source_file,
        s.processing_time=st.processing_time

WHEN NOT MATCHED
    AND st.METADATA$ACTION='INSERT'
    AND st.METADATA$ISUPDATE='FALSE'
THEN INSERT(
            transaction_id,
            store_id,
            store_name,
            store_city,
            store_region,
            cashier_id,
            customer_id,
            transaction_date,
            transaction_time,
            transaction_ts,
            product_sku,
            product_name,
            category,
            subcategory,
            quantity,
            unit_price,
            discount_pct,
            total_amount,
            payment_method,
            loyalty_points,
            load_ts,
            source_file,
            line_total,
            processing_time)
VALUES(
        st.transaction_id,
        st.store_id,
        st.store_name,
        st.store_city,
        st.store_region,
        st.cashier_id,
        st.customer_id,
        st.transaction_date,
        st.transaction_time,
        st.transaction_ts,
        st.product_sku,
        st.product_name,
        st.category,
        st.subcategory,
        st.quantity,
        st.unit_price,
        st.discount_pct,
        st.total_amount,
        st.payment_method,
        st.loyalty_points,
        st.load_ts,
        st.source_file,
        st.line_total,
        st.processing_time
)
WHEN MATCHED
    AND st.METADATA$ACTION='DELETE'
    AND st.METADATA$ISUPDATE='FALSE'
THEN DELETE;







-- task : task_load_sensor_data
create or replace task integrate_db.staging.task_load_sensor_data
    warehouse = compute_wh
    after integrate_db.staging.task_root
as
MERGE INTO integrate_db.staging.stg_json_sensor AS stg
USING(
     SELECT
            event_id,
            event_type,
            store_id,
            store_name,
            event_ts,
            device_id,
            raw_payload:metadata.firmware::STRING AS firmware,
            raw_payload:metadata.battery_pct::INT AS battery_pct,
            raw_payload:metadata.store_floor::INT AS store_floor,
            f.value:sensor::STRING AS sensor_name,
            f.value:value::FLOAT AS sensor_value,
            f.value:unit::STRING AS sensor_unit,
            source_file,
            CURRENT_TIMESTAMP() AS processed_ts
FROM integrate_db.raw.json_raw_stream,
LATERAL FLATTEN(input=>raw_payload:readings) f
) src
ON stg.event_id=src.event_id
AND stg.sensor_name=src.sensor_name
WHEN NOT MATCHED
THEN INSERT(
            event_id,
            event_type,
            store_id,
            store_name,
            event_ts,
            device_id,
            firmware,
            battery_pct,
            store_floor,
            sensor_name,
            sensor_value,
            sensor_unit,
            source_file,
            processed_ts
)
VALUES(
        src.event_id,
        src.event_type,
        src.store_id,
        src.store_name,
        src.event_ts,
        src.device_id,
        src.firmware,
        src.battery_pct,
        src.store_floor,
        src.sensor_name,
        src.sensor_value,
        src.sensor_unit,
        src.source_file,
        src.processed_ts
);







-- task : task_load_parquet_data
create or replace task integrate_db.staging.task_load_parquet_data
    warehouse = compute_wh
    after integrate_db.staging.task_root
as  
MERGE INTO integrate_db.staging.stg_parquet_order as stg
USING(
     SELECT
            order_id,
            order_date,
            store_id,
            supplier_id,
            store_city,
            supplier_name,
            supplier_city,
            product_sku,
            category,
            unit_cost,
            total_cost,
            quantity_ordered,
            quantity_received,
            order_status,
            expected_delivery,
            actual_delivery,
            warehouse_id,
            lead_time_days,
            is_late,
            CURRENT_TIMESTAMP() AS processed_ts
FROM integrate_db.raw.parquet_stream
) str
ON stg.order_id=str.order_id
WHEN NOT MATCHED
THEN INSERT(
            order_id,
            order_date,
            store_id,
            supplier_id,
            store_city,
            supplier_name,
            supplier_city,
            product_sku,
            category,
            unit_cost,
            total_cost,
            quantity_ordered,
            quantity_received,
            order_status,
            expected_delivery,
            actual_delivery,
            warehouse_id,
            lead_time_days,
            is_late,
            processed_ts
)
VALUES(
        str.order_id,
        str.order_date,
        str.store_id,
        str.supplier_id,
        str.store_city,
        str.supplier_name,
        str.supplier_city,
        str.product_sku,
        str.category,
        str.unit_cost,
        str.total_cost,
        str.quantity_ordered,
        str.quantity_received,
        str.order_status,
        str.expected_delivery,
        str.actual_delivery,
        str.warehouse_id,
        str.lead_time_days,
        str.is_late,
        str.processed_ts
);
