# Cleaning rules (raw → cleaned)

Verified by joining the raw file to the cleaned file on `date + state_name + power_station + power_station_unit`.

| # | Rule | Rows / effect |
|---|---|---|
| 1 | Keep `region == "Southern"` | 4,265,703 → 1,031,557 |
| 2 | Keep dates 2018-01-01 to 2024-12-10 | → 957,828 |
| 3 | Drop duplicate unit-day records (same key, different `id`) | → 580,825 (377,003 removed) |
| 4 | Rename `station_type` → `fuel_type` and map to fuel names | 100% match |
| 5 | Blank `outage_type` → "No Outage" | 484,963 rows |
| 6 | `cap_under_outage` → `loss_mw`, blanks → 0 | 89 rows had a blank loss but `loss_mw` = full capacity |
| 7 | Blank `remarks` → "No remark" | 100% match |
| 8 | Drop `id`, `region`, `state_code` | |
| 9 | Add `Year`, `outage_age_days`, `not_operational`, `shortfall_not_outage`, `Major_Category1`, `cause_category`, `in_service`, `cause_recorded` | see `data/README.md` |

## Not reconstructed

These were reverse-engineered from the two files, not from the original cleaning code:

- Which record was kept among 253 duplicate keys with slightly different values (the first occurrence matches the cleaned file).
- The exact rule behind `cause_category` (it depends on more than remark and loss) and `in_service`.

If you have the original cleaning script or Power Query steps, add them to `src/` and link them here.
