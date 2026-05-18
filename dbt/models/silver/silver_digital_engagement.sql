{{ config(materialized='table') }}

WITH raw AS (
  SELECT
    data::jsonb->>'customer_id'                                   as customer_id,
    data::jsonb->'digital_engagement'->>'mobile_app_registered'   as mobile_app_registered,
    data::jsonb->'digital_engagement'->>'web_banking_registered'  as web_banking_registered,
    data::jsonb->'digital_engagement'->>'last_login_date'         as last_login_date,
    data::jsonb->'digital_engagement'->>'avg_monthly_logins'      as avg_monthly_logins,
    data::jsonb->'digital_engagement'->>'preferred_channel'       as preferred_channel,
    data::jsonb->'digital_engagement'->>'push_notifications'      as push_notifications,
    data::jsonb->'digital_engagement'->>'paperless_statements'    as paperless_statements,
    load_timestamp
  FROM {{ source('silver', 'stg_raw_deduplicated') }}
),
parsed AS (
  SELECT
    customer_id,
    {{ clean_boolean('mobile_app_registered') }}                      as mobile_app_registered,
    {{ clean_boolean('web_banking_registered') }}                     as web_banking_registered,
    {{ parse_date('last_login_date') }}                               as _last_login_date_raw,
    CASE WHEN avg_monthly_logins ~ '^\d+$'
          THEN avg_monthly_logins::int END                           as avg_monthly_logins,
    CASE {{ trim_lower('preferred_channel') }}
        WHEN 'phone' THEN 'call_center'
        ELSE {{ trim_lower('preferred_channel') }}
    END                                                               as preferred_channel,
    {{ clean_boolean('push_notifications') }}                         as push_notifications,
    {{ clean_boolean('paperless_statements') }}                       as paperless_statements,
    load_timestamp
  FROM raw
),
cleaned AS (
  SELECT
    customer_id,
    mobile_app_registered,
    web_banking_registered,
    CASE WHEN _last_login_date_raw > CURRENT_DATE THEN NULL ELSE _last_login_date_raw END as _last_login_date,
    avg_monthly_logins,
    preferred_channel,
    push_notifications,
    paperless_statements,
    load_timestamp
  FROM parsed
)

SELECT
  customer_id,
  mobile_app_registered,
  web_banking_registered,
  _last_login_date as last_login_date,
  avg_monthly_logins,
  preferred_channel,
  push_notifications,
  paperless_statements,
  load_timestamp
FROM cleaned
WHERE customer_id IS NOT NULL
  AND preferred_channel IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM {{ ref('silver_customers') }})
