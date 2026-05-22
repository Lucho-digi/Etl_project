{{ config(materialized='table') }}
select
  ci.customer_id,
  c.country,
  ci.credit_score,
  case
    when ci.credit_score is null then null
    when ci.credit_score < 580 then 'Poor'
    when ci.credit_score < 670 then 'Fair'
    when ci.credit_score < 740 then 'Good'
    when ci.credit_score < 800 then 'Very Good'
    else 'Exceptional'
  end as credit_score_bucket,
  ci.utilization_pct,
  case
    when ci.utilization_pct < 10 then 'Very Low'
    when ci.utilization_pct < 30 then 'Low'
    when ci.utilization_pct < 50 then 'Moderate'
    when ci.utilization_pct < 70 then 'High'
    when ci.utilization_pct < 90 then 'Very High'
    else 'Maxed'
  end as utilization_bucket,
  ci.total_limit / fx.usd_rate as total_limit,
  ci.total_used / fx.usd_rate as total_used,
  ci.bankruptcy_flag,
  ci.late_payments_12m,
  ci.inquiries_6m,
  ci.num_credit_accounts,
  ci.oldest_account_age_months
from {{ ref('fact_credit_info') }} ci
left join {{ ref('dim_customers') }} c on ci.customer_id = c.customer_id
left join {{ ref('fx_rates') }} fx on ci.currency = fx.currency_code