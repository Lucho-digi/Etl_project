SELECT customer_id
FROM {{ ref('dim_customers') }}
WHERE lat != lat

