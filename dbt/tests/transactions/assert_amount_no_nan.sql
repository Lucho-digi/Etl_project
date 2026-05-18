SELECT transaction_id
FROM {{ ref('silver_transactions') }}
WHERE amount != amount

