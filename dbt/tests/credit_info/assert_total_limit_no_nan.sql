SELECT customer_id
FROM {{ ref('silver_credit_info') }}
WHERE total_limit != total_limit

