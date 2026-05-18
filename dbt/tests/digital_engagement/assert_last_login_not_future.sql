SELECT customer_id
FROM {{ ref('silver_digital_engagement') }}
WHERE last_login_date > CURRENT_DATE
