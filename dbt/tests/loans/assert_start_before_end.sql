SELECT loan_id
FROM {{ ref('silver_loans') }}
WHERE start_date > end_date
