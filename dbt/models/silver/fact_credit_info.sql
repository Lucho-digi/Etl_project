{{ config(materialized='table') }}

WITH raw AS (
  SELECT
    {{ jsonb_extract('data', 'customer_id') }}                                   as customer_id,
    {{ jsonb_extract('data', 'credit_info.credit_score') }}                    as credit_score,
    {{ jsonb_extract('data', 'credit_info.currency') }}                        as currency,
    {{ jsonb_extract('data', 'credit_info.utilization_pct') }}                 as utilization_pct,
    {{ jsonb_extract('data', 'credit_info.total_limit') }}                     as total_limit,
    {{ jsonb_extract('data', 'credit_info.total_used') }}                      as total_used,
    {{ jsonb_extract('data', 'credit_info.num_credit_accounts') }}             as num_credit_accounts,
    {{ jsonb_extract('data', 'credit_info.oldest_account_age_months') }}       as oldest_account_age_months,
    {{ jsonb_extract('data', 'credit_info.late_payments_12m') }}               as late_payments_12m,
    {{ jsonb_extract('data', 'credit_info.inquiries_6m') }}                    as inquiries_6m,
    {{ jsonb_extract('data', 'credit_info.bankruptcy_flag') }}                as bankruptcy_flag,
    load_timestamp
  FROM {{ source('silver', 'stg_raw_deduplicated') }}
)

SELECT
  customer_id,
  CASE
      WHEN credit_score::int <= 0 THEN NULL
      WHEN credit_score::int >= 999 THEN NULL
      ELSE {{ clamp('credit_score::int', 300, 850) }}
  END                                                               as credit_score,
  {{ trim_upper('currency') }}                                      as currency,
  {{ clamp(clean_numeric('utilization_pct'), 0, 100) }}             as utilization_pct,
  {{ clean_numeric('total_limit') }}                                as total_limit,
  {{ clean_numeric('total_used') }}                                 as total_used,
  num_credit_accounts::int                                          as num_credit_accounts,
  oldest_account_age_months::int                                    as oldest_account_age_months,
  late_payments_12m::int                                            as late_payments_12m,
  inquiries_6m::int                                                 as inquiries_6m,
  {{ clean_boolean('bankruptcy_flag') }}                            as bankruptcy_flag,
  load_timestamp
FROM raw
WHERE customer_id IS NOT NULL
  AND credit_score IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM {{ ref('dim_customers') }})
