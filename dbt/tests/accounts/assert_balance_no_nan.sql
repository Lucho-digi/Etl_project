SELECT account_id
FROM {{ ref('fact_accounts') }}
WHERE balance != balance

