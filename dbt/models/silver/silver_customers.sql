{{ config(materialized='table') }}

{% set email_regex = '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' %}

select
  data->>'customer_id'                                    as customer_id,
  initcap(trim(data->>'first_name'))                      as first_name,
  initcap(trim(data->>'last_name'))                       as last_name,
  CASE 
    WHEN data->>'email' ~* {{ email_regex }} 
    THEN lower(trim(data->>'email'))
    ELSE NULL
  END as email,
  trim(data->>'phone_number')                             as phone_number,
  (data->>'date_of_birth')::date                          as date_of_birth,
  initcap(data->>'gender')                                as gender,
  upper(data->>'nationality')                             as nationality,
  initcap(trim(data->>'city'))                            as city,
  upper(data->>'country')                                 as country,
  trim(data->>'address')                                  as address,
  (data->>'lat')::float                                   as lat,
  (data->>'lon')::float                                   as lon,
  (data->>'registration_date')::date                      as registration_date,
  lower(data->>'kyc_status')                              as kyc_status,
  (data->>'risk_score')::float                            as risk_score,
  lower(data->>'customer_segment')                        as customer_segment,
  initcap(trim(data->>'relationship_manager'))            as relationship_manager,
  CASE lower(data->>'status')
    WHEN 'activo'     THEN 'active'
    WHEN 'inactivo'   THEN 'inactive'
    WHEN 'suspendido' THEN 'suspended'
    WHEN 'cerrado'    THEN 'closed'
    ELSE lower(data->>'status')
  END                                                     as status,
  load_timestamp
from {{ source('silver', 'stg_raw_deduplicated') }}