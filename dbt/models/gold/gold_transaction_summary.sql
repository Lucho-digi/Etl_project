{{ config(materialized='table') }}

select
  t.transaction_id,
  t.customer_id,
  t.account_id,
  t.transaction_date,
  date_trunc('month', t.transaction_date)::date as transaction_month,
  t.amount / fx.usd_rate as amount,
  case
    when t.type = 'fee' and t.status = 'completed' then t.amount / fx.usd_rate
    else 0
  end as fee_amount,
  case
    when t.type = 'deposit' then 'Deposit'
    when t.type = 'withdrawal' then 'Withdrawal'
    when t.type = 'transfer' then 'Transfer'
    when t.type = 'payment' then 'Payment'
    when t.type = 'refund' then 'Refund'
    when t.type = 'fee' then 'Fee'
  end as type,
  t.category,
  t.merchant,
  case
    when t.channel = 'mobile' then 'Mobile'
    when t.channel = 'web' then 'Web'
    when t.channel = 'atm' then 'ATM'
    when t.channel = 'branch' then 'Branch'
    when t.channel = 'pos' then 'POS'
  end as channel,
  case
    when t.status = 'completed' then 'Completed'
    when t.status = 'pending' then 'Pending'
    when t.status = 'failed' then 'Failed'
    when t.status = 'reversed' then 'Reversed'
  end as status,
  t.currency,

  case
    when t.currency = 'USD' then true
    when c.country = 'CO' and t.currency != 'COP' then true
    when c.country = 'UY' and t.currency != 'UYU' then true
    when c.country = 'AR' and t.currency != 'ARS' then true
    when c.country = 'MX' and t.currency != 'MXN' then true
    when c.country = 'CL' and t.currency != 'CLP' then true
    when c.country = 'PE' and t.currency != 'PEN' then true
    when c.country = 'BR' and t.currency != 'BRL' then true
    else false
  end as is_international,

  t.status = 'failed' as is_failed,

  d.day_of_week,
  d.day_name,

  case
    when c.customer_segment = 'private_banking' then 'Private Banking'
    when c.customer_segment = 'sme' then 'SME'
    when c.customer_segment = 'premium' then 'Premium'
    when c.customer_segment = 'retail' then 'Retail'
  end as customer_segment,
  c.country

from {{ ref('fact_transactions') }} t
left join {{ ref('dim_customers') }} c on t.customer_id = c.customer_id
left join {{ ref('dim_date') }} d on t.transaction_date = d.full_date
left join {{ ref('fx_rates') }} fx on t.currency = fx.currency_code
