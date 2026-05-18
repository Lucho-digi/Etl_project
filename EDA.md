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

After all cleaning and filtering, the dataset contains **3,924 customers** with full, consistent information across all related tables. Every customer in the final dataset has a valid account, and every transaction and loan can be traced back to a known customer.

The data quality rules are enforced automatically — if new data arrives with the same problems, the pipeline catches and handles them the same way without manual intervention.