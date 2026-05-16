{{config(materialized='table')}}


SELECT
  data->>'customer_id'                                     as customer_id,
  (data->'credit_info'->>'credit_score')::int              as credit_score,
  data->'credit_info'->>'currency'                         as currency,
  (data->'credit_info'->>'utilization_pct')::float         as utilization_pct,
  (data->'credit_info'->>'total_limit')::float             as total_limit,
  (data->'credit_info'->>'total_used')::float              as total_used,
  (data->'credit_info'->>'num_credit_accounts')::int       as num_credit_accounts,
  (data->'credit_info'->>'oldest_account_age_months')::int as oldest_account_age_months,
  (data->'credit_info'->>'late_payments_12m')::int         as late_payments_12m,
  (data->'credit_info'->>'inquiries_6m')::int              as inquiries_6m,
  (data->'credit_info'->>'bankruptcy_flag')::boolean       as bankruptcy_flag,
  load_timestamp
FROM {{ source('silver', 'stg_raw_deduplicated')  }}


