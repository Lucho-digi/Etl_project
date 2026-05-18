SELECT account_id
FROM {{ ref('silver_accounts') }}
WHERE balance != balance

