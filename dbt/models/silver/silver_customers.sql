{{ config(materialized='table') }}

{% set email_regex = "^[\\w.%+\\-]+@[\\w.\\-]+\\.[\\w]{2,}$" %}

WITH raw AS (
  SELECT
    data::jsonb->>'customer_id'                                   as customer_id,
    data::jsonb->>'first_name'                                    as first_name,
    data::jsonb->>'last_name'                                     as last_name,
    data::jsonb->>'email'                                         as email,
    data::jsonb->>'phone_number'                                  as phone_number,
    data::jsonb->>'date_of_birth'                                 as _date_of_birth,
    data::jsonb->>'gender'                                        as gender,
    data::jsonb->>'nationality'                                   as nationality,
    data::jsonb->>'city'                                          as city,
    data::jsonb->>'country'                                       as country,
    data::jsonb->>'address'                                       as address,
    data::jsonb->>'lat'                                           as lat,
    data::jsonb->>'lon'                                           as lon,
    data::jsonb->>'registration_date'                             as _registration_date,
    data::jsonb->>'kyc_status'                                    as kyc_status,
    data::jsonb->>'risk_score'                                    as risk_score,
    data::jsonb->>'customer_segment'                              as customer_segment,
    data::jsonb->>'relationship_manager'                          as relationship_manager,
    data::jsonb->>'status'                                        as status,
    load_timestamp
  FROM {{ source('silver', 'stg_raw_deduplicated') }}
),

transformed AS (
  SELECT
    customer_id,
    initcap(trim(first_name))                                         as first_name,
    initcap(trim(last_name))                                          as last_name,
    CASE
      WHEN lower(regexp_replace(trim(email), '^@+', '')) ~* '{{ email_regex }}'
      THEN lower(regexp_replace(trim(email), '^@+', ''))
    END                                                               as email,
    CASE
      WHEN trim(phone_number) ~ '^\+[0-9\s\-]{7,20}$'
      THEN regexp_replace(regexp_replace(trim(phone_number), '\s', '', 'g'), '-', '', 'g')
    END                                                               as phone_number,
    {{ parse_date('_date_of_birth') }}                                as date_of_birth,
    CASE
      WHEN {{ trim_lower('gender') }} IN ('m', 'male', 'masculino') THEN 'M'
      WHEN {{ trim_lower('gender') }} IN ('f', 'female', 'femenino') THEN 'F'
      ELSE 'Other'
    END                                                               as gender,
    {{ trim_upper('nationality') }}                                   as nationality,
    initcap(trim(city))                                               as city,
    {{ trim_upper('country') }}                                       as country,
    nullif(trim(address), '')                                         as address,
    CASE WHEN lat::float BETWEEN -90 AND 90 THEN lat::float END       as lat,
    CASE WHEN lon::float BETWEEN -180 AND 180 THEN lon::float END     as lon,
    {{ parse_date('_registration_date') }}                            as registration_date,
    {{ trim_lower('kyc_status') }}                                    as kyc_status,
    risk_score::float                                                 as risk_score,
    CASE {{ trim_lower('customer_segment') }}
      WHEN 'pyme' THEN 'sme'
      WHEN 'minorista' THEN 'retail'
      WHEN 'banca_privada' THEN 'private_banking'
      ELSE {{ trim_lower('customer_segment') }}
    END                                                               as customer_segment,
    nullif(trim(relationship_manager), '')                           as relationship_manager,
    CASE {{ trim_lower('status') }}
      WHEN 'activo'     THEN 'active'
      WHEN 'inactivo'   THEN 'inactive'
      WHEN 'suspendido' THEN 'suspended'
      WHEN 'cerrado'    THEN 'closed'
      ELSE {{ trim_lower('status') }}
    END                                                               as status,
    load_timestamp
  FROM raw
)

SELECT *
FROM transformed
WHERE customer_id IS NOT NULL
  AND gender IS NOT NULL
  AND phone_number IS NOT NULL
  AND date_of_birth IS NOT NULL
  AND country IS NOT NULL
  AND registration_date IS NOT NULL
  AND risk_score IS NOT NULL
  AND status IS NOT NULL
  AND customer_segment IS NOT NULL
  AND kyc_status IS NOT NULL
