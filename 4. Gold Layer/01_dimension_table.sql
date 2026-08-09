-- schema
use schema integrate_db.golden_mart;


-- ============================================================
-- Store Dimension
-- ============================================================

CREATE OR REPLACE TABLE integrate_db.golden_mart.dim_store (
    store_key          NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    store_id           STRING        NOT NULL,
    store_name         STRING,
    store_city         STRING,
    store_region       STRING,
    CONSTRAINT pk_dim_store PRIMARY KEY (store_key)
);

-- merge command
MERGE INTO integrate_db.golden_mart.dim_store tgt
USING (
    SELECT DISTINCT
        store_id,
        store_name,
        store_city,
        store_region
    FROM integrate_db.staging.csv_raw_transaction
    WHERE store_id IS NOT NULL
) src
ON tgt.store_id = src.store_id
WHEN MATCHED THEN
UPDATE SET
    tgt.store_name   = src.store_name,
    tgt.store_city   = src.store_city,
    tgt.store_region = src.store_region
WHEN NOT MATCHED THEN
INSERT (
    store_id,
    store_name,
    store_city,
    store_region
)
VALUES (
    src.store_id,
    src.store_name,
    src.store_city,
    src.store_region
);




-- ============================================================
-- Product Dimension
-- ============================================================

CREATE OR REPLACE TABLE integrate_db.golden_mart.dim_product (
    product_key        NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    product_sku        STRING        NOT NULL,
    product_name       STRING,
    category           STRING,
    subcategory        STRING,
    CONSTRAINT pk_dim_product PRIMARY KEY (product_key)
);

-- merge command
MERGE INTO  integrate_db.golden_mart.dim_product tgt
USING (
    SELECT product_sku, product_name, category, subcategory
    FROM (
        SELECT product_sku, product_name, category, subcategory,
               ROW_NUMBER() OVER (
                   PARTITION BY product_sku
                   ORDER BY load_ts DESC
               ) AS rn
        FROM integrate_db.staging.csv_raw_transaction
        WHERE product_sku IS NOT NULL
    )
    WHERE rn = 1
) src
ON tgt.product_sku = src.product_sku
WHEN MATCHED THEN
UPDATE SET
    tgt.product_name = src.product_name,
    tgt.category     = src.category,
    tgt.subcategory  = src.subcategory
WHEN NOT MATCHED THEN
INSERT (
    product_sku,
    product_name,
    category,
    subcategory
)
VALUES (
    src.product_sku,
    src.product_name,
    src.category,
    src.subcategory
);


-- ============================================================
-- Supplier Dimension
-- ============================================================

CREATE OR REPLACE TABLE integrate_db.golden_mart.dim_supplier (
    supplier_key       NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    supplier_id        STRING       NOT NULL,
    supplier_name      STRING,
    supplier_city      STRING,
    CONSTRAINT pk_dim_supplier PRIMARY KEY (supplier_key)
);

-- merge command 
MERGE INTO integrate_db.golden_mart.dim_supplier tgt
USING (
    SELECT DISTINCT
        supplier_id,
        supplier_name,
        supplier_city
    FROM integrate_db.staging.stg_parquet_order
    WHERE supplier_id IS NOT NULL
) src
ON tgt.supplier_id = src.supplier_id
WHEN MATCHED THEN
UPDATE SET
    tgt.supplier_name = src.supplier_name,
    tgt.supplier_city = src.supplier_city
WHEN NOT MATCHED THEN
INSERT (
    supplier_id,
    supplier_name,
    supplier_city
)
VALUES (
    src.supplier_id,
    src.supplier_name,
    src.supplier_city
);


-- ============================================================
-- Date Dimension
-- ============================================================

CREATE OR REPLACE TABLE integrate_db.golden_mart.dim_date (
    date_key           NUMBER,
    transaction_date   DATE        NOT NULL,
    day_number         NUMBER,
    month_number       NUMBER,
    month_name         STRING,
    quarter_number     NUMBER,
    year_number        NUMBER,
    day_name           STRING,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
);

-- merge command
MERGE INTO integrate_db.golden_mart.dim_date tgt
USING (
    SELECT DISTINCT
        transaction_date,
        YEAR(transaction_date) * 10000 +
        MONTH(transaction_date) * 100 +
        DAY(transaction_date) AS date_key,
        DAY(transaction_date)      AS day_number,
        MONTH(transaction_date)    AS month_number,
        MONTHNAME(transaction_date) AS month_name,
        QUARTER(transaction_date)  AS quarter_number,
        YEAR(transaction_date)     AS year_number,
        DAYNAME(transaction_date)  AS day_name
    FROM integrate_db.staging.csv_raw_transaction
    WHERE transaction_date IS NOT NULL
) src
ON tgt.date_key = src.date_key
WHEN MATCHED THEN
UPDATE SET
    tgt.transaction_date = src.transaction_date,
    tgt.day_number       = src.day_number,
    tgt.month_number     = src.month_number,
    tgt.month_name       = src.month_name,
    tgt.quarter_number   = src.quarter_number,
    tgt.year_number      = src.year_number,
    tgt.day_name         = src.day_name
WHEN NOT MATCHED THEN
INSERT (
    date_key,
    transaction_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    day_name
)
VALUES (
    src.date_key,
    src.transaction_date,
    src.day_number,
    src.month_number,
    src.month_name,
    src.quarter_number,
    src.year_number,
    src.day_name
);

