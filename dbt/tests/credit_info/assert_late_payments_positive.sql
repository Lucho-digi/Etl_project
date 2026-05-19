SELECT customer_id
FROM {{ ref('fact_credit_info') }}
WHERE late_payments_12m < 0