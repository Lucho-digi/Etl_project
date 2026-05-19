SELECT transaction_id
FROM {{ ref('fact_transactions') }}
WHERE amount < 0
