SELECT account_id
FROM {{ ref('silver_accounts') }}
WHERE credit_limit < 0