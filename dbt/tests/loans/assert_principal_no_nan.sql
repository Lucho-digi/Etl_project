SELECT loan_id
FROM {{ ref('fact_loans') }}
WHERE principal != principal

