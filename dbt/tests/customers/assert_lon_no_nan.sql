SELECT customer_id
FROM {{ ref('silver_customers') }}
WHERE lon != lon

