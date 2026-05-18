SELECT customer_id
FROM {{ ref('silver_credit_info') }}
WHERE total_used != total_used

