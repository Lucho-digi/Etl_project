SELECT customer_id
FROM {{ ref('silver_customers') }}
WHERE email IS NOT NULL
  AND email !~ '^[\w.%+\-'']+@[\w.\-]+\.[\w]{2,}$'
