{{ config(materialized='table') }}

{% set email_regex = "^[\\w.%+\\-]+@[\\w.\\-]+\\.[\\w]{2,}$" %}

WITH raw AS (
  SELECT
    {{ jsonb_extract('data', 'customer_id') }}                                   as customer_id,
    {{ jsonb_extract('data', 'first_name') }}                                    as first_name,
    {{ jsonb_extract('data', 'last_name') }}                                     as last_name,
    {{ jsonb_extract('data', 'email') }}                                         as email,
    {{ jsonb_extract('data', 'phone_number') }}                                  as phone_number,
    {{ jsonb_extract('data', 'date_of_birth') }}                                 as _date_of_birth,
    {{ jsonb_extract('data', 'gender') }}                                        as gender,
    {{ jsonb_extract('data', 'nationality') }}                                   as nationality,
    {{ jsonb_extract('data', 'city') }}                                          as city,
    {{ jsonb_extract('data', 'country') }}                                       as country,
    {{ jsonb_extract('data', 'address') }}                                       as address,
    {{ jsonb_extract('data', 'lat') }}                                           as lat,
    {{ jsonb_extract('data', 'lon') }}                                           as lon,
    {{ jsonb_extract('data', 'registration_date') }}                             as _registration_date,
    {{ jsonb_extract('data', 'kyc_status') }}                                    as kyc_status,
    {{ jsonb_extract('data', 'risk_score') }}                                    as risk_score,
    {{ jsonb_extract('data', 'customer_segment') }}                              as customer_segment,
    {{ jsonb_extract('data', 'relationship_manager') }}                          as relationship_manager,
    {{ jsonb_extract('data', 'status') }}                                        as status,
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
    case
    -- AR
      when lower(trim(city)) in ('buenos aire') then 'Buenos Aires'
      when lower(trim(city)) in ('cordba') then 'Cordoba'
      when lower(trim(city)) in ('mendza') then 'Mendoza'
      when lower(trim(city)) in ('rosaro') then 'Rosario'
      when lower(trim(city)) in ('tucman') then 'Tucuman'
      -- BR
      when lower(trim(city)) in ('brasila') then 'Brasilia'
      when lower(trim(city)) in ('fortalza') then 'Fortaleza'
      when lower(trim(city)) in ('rio de janero') then 'Rio De Janeiro'
      when lower(trim(city)) in ('salvdor') then 'Salvador'
      when lower(trim(city)) in ('sao paulp') then 'Sao Paulo'
      -- CL
      when lower(trim(city)) in ('concepcin') then 'Concepcion'
      when lower(trim(city)) in ('la serna') then 'La Serena'
      when lower(trim(city)) in ('santiag') then 'Santiago'
      when lower(trim(city)) in ('temco') then 'Temuco'
      -- CO
      when lower(trim(city)) in ('barranquila') then 'Barranquilla'
      when lower(trim(city)) in ('bogta') then 'Bogota'
      when lower(trim(city)) in ('cai') then 'Cali'
      when lower(trim(city)) in ('cartagna') then 'Cartagena'
      when lower(trim(city)) in ('medelin') then 'Medellin'
      -- MX
      when lower(trim(city)) in ('ciudd de mexico') then 'Ciudad De Mexico'
      when lower(trim(city)) in ('guadalajra') then 'Guadalajara'
      when lower(trim(city)) in ('monterry') then 'Monterrey'
      when lower(trim(city)) in ('puebl') then 'Puebla'
      when lower(trim(city)) in ('tijana') then 'Tijuana'
      -- PE
      when lower(trim(city)) in ('arequpa') then 'Arequipa'
      when lower(trim(city)) in ('cusc') then 'Cusco'
      when lower(trim(city)) in ('lma') then 'Lima'
      when lower(trim(city)) in ('piua') then 'Piura'
      when lower(trim(city)) in ('trujllo') then 'Trujillo'
      -- UY
      when lower(trim(city)) in ('maldonad') then 'Maldonado'
      when lower(trim(city)) in ('montevide') then 'Montevideo'
      when lower(trim(city)) in ('paysand') then 'Paysandu'
      when lower(trim(city)) in ('rivra') then 'Rivera'
      when lower(trim(city)) in ('saltp') then 'Salto'
      else initcap(trim(city))
    end as city,
    {{ trim_upper('country') }}                                       as country,
    nullif(trim(address), '')                                         as address,
    CASE WHEN lat::float BETWEEN -90 AND 90 THEN lat::float END       as lat,
    CASE WHEN lon::float BETWEEN -180 AND 180 THEN lon::float END     as lon,
    {{ parse_date('_registration_date') }}                            as registration_date,
    {{ trim_lower('kyc_status') }}                                    as kyc_status,
    risk_score::float                                                 as risk_score,
    {{ map_values('customer_segment', {'pyme': 'sme', 'minorista': 'retail', 'banca_privada': 'private_banking'}) }} as customer_segment,
    nullif(trim(relationship_manager), '')                           as relationship_manager,
    {{ map_values('status', {'activo': 'active', 'inactivo': 'inactive', 'suspendido': 'suspended', 'cerrado': 'closed'}) }} as status,
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
  AND registration_date <= CURRENT_DATE
  AND risk_score IS NOT NULL
  AND status IS NOT NULL
  AND customer_segment IS NOT NULL
  AND kyc_status IS NOT NULL
