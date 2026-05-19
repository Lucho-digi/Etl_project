SELECT loan_id
FROM {{ ref('fact_loans') }}
WHERE outstanding_balance != outstanding_balance

