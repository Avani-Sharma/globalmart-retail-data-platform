# 🥇 Gold Layer — Business-Ready Analytics

![Layer](https://img.shields.io/badge/Layer-Gold-FFD700?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Automated-brightgreen?style=for-the-badge)
![Engine](https://img.shields.io/badge/Snowflake-Star%20Schema-29B5E8?style=for-the-badge&logo=snowflake)
![BI](https://img.shields.io/badge/Power%20BI-Connected-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)

## 🎯 Why this layer exists

Clean data still isn't *usable* data — not for a business user, and not for a dashboard. Nobody in a boardroom wants to query three staging tables and manually join them just to find out which store sold the most last month.

The Gold layer's job is to shape everything Silver produced into a **Star Schema** — the classic, battle-tested design where a handful of dimension tables (store, product, date, supplier) surround focused fact tables (sales, margin, sensor readings). This is what makes it possible to build a Power BI dashboard with drag-and-drop simplicity, and what makes questions like *"show me revenue by category, by month, by store"* answerable in seconds instead of minutes.

## 🧩 What's built here

- 🏛️ **Four dimension tables** — Store, Product, Supplier, Date — the reusable "who/what/when" building blocks
- 📊 **Three fact tables** — Daily Sales, Gross Margin, IoT Sensor readings — the measurable events that dimensions describe
- 🤖 **Two automated tasks** chained onto the same DAG as Silver — dimensions refresh first, facts refresh right after, entirely hands-off
- ⚡ **Materialized Views** — pre-aggregated summaries that keep dashboards fast even as data grows
- 🧊 **Clustering keys** on the big fact tables — keeps query performance solid at scale
- ✅ **Validation queries** — confirm every dimension, fact, and materialized view is populated correctly

## 🔀 How data flows in

```
🥈 Silver Staging Tables
        │
        ▼
🏛️ Dimension Tables  (dim_store · dim_product · dim_supplier · dim_date)
        │
        ▼
📊 Fact Tables  (fact_daily_sales · fact_gross_margin · fact_iot_sensor)
        │
        ▼
⚡ Materialized Views  +  🧊 Clustering
        │
        ▼
📈 Power BI Dashboard
```

## ⭐ The Star Schema

```
              🏛️ dim_date
                   │
🏛️ dim_store ──── 📊 fact_daily_sales ──── 🏛️ dim_product
                   │
              🏛️ dim_date
                   │
🏛️ dim_store ──── 📊 fact_gross_margin ──── 🏛️ dim_product
                   │
              🏛️ dim_supplier
                   │
              🏛️ dim_date
                   │
🏛️ dim_store ──── 📊 fact_iot_sensor
```

## 💡 Good to know

- 🛠️ **A real bug lives here, fixed here:** the same `product_sku` sometimes showed up with conflicting category/subcategory values across transactions. Left unhandled, this crashed the dimension refresh with a "duplicate row" error. The fix — always keep only the *most recent* version of each product (`ORDER BY load_ts DESC`) — is baked into the automated task
- Materialized Views and clustering are **set-and-forget** — Snowflake keeps them fresh and organized in the background, no schedule needed
- Power BI should connect **only to this layer** (never Bronze or Silver directly), using Import mode with a manual or scheduled Refresh
