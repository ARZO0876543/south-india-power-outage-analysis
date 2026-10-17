-- =====================================================================
-- South India power outage analysis: SQL queries (SQLite syntax)
--
-- Tables (built by notebooks/03_sql_analysis.ipynb):
--   daily     one row per unit per day (cleaned_south_outage_powerbi),
--             plus outage_loss_mw = loss_mw excluding shortfall rows
--   episodes  one row per unit outage episode (reports/tables/episodes.csv)
--
-- Definitions
--   outage loss  = loss_mw where shortfall_not_outage = 0 (real outages)
--   shortfall    = loss_mw where shortfall_not_outage = 1 (low schedule / reserve shutdown)
--   MW-days      = capacity lost, summed over days (not energy)
--   loss rate    = outage MW-days / monitored capacity-days
-- Each query starts with "-- name: <id>" so the notebook can run them one by one.
-- =====================================================================

-- name: q01_yearly_trend
-- Outage loss per year. Averages are used because years have unequal days of data.
SELECT Year,
       COUNT(DISTINCT date)                                   AS days_observed,
       ROUND(SUM(outage_loss_mw))                             AS outage_mw_days,
       ROUND(SUM(outage_loss_mw) * 1.0 / COUNT(DISTINCT date)) AS avg_daily_outage_mw
FROM daily
GROUP BY Year
ORDER BY Year;

-- name: q02_state_ranking
-- Share of outage loss and loss rate by state.
SELECT state_name,
       ROUND(SUM(outage_loss_mw))                                                   AS outage_mw_days,
       ROUND(100.0 * SUM(outage_loss_mw) / SUM(SUM(outage_loss_mw)) OVER (), 1)     AS share_of_outage_loss_pct,
       ROUND(100.0 * SUM(CASE WHEN monitored_capacity IS NOT NULL THEN outage_loss_mw END)
             / SUM(monitored_capacity), 1)                                          AS loss_rate_pct
FROM daily
GROUP BY state_name
ORDER BY outage_mw_days DESC;

-- name: q03_loss_by_cause
-- What the outage loss is made of: forced vs planned vs commercial.
SELECT cause_category,
       ROUND(SUM(outage_loss_mw))                                               AS outage_mw_days,
       ROUND(100.0 * SUM(outage_loss_mw) / SUM(SUM(outage_loss_mw)) OVER (), 1) AS share_pct
FROM daily
WHERE outage_loss_mw > 0 AND cause_category <> 'No loss'
GROUP BY cause_category
ORDER BY outage_mw_days DESC;

-- name: q04_station_pareto
-- Stations ranked by outage loss with cumulative share (window function).
WITH s AS (
    SELECT power_station, state_name, fuel_type, SUM(outage_loss_mw) AS mw_days
    FROM daily
    GROUP BY power_station, state_name, fuel_type
    HAVING SUM(outage_loss_mw) > 0
)
SELECT ROW_NUMBER() OVER (ORDER BY mw_days DESC)                                   AS station_rank,
       power_station, state_name, fuel_type,
       ROUND(mw_days)                                                              AS outage_mw_days,
       ROUND(100.0 * SUM(mw_days) OVER (ORDER BY mw_days DESC) / SUM(mw_days) OVER (), 1) AS cumulative_share_pct
FROM s
ORDER BY mw_days DESC
LIMIT 20;

-- name: q05_fuel_outage_vs_shortfall
-- Outage and shortfall by fuel. Gas, hydro and diesel loss is shortfall, not breakdowns.
SELECT fuel_type,
       ROUND(SUM(outage_loss_mw))                              AS outage_mw_days,
       ROUND(SUM(loss_mw - outage_loss_mw))                    AS shortfall_mw_days,
       ROUND(100.0 * SUM(loss_mw - outage_loss_mw) / NULLIF(SUM(loss_mw), 0), 1) AS shortfall_share_pct
FROM daily
GROUP BY fuel_type
ORDER BY outage_mw_days DESC;

-- name: q06_median_recovery_by_cause
-- Median episode duration by cause (SQLite has no MEDIAN, so rank the rows).
WITH r AS (
    SELECT cause, duration_days,
           ROW_NUMBER() OVER (PARTITION BY cause ORDER BY duration_days) AS rn,
           COUNT(*)     OVER (PARTITION BY cause)                         AS n
    FROM episodes
)
SELECT cause,
       MAX(n)                 AS episodes,
       AVG(duration_days)     AS median_days
FROM r
WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
GROUP BY cause
ORDER BY median_days DESC;

-- name: q07_long_outage_concentration
-- A small share of outages carries most of the lost capacity.
SELECT CASE WHEN duration_days <= 2  THEN '1: 0-2 days'
            WHEN duration_days <= 7  THEN '2: 3-7 days'
            WHEN duration_days <= 30 THEN '3: 8-30 days'
            ELSE                          '4: over 30 days' END AS duration_band,
       COUNT(*)                                                     AS episodes,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct_of_episodes,
       ROUND(100.0 * SUM(mw_days) / SUM(SUM(mw_days)) OVER (), 1)   AS pct_of_outage_mw_days
FROM episodes
GROUP BY duration_band
ORDER BY duration_band;

-- name: q08_repeat_failures
-- Forced trips that start within 30 days of the same unit's previous outage ending.
WITH f AS (
    SELECT power_station || ' | ' || power_station_unit AS unit,
           state, outage_date,
           LAG(last_seen) OVER (PARTITION BY power_station, power_station_unit
                                ORDER BY outage_date, last_seen)  AS prev_end
    FROM episodes
    WHERE cause = 'Technical (forced)'
)
SELECT unit, state,
       COUNT(*) AS forced_episodes,
       SUM(CASE WHEN julianday(outage_date) - julianday(prev_end) BETWEEN 0 AND 30 THEN 1 ELSE 0 END) AS repeats,
       ROUND(100.0 * SUM(CASE WHEN julianday(outage_date) - julianday(prev_end) BETWEEN 0 AND 30 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_pct
FROM f
GROUP BY unit, state
ORDER BY repeats DESC, forced_episodes DESC
LIMIT 15;

-- name: q09_seasonality
-- Average daily outage loss by calendar month (all years).
SELECT CAST(strftime('%m', date) AS INTEGER)                    AS month,
       ROUND(SUM(outage_loss_mw) * 1.0 / COUNT(DISTINCT date))  AS avg_daily_outage_mw
FROM daily
GROUP BY month
ORDER BY month;

-- name: q10_data_quality
-- Checks to run before trusting any total.
SELECT 'duplicate unit-day keys' AS check_name,
       COUNT(*) - COUNT(DISTINCT date || '|' || state_name || '|' || power_station || '|' || power_station_unit) AS value
FROM daily
UNION ALL
SELECT 'calendar days with no data',
       CAST(julianday(MAX(date)) - julianday(MIN(date)) + 1 - COUNT(DISTINCT date) AS INTEGER)
FROM daily
UNION ALL
SELECT 'rows missing monitored_capacity', COUNT(*) FROM daily WHERE monitored_capacity IS NULL
UNION ALL
SELECT 'rows where loss_mw > monitored_capacity', COUNT(*) FROM daily WHERE loss_mw > monitored_capacity
UNION ALL
SELECT 'episodes still open at end of data', COUNT(*) FROM episodes WHERE recovered = 0;
