SELECT account_id
FROM {{ ref('fact_accounts') }}
WHERE interest_rate < 0