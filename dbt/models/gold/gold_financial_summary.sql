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

  coalesce(b.total_balance, 0) as total_balance,

  coalesce(f.fee_revenue, 0) as fee_revenue,

  coalesce(i.interest_income, 0) as interest_income,

  coalesce(f.fee_revenue, 0) + coalesce(i.interest_income, 0) as total_revenue

from {{ ref('dim_customers') }} c
left join (
  select
    a.customer_id,
    sum(a.balance / fx.usd_rate) as total_balance
  from {{ ref('fact_accounts') }} a
  left join {{ ref('fx_rates') }} fx on a.currency = fx.currency_code
  group by a.customer_id
) b on c.customer_id = b.customer_id
left join (
  select
    t.customer_id,
    sum(t.amount / fx.usd_rate) as fee_revenue
  from {{ ref('fact_transactions') }} t
  left join {{ ref('fx_rates') }} fx on t.currency = fx.currency_code
  where t.type = 'fee' and t.status = 'completed'
  group by t.customer_id
) f on c.customer_id = f.customer_id
left join (
  select
    l.customer_id,
    sum(
      (l.principal / fx.usd_rate)
      * (l.interest_rate / 100)
      * (l.term_months::float / 12)
    ) as interest_income
  from {{ ref('fact_loans') }} l
  left join {{ ref('fx_rates') }} fx on l.currency = fx.currency_code
  where l.status in ('current', 'delinquent')
  group by l.customer_id
) i on c.customer_id = i.customer_id
