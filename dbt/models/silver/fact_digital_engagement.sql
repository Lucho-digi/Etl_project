{{ config(materialized='table') }}

WITH raw AS (
  SELECT
    {{ jsonb_extract('data', 'customer_id') }}                                   as customer_id,
    {{ jsonb_extract('data', 'digital_engagement.mobile_app_registered') }}   as mobile_app_registered,
    {{ jsonb_extract('data', 'digital_engagement.web_banking_registered') }}  as web_banking_registered,
    {{ jsonb_extract('data', 'digital_engagement.last_login_date') }}         as last_login_date,
    {{ jsonb_extract('data', 'digital_engagement.avg_monthly_logins') }}      as avg_monthly_logins,
    {{ jsonb_extract('data', 'digital_engagement.preferred_channel') }}       as preferred_channel,
    {{ jsonb_extract('data', 'digital_engagement.push_notifications') }}      as push_notifications,
    {{ jsonb_extract('data', 'digital_engagement.paperless_statements') }}    as paperless_statements,
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
    {{ map_values('preferred_channel', {'phone': 'call_center'}) }}   as preferred_channel,
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
    {{ clean_future_date('_last_login_date_raw') }} as last_login_date,
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
  last_login_date,
  avg_monthly_logins,
  preferred_channel,
  push_notifications,
  paperless_statements,
  load_timestamp
FROM cleaned
WHERE customer_id IS NOT NULL
  AND preferred_channel IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM {{ ref('dim_customers') }})
