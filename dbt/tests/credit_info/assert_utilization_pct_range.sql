SELECT customer_id
FROM {{ ref('silver_credit_info') }}
WHERE utilization_pct < 0 OR utilization_pct > 100