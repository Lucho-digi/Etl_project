{{ config(materialized='table') }}

select
  c.customer_id,
  c.country,
  case
    when c.customer_segment = 'private_banking' then 'Private Banking'
    when c.customer_segment = 'sme' then 'SME'
    when c.customer_segment = 'premium' then 'Premium'
    when c.customer_segment = 'retail' then 'Retail'
  end as customer_segment,

  extract(year from age(c.date_of_birth))::int as age,

  case
    when extract(year from age(c.date_of_birth)) < 18 then null
    when extract(year from age(c.date_of_birth)) <= 24 then '18-24'
    when extract(year from age(c.date_of_birth)) <= 34 then '25-34'
    when extract(year from age(c.date_of_birth)) <= 44 then '35-44'
    when extract(year from age(c.date_of_birth)) <= 54 then '45-54'
    when extract(year from age(c.date_of_birth)) <= 64 then '55-64'
    else '65+'
  end as age_bucket,

  de.mobile_app_registered,
  de.web_banking_registered,
  de.last_login_date,

  current_date - de.last_login_date as days_since_last_login,

  de.last_login_date is not null
    and current_date - de.last_login_date <= 90 as is_active_digital,

  de.mobile_app_registered as is_mobile_user,

  case
    when de.preferred_channel = 'mobile' then 'Mobile'
    when de.preferred_channel = 'web' then 'Web'
    when de.preferred_channel = 'atm' then 'ATM'
    when de.preferred_channel = 'branch' then 'Branch'
    when de.preferred_channel = 'call_center' then 'Call center'
  end as preferred_channel,

  de.preferred_channel in ('mobile', 'web') as is_digital_preferred,

  de.avg_monthly_logins,
  de.push_notifications,
  de.paperless_statements

from {{ ref('dim_customers') }} c
left join {{ ref('fact_digital_engagement') }} de on c.customer_id = de.customer_id
