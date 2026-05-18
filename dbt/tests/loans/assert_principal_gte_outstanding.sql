SELECT loan_id
FROM {{ ref('silver_loans') }}
WHERE principal < outstanding_balance
