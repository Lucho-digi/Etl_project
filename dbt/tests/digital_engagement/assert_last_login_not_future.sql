SELECT customer_id
FROM {{ ref('fact_digital_engagement') }}
WHERE last_login_date > CURRENT_DATE
