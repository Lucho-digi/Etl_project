SELECT customer_id
FROM {{ ref('fact_loans') }}
WHERE loan_id IS NOT NULL AND customer_id IS NULL