SELECT loan_id
FROM {{ ref('silver_loans') }}
WHERE outstanding_balance != outstanding_balance

