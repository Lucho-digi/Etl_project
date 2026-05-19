SELECT customer_id
FROM {{ ref('dim_customers') }}
WHERE customer_id !~ '^CUST-[0-9]{7}$'