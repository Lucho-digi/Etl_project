SELECT customer_id
FROM {{ ref('silver_customers') }}
WHERE risk_score != risk_score

