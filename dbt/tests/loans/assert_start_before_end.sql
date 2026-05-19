SELECT loan_id
FROM {{ ref('fact_loans') }}
WHERE start_date > end_date
