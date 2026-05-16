{{ config(materialized='table') }}
SELECT
  customer_id,
  account_id,
  lower(trim(account_type))                               as account_type,
  upper(currency)                                         as currency,
  balance::float                                          as balance,
  credit_limit::float                                     as credit_limit,
  interest_rate::float                                    as interest_rate,
  opened_date::date                                       as opened_date,
  CASE lower(status)
    WHEN 'active'    THEN 'active'
    WHEN 'activo'    THEN 'active'
    WHEN 'closed'    THEN 'closed'
    WHEN 'cerrado'   THEN 'closed'
    WHEN 'frozen'    THEN 'frozen'
    WHEN 'congelado' THEN 'frozen'
    ELSE NULL
  END                                                     as status,
  trim(branch_code) as branch_code                        as branch_code
FROM {{ source('silver', 'stg_accounts') }}