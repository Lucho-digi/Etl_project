SELECT transaction_id
FROM {{ ref('fact_transactions') }}
WHERE transaction_id !~ '^TXN-[A-F0-9]{12}$'