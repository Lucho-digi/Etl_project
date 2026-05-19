SELECT account_id
FROM {{ ref('fact_accounts') }}
WHERE opened_date > CURRENT_DATE
