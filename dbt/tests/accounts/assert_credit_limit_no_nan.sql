SELECT account_id
FROM {{ ref('fact_accounts') }}
WHERE credit_limit != credit_limit

