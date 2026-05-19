SELECT customer_id
FROM {{ ref('dim_customers') }}
WHERE risk_score != risk_score

