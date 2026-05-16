{{ config(materialized='table') }}
SELECT
  customer_id,
  loan_id,
  lower(trim(type))                                       as type,
  upper(trim(currency))                                   as currency,
  principal::float                                        as principal,
  outstanding_balance::float                              as outstanding_balance,
  interest_rate::float                                    as interest_rate,
  term_months::int                                        as term_months,
  monthly_payment::float                                  as monthly_payment,
  start_date::date                                        as start_date,
  end_date::date                                          as end_date,
  lower(trim(status))                                     as status, 
  trim(collateral_type)                                   as collateral_type
FROM {{ source('silver', 'stg_loans') }}