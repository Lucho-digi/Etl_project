SELECT customer_id
FROM {{ ref('fact_credit_info') }}
WHERE utilization_pct != utilization_pct

