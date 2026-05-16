{{ config(materialized='table') }}
SELECT *
FROM {{ source('raw','raw_fintech_data') }}
