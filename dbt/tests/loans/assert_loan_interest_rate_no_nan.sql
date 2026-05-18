SELECT loan_id
FROM {{ ref('silver_loans') }}
WHERE interest_rate != interest_rate

