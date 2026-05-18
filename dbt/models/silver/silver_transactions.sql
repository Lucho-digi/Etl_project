{{ config(materialized='table') }}

WITH raw AS (
  SELECT
    customer_id,
    transaction_id,
    account_id,
    date,
    amount,
    currency,
    type,
    category,
    merchant,
    channel,
    status,
    description
  FROM {{ source('silver', 'stg_transactions') }}
),
parsed AS (
  SELECT
    customer_id,
    transaction_id,
    account_id,
    {{ parse_date('date') }}                                          as _transaction_date,
    {{ clean_numeric('amount') }}                                     as amount,
    {{ trim_upper('currency') }}                                      as currency,
    CASE {{ trim_lower('type') }}
      WHEN 'deposito'      THEN 'deposit'
      WHEN 'retiro'        THEN 'withdrawal'
      WHEN 'transferencia' THEN 'transfer'
      WHEN 'pago'          THEN 'payment'
      WHEN 'reembolso'     THEN 'refund'
      WHEN 'comision'      THEN 'fee'
      ELSE {{ trim_lower('type') }}
    END                                                               as type,
    CASE WHEN {{ trim_lower('category') }} IN ('', 'na', 'n/a', 'null') THEN NULL
      ELSE {{ trim_lower('category') }} END                         as category,
    CASE WHEN {{ trim_lower('merchant') }} IN ('', 'na', 'n/a', 'null') THEN NULL
      ELSE initcap(trim(merchant)) END                             as merchant,
    {{ trim_lower('channel') }}                                       as channel,
    {{ trim_lower('status') }}                                        as status,
    CASE WHEN {{ trim_lower('description') }} IN ('', 'na', 'n/a', 'null') THEN NULL
      ELSE trim(description) END                                   as description
  FROM raw
)

SELECT
  customer_id,
  transaction_id,
  account_id,
  _transaction_date as transaction_date,
  amount,
  currency,
  type,
  category,
  merchant,
  channel,
  status,
  description
FROM parsed
WHERE transaction_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND account_id IS NOT NULL
  AND _transaction_date IS NOT NULL
  AND amount IS NOT NULL
  AND type IS NOT NULL
  AND channel IS NOT NULL
  AND status IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM {{ ref('silver_customers') }})
