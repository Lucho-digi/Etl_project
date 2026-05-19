SELECT customer_id
FROM {{ ref('dim_customers') }}
WHERE email IS NOT NULL
  AND email !~ '^[\w.%+\-'']+@[\w.\-]+\.[\w]{2,}$'
