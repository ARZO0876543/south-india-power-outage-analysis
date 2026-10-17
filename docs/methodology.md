# Methodology and metric definitions

## Core terms

| Term | Definition |
|---|---|
| **Unit-day** | One generating unit on one day; the row level of the cleaned data |
| **MW-days** | Capacity lost (MW) summed over days. It measures capacity, not energy. Multiply by 24 and divide by 1,000 for a rough GWh-equivalent |
| **Outage loss** | `loss_mw` on rows where `shortfall_not_outage = 0`, i.e. real outages: forced, planned, fuel supply, financial/legal and not-yet-operational units |
| **Shortfall** | `loss_mw` on rows where a loss is reported but `outage_type` is "No Outage" (reserve shutdown or low schedule). Reported separately, excluded from outage loss |
| **Avg daily outage loss** | Outage MW-days ÷ days with data (31.88M ÷ 2,459 = about 12,965 MW) |
| **Outage loss rate** | Outage MW-days ÷ monitored capacity summed over unit-days that have a capacity value (about 20.2%) |
| **Forced share** | Outage MW-days with cause "Technical (forced)" ÷ all outage MW-days (about 37.5%) |
| **Total loss rate** | The same ratio using outage + shortfall MW-days |

## Episodes

`reports/tables/episodes.csv` has one row per unit outage, keyed on `power_station + power_station_unit + outage_date`.

- **Duration** = last date the unit is seen in the outage − `outage_date`.
- **Recovered** = the episode has a "Unit Synchronised" row, or it ends before the last date in the data. Episodes that do not are **ongoing (censored)**; there are 41.
- **Cause / remark** = the most common value across the episode's days.
- `outage_date` is blank for most outage rows from mid-November 2024. It is rebuilt from the same unit's earlier days, and where the run started inside the gap, from the first day seen.

## Reliability measures

- **Repeat failure:** a forced episode that starts 0 to 30 days after the previous forced episode of the same unit ended. Repeat rate = repeats ÷ forced episodes (2,827 ÷ 5,090 = 55.5%). Notebook 02 also reports 57%, which divides by follow-on trips only (2,827 ÷ 4,939).
- **Kaplan–Meier recovery curves:** estimate the probability an outage is still on after *t* days, treating ongoing outages as censored. Written directly in NumPy.
- **Station Pareto:** stations ranked by outage MW-days with cumulative share; 47 stations have any outage loss.
- **Forecast:** monthly average daily outage loss. Three simple models are compared on a hold-out (Jan to Nov 2024): seasonal naive, month profile with linear trend, and Holt-Winters. The winner, month profile with trend (MAPE about 17.9%), forecasts 2025. December 2024 is excluded because only 10 days exist. The band is a rough 80% interval from backtest errors.

## Dashboard measures

| Card | Value | Meaning |
|---|---|---|
| Outage Loss (MW-days) | 32M | Outage MW-days, all years |
| Avg Daily Outage Loss | 12.97K | Outage MW-days ÷ days with data |
| Outage Loss Rate | 20.2% | Outage MW-days ÷ monitored capacity-days |
| Forced Share of outage loss | 37.5% | Share of outage MW-days with a forced cause |
| Median Recovery (Days) | 2.0 | Median episode duration |
| Forced trips repeating within 30 days | 55.5% | Repeats ÷ forced episodes |
| Outages still open at data end | 41 | Ongoing (censored) episodes |

## Data-quality notes

- 77 calendar days have no data in either the raw or the cleaned file.
- 5,943 rows have no monitored capacity; 28,231 rows have capacity 0 (about 62% are flagged as not operational, mainly "Unit Not Yet Commissioned"); none of them report a loss.
- 89 rows have `loss_mw` set to full capacity where the raw loss was blank (short-duration outages); the effect is under 0.1% of loss.
- `expected_sync_date` is almost always met, which suggests it is updated after the fact.
