# GA4 dbt setup (Phase 1)

This repo is configured to install and run the [`Velir/ga4`](https://hub.getdbt.com/) package.

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

## Quick run sequence

```bash
dbt deps && dbt seed && dbt build
```

After replacing placeholders in `dbt_project.yml`, the command above should run end-to-end against your configured BigQuery target.
