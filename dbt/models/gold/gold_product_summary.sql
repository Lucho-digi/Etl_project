{{ config(materialized='table') }}

select
  a.account_id,
  a.customer_id,
  c.country,
  case
    when c.customer_segment = 'private_banking' then 'Private Banking'
    when c.customer_segment = 'sme' then 'SME'
    when c.customer_segment = 'premium' then 'Premium'
    when c.customer_segment = 'retail' then 'Retail'
  end as customer_segment,
  case
    when a.account_type = 'checking' then 'Checking'
    when a.account_type = 'savings' then 'Savings'
    when a.account_type = 'credit_card' then 'Credit Card'
    when a.account_type = 'investment' then 'Investment'
    else 'Other'
  end as account_type,
  a.balance / fx.usd_rate as balance,
  a.currency,
  a.interest_rate,
  a.opened_date,
  case
    when a.status = 'active' then 'Active'
    when a.status = 'frozen' then 'Frozen'
    when a.status = 'closed' then 'Closed'
    else 'Other'
  end as account_status,

  date_part('year', age(a.opened_date)) * 12
    + date_part('month', age(a.opened_date)) as account_age_months

from {{ ref('fact_accounts') }} a
left join {{ ref('dim_customers') }} c on a.customer_id = c.customer_id
left join {{ ref('fx_rates') }} fx on a.currency = fx.currency_code
