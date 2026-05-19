SELECT customer_id
FROM {{ ref('fact_credit_info') }}
WHERE total_limit IS NOT NULL
  AND total_used IS NOT NULL
  AND total_limit < total_used
