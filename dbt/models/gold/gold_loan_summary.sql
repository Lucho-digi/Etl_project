{{ config(materialized='table') }}

select
  l.loan_id,
  l.customer_id,
  case
    when c.customer_segment = 'private_banking' then 'Private Banking'
    when c.customer_segment = 'sme' then 'SME'
    when c.customer_segment = 'premium' then 'Premium'
    when c.customer_segment = 'retail' then 'Retail'
  end as customer_segment,
  c.country,
  case
    when l.type = 'personal' then 'Personal'
    when l.type = 'mortgage' then 'Mortgage'
    when l.type = 'auto' then 'Auto'
    when l.type = 'education' then 'Education'
    when l.type = 'business' then 'Business'
  end as type,
  l.principal  / fx.usd_rate as principal,
  l.outstanding_balance / fx.usd_rate as outstanding_balance,
  l.interest_rate,
  l.term_months,
  l.monthly_payment / fx.usd_rate as monthly_payment,
  l.start_date,
  l.end_date,
  case
    when l.status = 'current' then 'Current'
    when l.status = 'delinquent' then 'Delinquent'
    when l.status = 'default' then 'Default'
    when l.status = 'paid_off' then 'Paid Off'
  end as status,
  l.days_past_due,

  case
    when l.status = 'paid_off' then null
    when l.days_past_due = 0 then 'Current'
    when l.days_past_due <= 30 then '1-30'
    when l.days_past_due <= 60 then '31-60'
    when l.days_past_due <= 90 then '61-90'
    else '90+'
  end as dpd_bucket,

  l.status in ('delinquent', 'default') as is_delinquent,

  case
    when l.status in ('current', 'delinquent')
      then (l.principal / fx.usd_rate)
           * (l.interest_rate / 100)
           * (l.term_months::float / 12)
    else null
  end as interest_income

from {{ ref('fact_loans') }} l
left join {{ ref('dim_customers') }} c on l.customer_id = c.customer_id
left join {{ ref('fx_rates') }} fx on l.currency = fx.currency_code
