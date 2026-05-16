{{ config(materialized='table') }}

SELECT
  data->>'customer_id'                                             as customer_id,
  (data->'digital_engagement'->>'mobile_app_registered')::boolean  as mobile_app_registered,
  (data->'digital_engagement'->>'web_banking_registered')::boolean as web_banking_registered,
  data->'digital_engagement'->>'last_login_date'                   as last_login_date,
  (data->'digital_engagement'->>'avg_monthly_logins')::int         as avg_monthly_logins,
  data->'digital_engagement'->>'preferred_channel'                 as preferred_channel,
  (data->'digital_engagement'->>'push_notifications')::boolean     as push_notifications,
  (data->'digital_engagement'->>'paperless_statements')::boolean   as paperless_statements,
  load_timestamp
FROM {{ source('silver', 'stg_raw_deduplicated')  }}