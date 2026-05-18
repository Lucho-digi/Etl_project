SELECT account_id
FROM {{ ref('silver_accounts') }}
WHERE opened_date > CURRENT_DATE
