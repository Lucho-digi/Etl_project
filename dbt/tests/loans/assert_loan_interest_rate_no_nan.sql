SELECT loan_id
FROM {{ ref('fact_loans') }}
WHERE interest_rate != interest_rate

