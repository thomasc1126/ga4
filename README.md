# GA4 dbt setup (Phase 1 + Phase 2)

This repo is configured to install and run the [`Velir/ga4`](https://hub.getdbt.com/) package, plus local executive marts layered on top of Velir modeled outputs.

## 1) Fill required GA4 vars in `dbt_project.yml`

Update these placeholders before running builds:

- `vars.ga4.source_project`: your GCP project that contains GA4 export tables.
- `vars.ga4.source_dataset`: your GA4 dataset (for example `analytics_123456789`).
- `vars.ga4.property_ids`: one or more GA4 property IDs.
- `vars.ga4.start_date`: earliest date to process (`YYYY-MM-DD`).

> Note: the Velir/ga4 package reads source location from vars, so no additional local `sources.yml` is required for package models.

## 2) (Optional) set `DBT_PROFILES_DIR`

If your `profiles.yml` is not in `~/.dbt`, set:

```bash
export DBT_PROFILES_DIR=/path/to/your/profiles-dir
```

## 3) Install dependencies

```bash
dbt deps
```

Expected output includes lines similar to:
- `Installing Velir/ga4`
- `Installed from version ...`

## 4) Seed (safe even if no seeds exist)

```bash
dbt seed
```

Expected output:
- If no seed files: `Nothing to do`
- If seeds exist later: seed models built successfully

## 5) Build models/tests/snapshots

```bash
dbt build
```

Expected output includes:
- package + local models parsed
- successful completion summary (or credential/config errors if placeholders are not filled)

## Executive marts (Phase 2)

All marts are in `models/marts/exec/` and are built only from Velir package modeled tables (sessions, purchases, items, and staged events).

### `mart_exec_daily_kpis` (date grain)

Top-line KPI mart for leadership scorecards.

- Grain: `date`
- Metrics: `revenue`, `orders`, `purchasers`, `aov`, `sessions`, `engaged_sessions`, `conversion_rate`, `items_sold`

### `mart_channel_daily` (date + channel grain)

Channel mix and attribution performance.

- Grain: `date` + `default_channel_grouping` (with source/medium retained for drill-down)
- Metrics: `sessions`, `revenue`, `orders`, `purchasers`, `aov`, `conversion_rate`

### `mart_product_daily` (date + product grain)

Merchandising and SKU/category performance.

- Grain: `date` + `item_id` (with `item_name`, `item_category` attributes)
- Metrics: `item_revenue`, `quantity`, `orders_with_item`

### `mart_funnel_daily` (date grain)

Session-based ecommerce funnel progression.

- Grain: `date`
- Steps: `view_item`, `add_to_cart`, `begin_checkout`, `purchase`
- Outputs: per-step distinct session counts + CVRs (`view→cart`, `cart→checkout`, `checkout→purchase`, `view→purchase`)

## Suggested dashboard mapping

Use these marts directly in Looker Studio/Tableau to minimize ad hoc recomputation:

- Executive KPI scorecard + daily trend: `mart_exec_daily_kpis`
- Channel performance table/stacked trend: `mart_channel_daily`
- Product leaderboard and category trends: `mart_product_daily`
- Funnel visualization and daily conversion trend: `mart_funnel_daily`

## Quick run sequence

```bash
dbt deps && dbt seed && dbt build
```

After replacing placeholders in `dbt_project.yml`, the command above should run end-to-end against your configured BigQuery target.
