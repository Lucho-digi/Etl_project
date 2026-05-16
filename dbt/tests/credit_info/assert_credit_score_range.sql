SELECT customer_id
FROM {{ ref('silver_credit_info') }}
WHERE credit_score < 300 OR credit_score > 850