{{ config(materialized='table') }}

select
  c.customer_id,
  c.country,
  c.city,
  c.gender,
  case
    when c.customer_segment = 'private_banking' then 'Private Banking'
    when c.customer_segment = 'sme' then 'SME'
    when c.customer_segment = 'premium' then 'Premium'
    when c.customer_segment = 'retail' then 'Retail'
  end as customer_segment,
  case
    when c.kyc_status = 'verified' then 'Verified'
    when c.kyc_status = 'pending' then 'Pending'
    when c.kyc_status = 'expired' then 'Expired'
    when c.kyc_status = 'rejected' then 'Rejected'
  end as kyc_status,
  case
    when c.status = 'active' then 'Active'
    when c.status = 'inactive' then 'Inactive'
    when c.status = 'suspended' then 'Suspended'
    when c.status = 'closed' then 'Closed'
  end as status,
  c.registration_date,
  c.risk_score,

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

  date_part('year', age(c.registration_date)) * 12
    + date_part('month', age(c.registration_date))::int as tenure_months,

  case
    when c.risk_score <= 24 then 'Low'
    when c.risk_score <= 49 then 'Medium'
    when c.risk_score <= 74 then 'High'
    else 'Critical'
  end as risk_bucket,

  coalesce(a.num_accounts, 0) as num_accounts,
  coalesce(l.num_loans, 0) as num_loans,
  coalesce(a.num_accounts, 0) + coalesce(l.num_loans, 0) as num_products

from {{ ref('dim_customers') }} c
left join (
  select customer_id, count(*) as num_accounts
  from {{ ref('fact_accounts') }}
  group by customer_id
) a on c.customer_id = a.customer_id
left join (
  select customer_id, count(*) as num_loans
  from {{ ref('fact_loans') }}
  group by customer_id
) l on c.customer_id = l.customer_id
