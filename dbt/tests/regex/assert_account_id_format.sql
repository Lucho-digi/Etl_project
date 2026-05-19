SELECT account_id
FROM {{ ref('fact_accounts') }}
WHERE account_id !~ '^ACC-[A-F0-9]{12}$'
