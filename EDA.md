# EDA & Data Processing Documentation

---

## 1. What the Raw Data Looked Like

Before building anything, I spent time just looking at the data as it came in whit pgAdmin for visual inspection — no transformations, no assumptions. The goal was to understand what problems existed before trying to fix them.

The dataset covers 5 main entities: customers, accounts, transactions, loans, and digital engagement records. Each one came nested inside a single raw structure, meaning all the information about a customer — their accounts, their transactions, their loans — was bundled together in one blob rather than in separate organized tables.

The first thing that became clear is that the data came from multiple source systems across different countries, and nobody had enforced a common standard. That created most of the problems described below.

---

## 2. Problems Found & How They Were Solved

### 2.1 Missing Information

Some records were simply incomplete. Certain fields were blank for a portion of customers — things like email addresses, phone numbers, or geographic coordinates.

The key decision here was distinguishing between *critical* and *optional* missing information:

- **Critical fields**: If a customer had no country, no risk score, no registration date, the record was dropped entirely. A customer without those fields can't be used for segmentation or analysis — keeping them would silently corrupt any metric that depends on those values.
- **Optional fields**: If a phone number or address was missing, the record was kept. Those fields are useful when present but not required for the core analytics.

Because all other tables reference customers, related records to removed customers were also removed to keep everything consistent.

### 2.2 Inconsistent Categories

Many fields that should have had a fixed set of values instead had dozens of variations. Some examples:

- **Customer segment** had English and Spanish versions mixed together, plus inconsistent capitalization.
- **Transaction types** had Spanish names in some records and English in others.

The solution was to define a clean standard for each field and map all the variations to it. Any value that didn't fit a known category was either mapped to a catch-all or flagged.

### 2.3 Invalid Numbers

Some numeric fields contained placeholder values that were clearly not real data — credit scores with impossible values, for example. These are markers that source systems use when they don't have a real value, but they look like numbers so they slip through undetected.

The fix was to define the valid range for each numeric field and treat anything outside it as missing rather than as a real value.

A separate issue: some records contained a special marker in numeric fields that is invisible to the eye in most tools but causes silent errors in calculations — a sum or average that includes it produces a wrong result without any warning. These were all converted to blank values before processing.

A small portion of records had location coordinates that are physically impossible — values that fall outside the valid range for any point on Earth. These were cleared out. The customer records were kept; they just can't be placed on a map.

### 2.4 Inconsistent Date Formats

Dates appeared in four different formats across the dataset — international standard, US format, Latin American day-first format, and a compact number format with no separators.

The US and Latin American formats were the trickiest because they're ambiguous: the same string could mean March 5th or May 3rd depending on who wrote it. The approach taken was a simple heuristic — if the day portion is greater than 12, it must be a day (since months only go up to 12), which resolves the large majority of ambiguous cases.

Additionally, some records had dates set in the future — last login dates and account opening dates that hadn't happened yet. These were treated as data errors and cleared out.

### 2.5 Duplicate Records

The raw data contained duplicates across all entities — the same customer appearing more than once, the same transaction recorded twice, and so on. This likely happened because data was pulled from multiple source systems that didn't deduplicate before sending.

For each type of duplicate, a priority rule was applied: prefer the record with more complete information, and when that's a tie, prefer the earlier record. This way we keep the most useful version of each record while removing the noise.

---

## 3. How the Pipeline is Structured

The data flows through three layers, each with a specific responsibility:

**Raw layer**: The data is stored exactly as it arrived, with no changes. This is the safety net — if something goes wrong downstream, the original data is always there.

**Cleaning layer**: This is where all the problems described above were addressed. Records were deduplicated, categories were standardized, invalid values were cleared, dates were normalized, and incomplete critical records were removed. The output is a clean, consistent set of tables that can be trusted for analysis.

**Analytics layer**: Business metrics and aggregations are calculated here using the clean data. Things like revenue per customer, delinquency rates, and channel preferences are all defined and computed in this layer.

---

## 4. Business Definitions

A few terms that appear throughout the analytics needed explicit definitions, since different teams and source systems used them differently.

**Revenue** is counted in two ways: fees charged on transactions, and estimated interest income from active loans. Only completed transactions count — pending or failed ones are excluded.

**Loan status** distinguishes between loans being paid on time, loans that are late but potentially recoverable, loans that have been written off, and loans that have been fully repaid.

**Customer status** reflects whether a customer is actively using their account. An active customer has at least one open account and has logged in within the last 90 days. Inactive means they have open accounts but haven't logged in recently.

**Risk and credit scores** are both grouped into ranges to make segmentation easier. Placeholder values used when no real score exists are excluded before grouping.

---

## 5. Net Result

After all cleaning and filtering, the dataset contains customers with full, consistent information across all related tables. Every customer in the final dataset has a valid account, and every transaction and loan can be traced back to a known customer.

The data quality rules are enforced automatically — if new data arrives with the same problems, the pipeline catches and handles them the same way without manual intervention.


## 6. Gold Layer — Design Decisions

The Gold layer is built on top of clean Silver data and exists solely to answer business 
questions. No cleaning happens here — if something looks wrong in Gold, the fix belongs 
in Silver. Each model has a clearly defined grain and is designed to be loaded directly 
into PowerBI without requiring additional joins or calculations in the BI layer.

The 7 models collectively cover all 24 business questions. Metrics that appear in multiple 
models (like `age_bucket` and `interest_income`) use identical logic across all of them 
to ensure consistent numbers regardless of which model PowerBI queries.

---

### 6.1 gold_customer_summary

**Grain**: One row per customer.

**Source tables**: `dim_customers`, `fact_accounts`, `fact_loans`

**Business questions answered**: Q9, Q10, Q11, Q12, Q13, Q14, Q24

This is the central demographic model. Most of the fields come straight from 
`dim_customers` already clean from Silver — the work here is in the calculated fields.

`age` and `age_bucket` are calculated here rather than Silver because age changes 
every day. Storing it in Silver would mean running Silver every day just to keep 
ages current, which doesn't make sense. Same reasoning applies to `tenure_months`.

`age_bucket` uses generational demographic brackets (18-24, 25-34, 35-44, 45-54, 
55-64, 65+) because each range reflects a distinct life stage with different financial 
needs. Under 18 returns null — not expected in the dataset but handled defensively.

`risk_bucket` divides the 0-100 risk score into 4 equal ranges of 25 points. There's 
no external standard for this score, so equal intervals were the simplest defensible 
choice. Both the raw score and the bucket are kept so PowerBI can show either depending 
on the visual.

`num_products` is the sum of accounts and loans per customer. It's calculated here 
rather than in a separate model so Q24 (average products by segment) doesn't require 
an extra join in PowerBI. Closed accounts and paid-off loans are included — a customer 
who had 3 accounts and closed 2 still has a history of 3 products.

---

### 6.2 gold_financial_summary

**Grain**: One row per customer.

**Source tables**: `dim_customers`, `fact_accounts`, `fact_transactions`, `fact_loans`

**Business questions answered**: Q1, Q2, Q4

Revenue in this dataset comes from two sources: fees on completed transactions, 
and estimated interest income from active loans. Only `completed` transactions 
of type `fee` count — pending, failed, and reversed are excluded because they 
don't represent realized revenue.

Interest income is estimated as `principal × (interest_rate / 100) × (term_months / 12)`. 
This is a simplified annualized proxy — proper accrual accounting would require 
a time-series model tracking each payment period, which is out of scope. Only 
`current` and `delinquent` loans are included; `paid_off` loans are historical 
and `default` loans are written off.

`fee_revenue` and `interest_income` are kept separate alongside `total_revenue` 
so PowerBI can break down revenue by source without recalculating. `total_balance` 
is aggregated at customer level so Q2 (total balances by country) is a simple 
SUM in PowerBI.

---

### 6.3 gold_transaction_summary

**Grain**: One row per transaction.

**Source tables**: `fact_transactions`, `dim_customers`, `dim_date`

**Business questions answered**: Q3, Q15, Q16, Q17, Q18, Q19

This is the most granular Gold model — it keeps one row per transaction rather 
than aggregating, so PowerBI can slice by any combination of channel, type, 
date, category, or segment without losing flexibility.

`day_of_week` and `day_name` are joined from `dim_date` rather than derived 
inline to keep the model consistent with the date dimension and avoid 
recalculating the same logic in multiple places.

`is_international` flags transactions where the currency doesn't match the 
customer's country default (CO → COP, UY → UYU, etc.). USD and EUR are 
therefore international for all 7 countries — this definition was confirmed 
with the project specification, which defines international as any currency 
that doesn't match the local one.

`is_failed` is a direct boolean from `status = 'failed'` — no CASE WHEN needed. 
PowerBI can then calculate failure rate as `SUM(is_failed) / COUNT(*)` by channel 
for Q18.

`customer_segment` and `country` are denormalized from `dim_customers` into this 
model to avoid forcing PowerBI to join two large tables at report time.

---

### 6.4 gold_loan_summary

**Grain**: One row per loan.

**Source tables**: `fact_loans`, `dim_customers`

**Business questions answered**: Q5, Q7, Q8, Q23

`dpd_bucket` groups `days_past_due` into current/1-30/31-60/61-90/90+ following 
the standard delinquency buckets defined in Section 9.5. `paid_off` loans return 
NULL for this field — they have no meaningful DPD. Both the raw `days_past_due` 
and the bucket are kept for the same reason as risk scores: PowerBI may need either.

`is_delinquent` flags loans in `delinquent` or `default` status. This makes Q5 
(delinquency rate by segment) a simple `AVG(is_delinquent)` in PowerBI rather 
than a CASE WHEN at report time.

`interest_income` uses the same formula as `gold_financial_summary` to ensure 
consistent numbers if both models are queried in the same dashboard. The formula 
is applied per loan here rather than per customer, which allows Q4 (interest income 
by loan type) to be answered by grouping on `type`.

`principal` and `outstanding_balance` are both included for Q23 — principal 
shows the original portfolio size, outstanding shows what remains. The difference 
between the two reflects repayment progress.

---

### 6.5 gold_credit_summary

**Grain**: One row per customer.

**Source tables**: `fact_credit_info`, `dim_customers`

**Business questions answered**: Q6, Q7

`credit_score_bucket` follows FICO-style ranges (poor/fair/good/very_good/exceptional) 
as defined in Section 9.3. NULL credit scores — those that were sentinel values 
cleaned in Silver (~10.3% of customers) — remain NULL and are not bucketed. 
Forcing them into a category would misrepresent the data.

`utilization_bucket` maps utilization percentage to six ranges from very_low to 
maxed as defined in Section 9.4. Both the raw percentage and the bucket are kept 
for the same reason as credit scores.

`bankruptcy_flag`, `late_payments_12m`, and `inquiries_6m` are included alongside 
utilization to support Q7 (relationship between utilization and delinquency). 
These fields provide the credit behavior context needed to cross-analyze with 
loan delinquency from `gold_loan_summary`.

---

### 6.6 gold_digital_summary

**Grain**: One row per customer.

**Source tables**: `dim_customers`, `fact_digital_engagement`

**Business questions answered**: Q20, Q21

`age` and `age_bucket` are recalculated here using the same logic as 
`gold_customer_summary`. This is a conscious duplication — the alternative 
would be joining `gold_digital_summary` with `gold_customer_summary` in PowerBI 
every time Q21 (digital vs branch by age) is visualized, which adds unnecessary 
complexity at report time.

`is_digital_preferred` flags customers whose `preferred_channel` is `mobile` 
or `web`. This gives PowerBI a clean binary split for Q21 without needing 
a CASE WHEN in the report layer.

`is_active_digital` flags customers who logged in within the last 90 days. 
This distinguishes between customers who registered for digital channels 
and those who actually use them — a customer can have `mobile_app_registered = true` 
but not have logged in for months.

`days_since_last_login` is NULL for customers with no login history. This is 
treated as "never logged in" rather than "unknown" as defined in Section 12.

---

### 6.7 gold_product_summary

**Grain**: One row per account.

**Source tables**: `fact_accounts`, `dim_customers`

**Business questions answered**: Q22

This is the simplest Gold model — most fields come directly from `fact_accounts` 
with no transformation needed. The only calculated field is `account_age_months`, 
kept in Gold for the same reason as `tenure_months` in `gold_customer_summary` — 
it changes daily and would go stale in Silver.

`account_status` is included to let PowerBI distinguish active from closed accounts 
when measuring popularity — closed accounts are still relevant for historical trends 
but shouldn't dominate current product mix analysis.

`customer_segment` and `country` are denormalized from `dim_customers` to enable 
cross-dimensional slicing (e.g. which account types are most popular among premium 
customers in Mexico) without extra joins in PowerBI.


Q3 — Revenue by channel reflects fee revenue only, as interest income 
is derived from loans and cannot be attributed to a specific transaction channel.