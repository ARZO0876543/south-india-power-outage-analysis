# Data

The full datasets are too large for GitHub (the raw file is about 480 MB; GitHub rejects files over 100 MB),
so they are **not stored in this repo**.

| File | Where it goes | Rows | Size | Notes |
|---|---|---|---|---|
| `daily-power-outage.csv` | `data/raw/` | 4,265,703 | ~478 MB | National, Sep 2017 – Apr 2025. Source file. |
| `cleaned_south_outage_powerbi.csv` | `data/processed/` | 580,825 | ~89 MB | Southern region, 2018-01-01 – 2024-12-10, deduplicated. |
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
