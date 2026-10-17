# South India Power Outage Analysis (2018 – Dec 2024)

Analysis of daily, unit-level power-plant outage records for the southern region of India
(Andhra Pradesh, Karnataka, Kerala, Tamil Nadu, Telangana, Puducherry, Lakshadweep).

The project covers three things:

1. **Data cleaning**: the raw national file (4.27M rows) reduced to a 580,825-row southern-region dataset, with a before/after comparison.
2. **Analysis**: loss, trends, states, causes, fuel types, recovery times, repeat failures, survival curves and a forecast.
3. **Power BI dashboard**: an interactive report built on the cleaned data.

## Key findings

All numbers come from `notebooks/02_outage_analysis_extended.ipynb`. *Outage loss* excludes demand/schedule
shortfalls (e.g. "Rsd/Low Schedule"), which are reported separately.

- Total outage loss: about **31.9 million MW-days** (shortfall adds a further 19.5 million MW-days).
- Average daily outage loss peaked in **2020** (19,185 MW) and was lowest in **2024** (8,795 MW).
- **Tamil Nadu** has the largest share of outage loss (36%); **Karnataka** has the highest loss rate relative to capacity (29.9%).
- **Coal/Lignite** accounts for 94% of outage MW-days. Gas, hydro and diesel show no recorded outages: all their loss is shortfall.
- The median outage lasts **2 days** (mean 10). Financial/legal causes are slowest to recover (median 114 days); forced technical outages are fastest (median 2 days).
- 41 outages were still ongoing when the data ends.

## Repository structure

```
.
├── README.md
├── requirements.txt
├── .gitignore
├── data/
│   ├── README.md                 # data sources, dictionary, how to get the big files
│   ├── raw/                      # (git-ignored) daily-power-outage.csv
│   ├── processed/                # (git-ignored) cleaned_south_outage_powerbi.csv
│   └── sample/
│       └── cleaned_sample_5k.csv # 5,000-row random sample of the cleaned data
├── notebooks/
│   ├── 01_before_after_cleaning.ipynb      # raw vs cleaned comparison + first look
│   └── 02_outage_analysis_extended.ipynb   # full analysis, episodes, reliability, forecast
├── reports/
│   └── tables/                   # analysis outputs used in Power BI
│       ├── episodes.csv          # one row per unit outage episode
│       ├── repeat_units.csv      # units that trip again soon after returning
│       ├── km_curves.csv         # Kaplan–Meier recovery curves by cause
│       └── forecast.csv          # monthly forecast with backtest
├── powerbi/
│   ├── south_outage_dashboard.pbix
│   └── assets/dashboard_background.png
├── docs/
│   ├── Daily_Power_Outage_codebook.xlsx    # original variable codebook
│   └── cleaning_rules.md                   # what changed between raw and cleaned
└── src/                          # (reserved for the cleaning script)
```

## How to run

```bash
git clone <your-repo-url>
cd south-india-power-outage-analysis
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

1. Download the data as described in [`data/README.md`](data/README.md) and place the files in `data/raw/` and `data/processed/`.
2. Run `jupyter lab` and open the notebooks in order (01, then 02).

Notebook 02 only needs the cleaned file. Notebook 01 also needs the raw file (about 480 MB).
Both notebooks are saved with their outputs, so you can read them on GitHub without running anything.

To open the dashboard, open `powerbi/south_outage_dashboard.pbix` in Power BI Desktop and
point the data source at your local `data/processed/cleaned_south_outage_powerbi.csv`.

## Limitations

- `loss_mw` is a daily snapshot of capacity, so totals are MW-days, not energy (MWh).
- 77 calendar days are missing from the source data.
- `outage_date` is blank for most outage rows from mid-November 2024; notebook 02 rebuilds it from each unit's earlier days.
- About 35% of lost MW-days have no recorded cause.
- Notebook 01 counts shortfall inside "loss". Use notebook 02 for the outage-only figures above.

## Data source

Daily Power Outage dataset (see `docs/Daily_Power_Outage_codebook.xlsx`). Retrieved 2025-04-30, last updated by the source on 2025-04-22.
Add the original source link in `data/README.md`.
