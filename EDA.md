# EDA & Data Processing Documentation

---

## 1. What the Raw Data Looked Like

Before building anything, I spent time looking at the data as it came in with pgAdmin for visual inspection — no transformations, no assumptions. The goal was to understand what problems existed before trying to fix them.

The dataset covers 5 main entities: customers, accounts, transactions, loans, and digital engagement records. Each one came nested inside a single raw structure, meaning all the information about a customer — their accounts, their transactions, their loans — was bundled together in one blob rather than in separate organized tables.

The first thing that became clear is that the data came from multiple source systems across different countries, and nobody had enforced a common standard. That created most of the problems described below.

---

## 2. Problems Found & How They Were Solved

### 2.1 Missing Information

Some records were simply incomplete. Certain fields were blank for a portion of customers — things like email addresses, phone numbers, or geographic coordinates.

The key decision here was distinguishing between *critical* and *optional* missing information:

- **Critical fields**: If a customer had no country, no risk score, or no registration date, the record was dropped entirely. A customer without those fields can't be used for segmentation or analysis — keeping them would silently corrupt any metric that depends on those values.
- **Optional fields**: If a phone number or address was missing, the record was kept. Those fields are useful when present but not required for the core analytics.

Because all other tables reference customers, records related to removed customers were also removed to keep everything consistent.

### 2.2 Inconsistent Categories

Many fields that should have had a fixed set of values instead had dozens of variations:

- **Customer segment** had English and Spanish versions mixed together, plus inconsistent capitalization (`premium`, `PREMIUM`, `minorista`).
- **Transaction types** had Spanish names in some records and English in others (`deposito` vs `deposit`).
- **City names** had typos and abbreviations scattered throughout (`Medellin` vs `Medelin`, `Buenos Aires` vs `Buenos Aire`).

The solution was to define a clean standard for each field and map all the variations to it. City names required a full lookup table covering all 35 cities across 7 countries. Any value that didn't fit a known category was either mapped to a catch-all or flagged.

### 2.3 Invalid Numbers

Some numeric fields contained placeholder values that were clearly not real data — credit scores of `0`, `-99`, or `999999`, for example. These are markers that source systems use when they don't have a real value, but they look like numbers so they slip through undetected.

The fix was to define the valid range for each numeric field and treat anything outside it as missing rather than as a real value.

A separate issue: some records contained a special marker (`NaN`) in numeric fields that is invisible in most tools but causes silent errors in calculations — a sum or average that includes it produces a wrong result without any warning. 673 occurrences were found and converted to blank values before processing.

A small portion of records had location coordinates that are physically impossible — values outside the valid range for any point on Earth. These were cleared out. The customer records were kept; they just can't be placed on a map.

### 2.4 Inconsistent Date Formats

Dates appeared in four different formats: international standard (`YYYY-MM-DD`), US format (`MM/DD/YYYY`), Latin American day-first format (`DD/MM/YYYY`), and a compact format with no separators (`YYYYMMDD`).

The US and Latin American formats were the trickiest because they're ambiguous — the same string could mean March 5th or May 3rd depending on who wrote it. The approach was a simple heuristic: if the day portion is greater than 12, it must be a day (since months only go up to 12), which resolves the large majority of ambiguous cases.

Additionally, some records had dates set in the future — 45 accounts with future `opened_date` and 34 engagement records with future `last_login_date`. These were treated as data errors and cleared out.

### 2.5 Duplicate Records

The raw data contained duplicates across all entities — likely because data was pulled from multiple source systems that didn't deduplicate before sending.

For each type of duplicate, a priority rule was applied: prefer the record with more complete information, and when that's a tie, prefer the earlier record.

| Entity | Duplicates Removed |
|--------|--------------------|
| Customers | 100 |
| Accounts | 336 |
| Transactions | 1,754 |
| Loans | 156 |

---

## 3. How the Pipeline is Structured

**Raw layer**: Data stored exactly as it arrived. No changes — this is the safety net.

**Cleaning layer**: All the problems above were addressed here. Records deduplicated, categories standardized, invalid values cleared, dates normalized, and incomplete critical records removed.

**Analytics layer**: Business metrics and aggregations calculated on top of clean data. Revenue, delinquency rates, age buckets, and channel preferences all live here.

---

## 4. Business Definitions

**Revenue** comes from two sources: fees on completed transactions and estimated interest income from active loans. Pending, failed, and reversed transactions are excluded.

**Loan status** distinguishes between loans being paid on time (current), loans that are late but potentially recoverable (delinquent), loans that have been written off (default), and loans fully repaid (paid off).

**Customer status**: An active customer has at least one open account and logged in within the last 90 days. Inactive means open accounts but no recent login.

**Risk and credit scores** are grouped into ranges for segmentation. Placeholder values are excluded before grouping.

---

## 5. Net Result

After all cleaning and filtering, the dataset contains **4,669 customers** with full, consistent information across all related tables. Every customer has a valid account, and every transaction and loan can be traced back to a known customer.

The data quality rules are enforced automatically — if new data arrives with the same problems, the pipeline catches and handles them the same way without manual intervention.

---

## 6. Gold Layer — Design Decisions

The Gold layer is built on top of clean Silver data and exists solely to answer business questions. No cleaning happens here — if something looks wrong in Gold, the fix belongs in Silver. Each model has a clearly defined grain and is designed to be loaded directly into PowerBI without requiring additional joins or calculations in the BI layer.

The 7 models collectively cover all 24 business questions. Metrics that appear in multiple models (like `age_bucket` and `interest_income`) use identical logic across all of them to ensure consistent numbers regardless of which model PowerBI queries.

---

### 6.1 gold_customer_summary

**Grain**: One row per customer.

**Source tables**: `dim_customers`, `fact_accounts`, `fact_loans`

**Business questions answered**: Q9, Q10, Q11, Q12, Q13, Q14, Q24

This is the central demographic model. Most fields come straight from `dim_customers` already clean from Silver — the work here is in the calculated fields.

`age` and `age_bucket` are calculated in Gold rather than Silver because age changes every day. Storing it in Silver would mean running Silver daily just to keep ages current. Same reasoning applies to `tenure_months`.

`age_bucket` uses generational demographic brackets (18-24, 25-34, 35-44, 45-54, 55-64, 65+) — each range reflects a distinct life stage with different financial needs and product preferences. Under 18 returns null, not expected in the dataset but handled defensively.

`risk_bucket` divides the 0-100 risk score into 4 equal ranges of 25 points. No external standard exists for this score, so equal intervals were the simplest defensible choice. Both the raw score and the bucket are kept so PowerBI can show either depending on the visual.

`num_products` is the sum of accounts and loans per customer, calculated here to keep Q24 answerable from a single table. Closed accounts and paid-off loans are included — a customer who had 3 accounts and closed 2 still has a history of 3 products.

---

### 6.2 gold_financial_summary

**Grain**: One row per customer.

**Source tables**: `dim_customers`, `fact_accounts`, `fact_transactions`, `fact_loans`

**Business questions answered**: Q1, Q2, Q4

Revenue comes from two sources: fees on completed transactions and estimated interest income from active loans. Only `completed` fee transactions count — pending, failed, and reversed don't represent realized revenue.

Interest income is estimated as `principal × (interest_rate / 100) × (term_months / 12)`. This is a simplified annualized proxy — proper accrual accounting would require a time-series model tracking each payment period, which is out of scope. Only `current` and `delinquent` loans are included; `paid_off` are historical and `default` are written off.

`fee_revenue` and `interest_income` are kept separate alongside `total_revenue` so PowerBI can break down revenue by source. `total_balance` is aggregated at customer level so Q2 is a simple SUM in PowerBI.

---

### 6.3 gold_transaction_summary

**Grain**: One row per transaction.

**Source tables**: `fact_transactions`, `dim_customers`, `dim_date`

**Business questions answered**: Q3, Q15, Q16, Q17, Q18, Q19

This is the most granular Gold model — one row per transaction so PowerBI can slice by any combination of channel, type, date, category, or segment without losing flexibility.

`day_of_week` and `day_name` are joined from `dim_date` to keep the model consistent with the date dimension.

`is_international` flags transactions where the currency doesn't match the customer's country default (CO → COP, UY → UYU, etc.). USD and EUR are international for all 7 countries — confirmed with project specification.

`is_failed` is a direct boolean from `status = 'Failed'`. PowerBI calculates failure rate as `SUM(is_failed) / COUNT(*)` by channel for Q18.

`fee_amount` is the transaction amount when `type = 'Fee'` and `status = 'Completed'`, else 0. Used for Q3 revenue by channel — keeping it at transaction level allows PowerBI to group by channel without pre-aggregating.

`customer_segment` and `country` are denormalized from `dim_customers` to avoid joining two large tables at report time.

---

### 6.4 gold_loan_summary

**Grain**: One row per loan.

**Source tables**: `fact_loans`, `dim_customers`

**Business questions answered**: Q5, Q7, Q8, Q23

`dpd_bucket` groups `days_past_due` into current/1-30/31-60/61-90/90+. `paid_off` loans return NULL — they have no meaningful DPD.

`is_delinquent` flags loans in `delinquent` or `default` status, making Q5 a simple `AVG(is_delinquent)` in PowerBI.

`interest_income` uses the same formula as `gold_financial_summary` for consistency. Applied per loan here (not per customer) so Q4 can group by loan type.

`principal` and `outstanding_balance` are both included for Q23 — principal shows original size, outstanding shows what remains.

---

### 6.5 gold_credit_summary

**Grain**: One row per customer.

**Source tables**: `fact_credit_info`, `dim_customers`

**Business questions answered**: Q6, Q7

`credit_score_bucket` follows FICO-style ranges (poor/fair/good/very_good/exceptional). NULL credit scores — sentinel values cleaned in Silver (~10.3% of customers) — remain NULL and are not forced into a bucket.

`utilization_bucket` maps utilization percentage to six ranges from very_low to maxed. Both the raw percentage and the bucket are kept.

`bankruptcy_flag`, `late_payments_12m`, and `inquiries_6m` are included to support cross-analysis with loan delinquency for Q7.

---

### 6.6 gold_digital_summary

**Grain**: One row per customer.

**Source tables**: `dim_customers`, `fact_digital_engagement`

**Business questions answered**: Q20, Q21

`age` and `age_bucket` are recalculated here using the same logic as `gold_customer_summary`. This is a conscious duplication — the alternative would be joining both models in PowerBI every time Q21 is visualized.

`is_digital_preferred` flags customers whose `preferred_channel` is `mobile` or `web` — a clean binary split for Q21 without needing a CASE WHEN at report time.

`is_active_digital` flags customers who logged in within the last 90 days, distinguishing between customers who registered for digital channels and those who actually use them.

`days_since_last_login` is NULL for customers with no login history — treated as "never logged in" rather than "unknown".

---

### 6.7 gold_product_summary

**Grain**: One row per account.

**Source tables**: `fact_accounts`, `dim_customers`

**Business questions answered**: Q22

The simplest Gold model — most fields come directly from `fact_accounts`. The only calculated field is `account_age_months`, kept in Gold so it stays current.

`account_status` lets PowerBI distinguish active from closed accounts when measuring popularity.

`customer_segment` and `country` are denormalized to enable cross-dimensional slicing without extra joins.

---

*Q3 note: Revenue by channel reflects fee revenue only, as interest income is derived from loans and cannot be attributed to a specific transaction channel.*