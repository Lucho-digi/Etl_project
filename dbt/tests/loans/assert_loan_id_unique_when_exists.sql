SELECT loan_id, COUNT(*)
FROM {{ ref('silver_loans') }}
WHERE loan_id IS NOT NULL
GROUP BY loan_id
HAVING COUNT(*) > 1