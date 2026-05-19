SELECT customer_id
FROM {{ ref('dim_customers') }}
WHERE phone_number IS NOT NULL
  AND phone_number !~ '^\+[0-9]+$'
