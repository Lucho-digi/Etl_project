SELECT account_id
FROM {{ ref('fact_accounts') }}
WHERE branch_code !~ '^BR-[0-9]{3}$'