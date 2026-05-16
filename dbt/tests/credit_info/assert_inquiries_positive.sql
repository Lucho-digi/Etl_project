SELECT customer_id
FROM {{ ref('silver_credit_info') }}
WHERE inquiries_6m < 0