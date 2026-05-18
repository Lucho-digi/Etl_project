SELECT customer_id
FROM {{ ref('silver_credit_info') }}
WHERE utilization_pct != utilization_pct

