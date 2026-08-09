# 🥉 Bronze Layer — Raw Ingestion

![Layer](https://img.shields.io/badge/Layer-Bronze-CD7F32?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Automated-brightgreen?style=for-the-badge)
![Engine](https://img.shields.io/badge/Snowflake-Snowpipe-29B5E8?style=for-the-badge&logo=snowflake)

## 🎯 Why this layer exists

GlobalMart receives data from **three completely different systems** — a point-of-sale system dropping CSV files, IoT sensors streaming JSON events, and a supplier/procurement system exporting Parquet files. Before any of this data can be trusted, cleaned, or analyzed, it needs a **safe, untouched landing zone**.

That's the Bronze layer's entire job: **capture everything, exactly as it arrives, automatically — no exceptions, no cleanup, no data loss.** If something ever looks wrong three layers downstream in a dashboard, this is the layer you come back to and ask *"what did the source file actually say?"*

## 🧩 What's built here

- 📥 **Three raw tables** — one landing zone each for transactions, sensor events, and purchase orders
- 🔄 **Snowflake Streams** on every raw table — a lightweight "what changed since I last looked" tracker that the Silver layer reads from
- ⚡ **Snowpipes with auto-ingest** — the moment a file lands in S3, it's loaded into Snowflake within seconds. Nobody has to click "run" ever again
- ✅ **Validation queries** — quick row-count sanity checks to confirm ingestion actually worked

## 🔀 How data flows in

```
📁 S3 Bucket (file_csv/  file_json/  file_parquet/)
        │
        │  🔔  new file lands → S3 event fires
        ▼
⚡ Snowpipe (auto_ingest = true)
        │
        ▼
🥉 Bronze Table  (csv_raw / json_raw / parquet_raw)
        │
        ▼
🌊 Stream captures the new rows
        │
        ▼
        → picked up by the Silver Layer
```

## 📦 What lands here

| 🗂️ Source | Format | What it carries |
|---|---|---|
| 🛒 Store transactions | CSV | Every sale, across every store |
| 📡 IoT sensors | JSON | Temperature, footfall, device health readings |
| 🚚 Purchase orders | Parquet | What suppliers shipped, and when |

## 💡 Good to know

- Nothing is transformed here — Bronze is a **mirror of the source file**, kept for traceability and auditing
- Every file needs a **unique filename** on upload — Snowflake remembers what it already loaded, even if the table is later truncated
- If ingestion ever looks stuck, `SYSTEM$PIPE_STATUS()` on the relevant pipe is the first thing to check
