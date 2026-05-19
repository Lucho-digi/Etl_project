SELECT customer_id
FROM {{ ref('fact_credit_info') }}
WHERE inquiries_6m < 0