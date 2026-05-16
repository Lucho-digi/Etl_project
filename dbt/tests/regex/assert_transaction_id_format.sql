SELECT transaction_id
FROM {{ ref('silver_transactions') }}
WHERE transaction_id !~ '^TXN-[A-F0-9]{12}$'