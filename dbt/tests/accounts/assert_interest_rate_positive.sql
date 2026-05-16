SELECT account_id
FROM {{ ref('silver_accounts') }}
WHERE interest_rate < 0