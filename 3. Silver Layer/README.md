# 🥈 Silver Layer — Cleaned & Standardized

![Layer](https://img.shields.io/badge/Layer-Silver-C0C0C0?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Automated-brightgreen?style=for-the-badge)
![Engine](https://img.shields.io/badge/Snowflake-Tasks%20%2B%20Streams-29B5E8?style=for-the-badge&logo=snowflake)

## 🎯 Why this layer exists

Raw data is honest, but it's messy. Prices come in negative by mistake, category names are inconsistent (`clothing` vs `CLOTHING`), payment methods are written a dozen different ways, and a single JSON event can secretly contain five different sensor readings bundled inside it.

The Silver layer's job is to take that raw chaos from Bronze and turn it into something **trustworthy and analysis-ready** — proper data types, consistent formatting, business rules applied, and every JSON payload unpacked into clean rows. This is the layer where GlobalMart's data actually starts telling a coherent story.

## 🧩 What's built here

- 🧹 **Staging tables** — one clean, structured home for transactions, sensor readings, and purchase orders
- 🤖 **A self-running task DAG** — a root scheduler task fires every minute and automatically triggers three loader tasks in parallel, so data keeps flowing without anyone touching Snowflake
- 🔗 **MERGE-based loading** — every task reads only what's *new* from the Bronze stream and safely upserts it, so re-running never creates duplicates
- ✅ **Validation queries** — confirm the cleaned tables are populated and looking right

## 🔀 How data flows in

```
🌊 Bronze Streams (csv_raw_stream / json_raw_stream / parquet_stream)
        │
        ▼   ⏱️  task_root fires every 1 minute
   ┌────┴────┬─────────────┐
   ▼         ▼             ▼
🧽 CSV     📡 Sensor     🚚 Parquet
 cleanup    flattening    passthrough
   │         │             │
   ▼         ▼             ▼
🥈 Silver Staging Tables
        │
        ▼
        → picked up by the Gold Layer
```

## ✨ What actually gets cleaned

| 📦 Data | What happens to it |
|---|---|
| 🛒 Transactions | Categories uppercased · negative prices/quantities zeroed out · payment methods standardized (`CREDIT CARD` → `CC`) · a proper transaction timestamp and line-total are calculated |
| 📡 Sensor events | Nested JSON is flattened — each reading inside one event becomes its own clean row, with device metadata pulled out |
| 🚚 Purchase orders | Passed through with a processing timestamp, ready to be joined with sales data later |

## 💡 Good to know

- These tasks are **incremental** — the underlying Streams remember what's already been processed, so nothing is ever reprocessed
- If a task fails repeatedly, Snowflake auto-suspends it as a safety measure — it needs a manual `RESUME` once the root cause is fixed
- Everything the Gold layer builds depends on this layer being fresh and correct first
