# Data

The full datasets are too large for GitHub (the raw file is about 480 MB; GitHub rejects files over 100 MB),
so they are **not stored in this repo**.

| File | Where it goes | Rows | Size | Notes |
|---|---|---|---|---|
| `daily-power-outage.csv` | `data/raw/` | 4,265,703 | ~478 MB | National, Sep 2017 – Apr 2025. Source file. |
| `cleaned_south_outage_powerbi.csv.gz` | `data/processed/` (**included in repo**) | 580,825 | 7.3 MB (89 MB unzipped) | Southern region, 2018-01-01 – 2024-12-10, deduplicated. Pandas reads `.csv.gz` directly. |
| `cleaned_sample_5k.csv` | `data/sample/` (included) | 5,000 | <1 MB | Random sample (seed 42) for quick exploration. |

**Where to get them:** add your download link or release/Drive URL here. The original source link is blank in the codebook, so fill it in.

## Raw columns (see `docs/Daily_Power_Outage_codebook.xlsx`)

`id, date, region, state_name, state_code, sector, station_type, power_station, power_station_unit, outage_type, monitored_capacity, cap_under_outage, outage_date, expected_sync_date, remarks`

## Cleaned columns

| Column | Description |
|---|---|
| `date`, `Year` | Observation date and its year |
| `state_name`, `sector` | State/UT and sector (State, Central, Private) |
| `fuel_type` | From `station_type`: Thermal → Coal/Lignite, Ther (Gt) → Gas, Ther (Dg) → Diesel, Hydro, Nuclear |
| `power_station`, `power_station_unit` | Plant and unit |
| `outage_type` | Long/Short Duration, Planned, Unit Synchronised, or **No Outage** (blank in raw) |
| `monitored_capacity` | Unit capacity in MW |
| `loss_mw` | Capacity lost that day in MW (from `cap_under_outage`, blanks as 0) |
| `not_operational` | True for new or unstabilised units |
| `remarks` | Reported reason; "No remark" where blank |
| `Major_Category1`, `cause_category` | Grouped remark and cause category |
| `outage_date`, `expected_sync_date`, `outage_age_days` | Outage start, expected return, days since start |
| `in_service` | Whether the unit is treated as in service |
| `shortfall_not_outage` | True when a loss is reported but `outage_type` is "No Outage" (backing down / low schedule) |
| `cause_recorded` | False when no cause is recorded for the row |

The unit of record is one **unit on one day**. The key `date + state_name + power_station + power_station_unit` is unique in the cleaned file.

## Derived tables (`reports/tables/`)

| File | Rows | One row per | Key columns |
|---|---|---|---|
| `episodes.csv` | 9,522 | unit outage episode | `power_station, power_station_unit, outage_date, last_seen, duration_days, recovered, cause, remark, mw_days, capacity_mw` |
| `repeat_units.csv` | 151 | unit with forced outages | `unit, forced_episodes, repeats, repeat_pct, trips_per_year` |
| `km_curves.csv` | 325 | day × cause | `days, prob_still_down, cause` (Kaplan–Meier recovery curve) |
| `forecast.csv` | 92 | month | `month, actual, forecast, lower, upper` (average daily outage MW; 2025 forecast) |

These tables feed the Power BI report. Their definitions are in [`docs/methodology.md`](../docs/methodology.md).
