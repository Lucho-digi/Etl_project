SELECT customer_id
FROM {{ ref('fact_credit_info') }}
WHERE total_used != total_used

