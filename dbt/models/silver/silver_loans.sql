{{ config(materialized='table') }}

WITH raw AS (
  SELECT
    customer_id,
    loan_id,
    type,
    currency,
    principal,
    outstanding_balance,
    interest_rate,
    term_months,
    monthly_payment,
    start_date,
    end_date,
    status,
    days_past_due,
    collateral_type
  FROM {{ source('silver', 'stg_loans') }}
)

SELECT
  customer_id,
  loan_id,
  {{ trim_lower('type') }}                                          as type,
  {{ trim_upper('currency') }}                                      as currency,
  {{ clean_numeric('principal') }}                                  as principal,
  {{ clean_numeric('outstanding_balance') }}                        as outstanding_balance,
  interest_rate                                                     as interest_rate,
  term_months                                                       as term_months,
  {{ clean_numeric('monthly_payment') }}                            as monthly_payment,
  {{ parse_date('start_date') }}                                    as start_date,
  {{ parse_date('end_date') }}                                      as end_date,
  {{ trim_lower('status') }}                                        as status,
  days_past_due                                                     as days_past_due,
  CASE WHEN {{ trim_lower('collateral_type') }} IN ('', 'na', 'n/a', 'null') THEN NULL
    ELSE {{ trim_lower('collateral_type') }} END                 as collateral_type
FROM raw
WHERE loan_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND principal IS NOT NULL
  AND interest_rate IS NOT NULL
  AND term_months IS NOT NULL
  AND start_date IS NOT NULL
  AND end_date IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM {{ ref('silver_customers') }})
