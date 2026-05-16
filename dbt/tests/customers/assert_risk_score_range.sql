SELECT customer_id
FROM {{ ref('silver_customers') }}
WHERE risk_score < 0 OR risk_score > 100