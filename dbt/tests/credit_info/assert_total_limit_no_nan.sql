SELECT customer_id
FROM {{ ref('fact_credit_info') }}
WHERE total_limit != total_limit

