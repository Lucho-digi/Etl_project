{{ config(materialized='table') }}

WITH min_max AS (
  SELECT
    COALESCE(MIN(earliest_date), '2015-01-01'::date) AS min_date,
    COALESCE(MAX(latest_date), CURRENT_DATE) AS max_date
  FROM (
    SELECT MIN(registration_date) AS earliest_date, MAX(registration_date) AS latest_date FROM {{ ref('dim_customers') }}
    UNION ALL
    SELECT MIN(opened_date), MAX(opened_date) FROM {{ ref('fact_accounts') }}
    UNION ALL
    SELECT MIN(transaction_date), MAX(transaction_date) FROM {{ ref('fact_transactions') }}
    UNION ALL
    SELECT MIN(start_date), MAX(end_date) FROM {{ ref('fact_loans') }}
    UNION ALL
    SELECT MIN(last_login_date), MAX(last_login_date) FROM {{ ref('fact_digital_engagement') }}
  ) combined
),

date_spine AS (
  SELECT generate_series(
      (SELECT min_date FROM min_max),
      (SELECT max_date FROM min_max),
      '1 day'::interval
  )::date AS full_date
)

SELECT
  TO_CHAR(full_date, 'YYYYMMDD')::int AS date_key,
  full_date,
  EXTRACT(YEAR FROM full_date)::int AS year,
  EXTRACT(QUARTER FROM full_date)::int AS quarter,
  EXTRACT(MONTH FROM full_date)::int AS month,
  TRIM(TO_CHAR(full_date, 'Month')) AS month_name,
  EXTRACT(DAY FROM full_date)::int AS day,
  EXTRACT(DOW FROM full_date)::int AS day_of_week,
  TRIM(TO_CHAR(full_date, 'Day')) AS day_name,
  CASE WHEN EXTRACT(DOW FROM full_date) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
  EXTRACT(WEEK FROM full_date)::int AS week_of_year
FROM date_spine
