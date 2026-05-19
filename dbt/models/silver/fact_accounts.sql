{{ config(materialized='table') }}

WITH raw AS (
  SELECT
    customer_id,
    account_id,
    account_type,
    currency,
    balance,
    credit_limit,
    interest_rate,
    opened_date,
    status,
    branch_code
  FROM {{ source('silver', 'stg_accounts') }}
),
parsed AS (
  SELECT
    customer_id,
    account_id,
    {{ trim_lower('account_type') }}                                  as account_type,
    {{ trim_upper('currency') }}                                      as currency,
    {{ clean_numeric('balance') }}                                    as balance,
    credit_limit                                                      as credit_limit,
    interest_rate                                                     as interest_rate,
    {{ parse_date('opened_date') }}                                   as _opened_date_raw,
    {{ map_values('status', {'activo': 'active', 'cerrado': 'closed', 'congelado': 'frozen'}) }} as status,
    trim(branch_code)                                                 as branch_code
  FROM raw
),
cleaned AS (
  SELECT
    customer_id,
    account_id,
    account_type,
    currency,
    balance,
    credit_limit,
    interest_rate,
    {{ clean_future_date('_opened_date_raw') }} as opened_date,
    status,
    branch_code
  FROM parsed
)

SELECT
  customer_id,
  account_id,
  account_type,
  currency,
  balance,
  credit_limit,
  interest_rate,
  opened_date,
  status,
  branch_code
FROM cleaned
WHERE customer_id IS NOT NULL
  AND account_id IS NOT NULL
  AND account_type IS NOT NULL
  AND balance IS NOT NULL
  AND interest_rate IS NOT NULL
  AND status IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM {{ ref('dim_customers') }})
