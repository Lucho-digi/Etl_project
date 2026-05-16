SELECT customer_id
FROM {{ ref('silver_customers') }}
WHERE customer_id !~ '^CUST-[0-9]{7}$'