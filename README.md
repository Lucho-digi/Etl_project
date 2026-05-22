# Qversity v2 — Fintech/Banking Data Engineering Project

A containerized ELT data platform using Docker Compose with Airflow, PostgreSQL, PySpark, dbt, and PowerBI.

## Project Overview

This project implements a modern data engineering pipeline for a LATAM Fintech/Banking dataset, following a Bronze-Silver-Gold data warehouse architecture. The pipeline ingests raw JSON data from S3, processes it with PySpark and dbt, and delivers business-ready analytics to PowerBI.

### Business Context

**Problem Statement**: A LATAM fintech lacks a unified, trusted view of customers, accounts, transactions, loans, and digital engagement, limiting growth and risk decisioning.

**Business Objectives**:
- Eliminate data silos by consolidating raw data into dependable analytical layers.
- Standardize metrics across countries and business lines for consistent KPI definitions.
- Improve data quality and lineage to increase trust in reporting.
- Deliver timely dashboards for segmentation, credit risk monitoring, operational performance, fraud signals, and regulatory readiness.

**Expected Impact**:
- Faster experimentation and decision-making.
- Improved cross-sell, retention, and risk outcomes.
- Reliable, comparable analytics across regions and products.

### Architecture Diagram

![image](Diagram.png)

```
S3 (JSON) → Airflow → Bronze → PySpark (Silver) → dbt (Silver) → dbt (Gold) → PowerBI
```
---

## Project Structure

```
qversity-data-2026-montevideo-lucianoduarte/
├── dags/                     # Airflow DAG definitions
|   ├── bronze_dag.py         # DAG for Bronze layer ingestion
|   ├── silver_dag.py         # DAG for Silver layer transformations
|   ├── gold_dag.py           # DAG for Gold layer transformations
│   └── qversity_pipeline.py  # Main DAG orchestrating the pipeline
├── spark/                    # PySpark scripts
├── dbt/                      # dbt project
|   ├── macros/               # dbt macros
│   ├── models/
│   │   ├── bronze/           # Raw data staging
│   │   ├── silver/           # Cleaned and normalized data
│   │   └── gold/             # Business analytics
│   ├── tests/                # dbt tests
│   ├── dbt_project.yml       # dbt configuration
│   └── profiles.yml          # Database connections
├── powerbi/                  # PowerBI deliverables
│   ├── dashboard.pbix        # PowerBI file with 4 pages of visualizations
│   └── screenshots/          # Dashboard page screenshots
├── data/
│   └── raw/                  # Raw input data
├── docker-compose.yml        # Docker environment setup
├── env.example               # Environment variables template
├── requirements.txt          # Python dependencies
├── .gitignore
├── .pre-commit-config.yaml   # Code quality hooks
├── EDA.md                    # Data exploration and processing decisions
├── BUSINESS_QUESTIONS.md     # Answers to all 24 business questions
└── README.md                 # This file
```

---

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available
- PowerBI Desktop (for dashboard creation)

### Setup

1. **Clone the repository and setup environment**:
```bash
git clone git@github.com:Lucho-digi/qversity-data-2026-montevideo-lucianoduarte.git
cd qversity-data-2026-montevideo-lucianoduarte
cp env.example .env
```
Note you will need to fill in any required environment variables in the `.env` file before starting the services.
It's highly recommended to use a dedicated `POSTGRES_PORT` to avoid conflicts with any existing local PostgreSQL installation — if you change it, update `docker-compose.yml` accordingly.

2. **Start services**:
```bash
docker compose up -d --build
```

3. **Verify services are running**:
```bash
docker compose ps
```

4. **Access Airflow UI**: http://localhost:8080
You need to define the User and Password in the `.env` file before starting the services. Default credentials for testing:
> User: admin \
> Password: admin

5. **Trigger the pipeline**:
```bash
docker compose exec airflow airflow dags trigger qversity_pipeline
```

---

## Access Points

| Service | URL / Connection | Credentials |
|---------|-----------------|-------------|
| Airflow UI | http://localhost:8080 | define in .env |
| PostgreSQL | localhost:5432 | define in .env |
| Database | qversity | — |

---

## Common Commands

### dbt
```bash
# Enter dbt container
docker compose exec dbt bash

# Run all models
dbt run

# Run specific layer
dbt run --models bronze
dbt run --models silver
dbt run --models gold

# Load seed data (fx_rates)
dbt seed

# Test data quality
dbt test

# List models
dbt ls --resource-type model
```

### Airflow
```bash
# View logs
docker compose logs -f airflow

# List DAGs
docker compose exec airflow airflow dags list

# Trigger DAG
docker compose exec airflow airflow dags trigger <dagname>

# Check DAG run status
docker compose exec airflow airflow dags list-runs -d <dagname>
```

### PySpark
```bash
# Test PySpark interactively
docker compose exec airflow python -c "from pyspark.sql import SparkSession; print('PySpark OK')"
```

### Database Access
```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U qversity-admin -d qversity

# View schemas
\dn

# View tables in a schema
\dt bronze.*
\dt silver.*
\dt gold.*

# Describe a table
\d <schema>.<table_name>
```

---

## Architecture

This project implements a **Bronze-Silver-Gold** data lakehouse architecture for a LATAM Fintech/Banking dataset:

- **Bronze Layer**: Raw JSON ingestion from S3 into PostgreSQL (`jsonb`). Data is stored exactly as received — no transformations, no assumptions. This is the safety net for the entire pipeline.
- **Silver Layer (PySpark)**: Reads Bronze data via JDBC, flattens nested arrays (`accounts[]`, `transactions[]`, `loans[]`) into relational staging tables, and applies deduplication logic. Writes results back to the `silver` schema.
- **Silver Layer (dbt)**: Cleans, standardizes, and normalizes PySpark output. Handles type casting, boolean normalization, date format inconsistencies, NaN values, invalid numeric ranges, and categorical standardization. Builds dimension and fact tables.
- **Gold Layer (dbt)**: Business-ready analytics models that answer 24 business questions. All revenue calculations, risk bucketing, and age/tenure computations happen here. Amounts are converted to USD using fixed exchange rates loaded via dbt seeds.
- **PowerBI**: Connects directly to the `gold` schema in PostgreSQL. Presents insights in a 4-page dashboard with slicers for country, segment, and channel.

### Role of Main Technologies

| Technology | Role |
|------------|------|
| **Airflow** | Orchestrates the full ELT pipeline via DAGs |
| **PostgreSQL** | Single warehouse storing bronze, silver, and gold schemas |
| **PySpark** | Flattens nested JSON arrays and deduplicates entities |
| **dbt** | SQL transformations, testing, and documentation |
| **PowerBI** | 4-page dashboard connected to gold schema |
| **Docker** | Containerized development and reproducible environment |

---

## Data Model

The data model consists of 6 main entities: Customers, Accounts, Transactions, Loans, Credit Info, and Digital Engagement. Each entity has a corresponding table in the Silver and Gold layers.

For Silver, PySpark flattened the nested arrays and dbt finished flattening the nested objects (`credit_info`, `digital_engagement`) into relational structures. The Silver ERD is available below:

![image](SilverERD.svg)

### Silver Layer — Dimensions and Facts

| Table | Type | Grain | Description |
|-------|------|-------|-------------|
| `dim_customers` | Dimension | One row per customer | Demographics, risk score, KYC, segment |
| `dim_date` | Dimension | One row per calendar day | Date attributes for time-series analysis |
| `fact_accounts` | Fact | One row per account | Account balances, types, interest rates |
| `fact_transactions` | Fact | One row per transaction | Amounts, channels, types, statuses |
| `fact_loans` | Fact | One row per loan | Principal, rates, DPD, status |
| `fact_credit_info` | Fact | One row per customer | Credit score, utilization, bankruptcy flag |
| `fact_digital_engagement` | Fact | One row per customer | Login history, channel preferences, registrations |

### Gold Layer — Analytics Models

| Model | Grain | Business Questions |
|-------|-------|-------------------|
| `gold_customer_summary` | One row per customer | Q9, Q10, Q11, Q12, Q13, Q14, Q24 |
| `gold_financial_summary` | One row per customer | Q1, Q2, Q4 |
| `gold_transaction_summary` | One row per transaction | Q3, Q15, Q16, Q17, Q18, Q19 |
| `gold_loan_summary` | One row per loan | Q5, Q7, Q8, Q23 |
| `gold_credit_summary` | One row per customer | Q6, Q7 |
| `gold_digital_summary` | One row per customer | Q20, Q21 |
| `gold_product_summary` | One row per account | Q22 |

For full documentation of data quality decisions, NULL handling strategy, and Gold layer design decisions, refer to [EDA.md](EDA.md).
The Gold ERD is available below:
![image](GoldERD.svg)
---

## PySpark Logic

PySpark scripts live in the `spark/` directory and are triggered from Airflow as part of the silver pipeline.

### Scripts

**`flatten_customers.py`**
Reads `bronze.raw_fintech_data` and extracts flat customer fields into `silver.stg_raw_deduplicated`. Applies deduplication logic: for duplicate `customer_id` records, the record with fewer NULLs in key fields is kept. Ties are broken by earliest `registration_date`.

**`flatten_accounts.py`**
Explodes the `accounts[]` array from each customer record into individual rows. Each row represents one account. Deduplication keeps the most complete record per `account_id`.

**`flatten_transactions.py`**
Explodes the `transactions[]` array. Each row represents one transaction. Deduplication prefers `completed` status, then earliest date.

**`flatten_loans.py`**
Explodes the `loans[]` array. Each row represents one loan. Deduplication keeps the most complete record per `loan_id`.

### Deduplication Summary

| Entity | Duplicates Removed | Strategy |
|--------|-------------------|----------|
| Customers | 100 | Fewest NULLs → earliest registration date |
| Accounts | 336 | Most complete record |
| Transactions | 1,754 | Prefer completed → earliest date |
| Loans | 156 | Most complete record |

The `credit_info{}` and `digital_engagement{}` objects were flattened directly in dbt Silver as they are nested objects (not arrays) and don't require PySpark to explode.

---

## PowerBI Dashboard

The dashboard connects directly to PostgreSQL (`gold` schema) and consists of 4 pages. All amounts are displayed in USD using fixed exchange rates as of 2026-05-19.

### Page 1 — Executive Overview

![Executive Overview](powerbi/screenshots/page1_executive_overview.png)

**What it shows**: High-level KPIs and demographic breakdown of the customer base across 7 LATAM countries.

**Key metrics**: 4,667 total customers, $4.07bn in assets under management, average risk score of 49.91, average 5.04 products per customer.

**Visuals**: Customer count by country and city, segment distribution, customer status breakdown, KYC status distribution, risk score distribution.

**Business questions answered**: Q9, Q10, Q13, Q14, Q24

**Decisions it can support**:
- Geographic expansion priorities based on customer concentration
- Compliance monitoring via KYC status distribution
- Risk appetite assessment via risk bucket distribution
- Cross-sell opportunities via average products per segment

---

### Page 2 — Revenue & Transactions

![Revenue & Transactions](powerbi/screenshots/page2_revenue_transactions.png)

**What it shows**: Revenue breakdown, transaction patterns, channel performance, and international activity.

**Key metrics**: $82.81M in fee revenue, 81,864 total transactions, $24.83K average ticket size, 25.02% failed transaction rate.

**Visuals**: Fee revenue by channel, average revenue by segment, total balances by country, interest income by loan type, transaction categories by volume and value, volume by day of week, average ticket by channel, failed rate by channel, international transactions by country and currency.

**Business questions answered**: Q1, Q2, Q3, Q4, Q15, Q16, Q17, Q18, Q19

**Note on Q3**: Revenue by channel reflects fee revenue only. Interest income is derived from loans and cannot be attributed to a specific transaction channel.

**Decisions it can support**:
- Channel investment decisions based on revenue and failure rates
- Product pricing strategy via fee revenue distribution
- Operational capacity planning via volume by day of week
- International expansion based on cross-border transaction patterns

---

### Page 3 — Risk & Credit

![Risk & Credit](powerbi/screenshots/page3_risk_credit.png)

**What it shows**: Credit quality, delinquency, and loan portfolio health across segments and loan types.

**Key metrics**: 49.39% delinquency rate, average credit score of 568.40 (fair bucket), average utilization of 49.59%, $663.86M in total outstanding balance.

**Visuals**: Credit score distribution by country, delinquency rate by segment, delinquency by utilization bucket, DPD distribution by loan type, loan portfolio composition by type and status.

**Business questions answered**: Q5, Q6, Q7, Q8, Q23

**Note on Q7**: No significant relationship between credit utilization and delinquency was found — rates are uniform across all utilization buckets (~48–51%). This is consistent with the synthetic nature of the dataset.

**Note on Q23**: Paid Off loans show no outstanding balance by definition and do not appear in the portfolio composition visual. This is correct behavior — those loans no longer represent active exposure.

**Decisions it can support**:
- Credit policy tightening based on delinquency rates by segment
- Loan provisioning and write-off planning via DPD distribution
- Portfolio rebalancing based on loan type composition
- Country-level credit risk monitoring

---

### Page 4 — Customer & Engagement

![Customer & Engagement](powerbi/screenshots/page4_customer_engagement.png)

**What it shows**: Customer acquisition trends, demographic distribution, digital adoption, and product preferences.

**Key metrics**: 49.15% mobile adoption rate, 40.58% digital preferred rate, 30.03 average monthly logins, 949 active digital customers.

**Visuals**: Monthly acquisition trend, age distribution by segment, mobile adoption by segment, digital vs branch preference by age group, most popular account types.

**Business questions answered**: Q11, Q12, Q20, Q21, Q22

**Decisions it can support**:
- Digital channel investment based on adoption rates by segment
- Targeted onboarding campaigns based on age and channel preference
- Product development priorities based on account type popularity
- Acquisition strategy based on monthly registration trends

---

## Key Findings

- The customer base is evenly distributed across 7 LATAM countries with no dominant market.
- Average credit score of 568 falls in the `fair` bucket across all countries — suggesting a mid-risk customer base with room for credit product growth.
- Mobile adoption is ~49% across all segments — digital channels have significant room to grow, especially in older age groups.
- Fee revenue is distributed evenly across channels (~$15–18M each) with no single dominant channel.
- Education and Business loans generate the highest interest income ($168M and $167M respectively).
- Credit Card is the most popular account type (4,170 accounts), followed closely by Savings (4,143).

For detailed answers to all 24 business questions with exact figures, refer to [BUSINESS_QUESTIONS.md](BUSINESS_QUESTIONS.md).

---

## Assumptions & Design Decisions

For full documentation of data quality decisions, NULL handling strategy, bucketing definitions, and Gold layer design rationale, refer to [EDA.md](EDA.md).

Key assumptions:
- **Currency**: All amounts are converted to USD using fixed exchange rates as of 2026-05-20. No real-time FX conversion is applied.
- **Revenue**: Fee revenue counts only `completed` transactions of type `fee`. Interest income uses `principal × (interest_rate / 100) × (term_months / 12)` as a simplified annualized proxy.
- **International transactions**: A transaction is international when its currency does not match the customer's country default currency (e.g. CO → COP). USD transactions are international for all 7 countries.
- **Active customer**: Has at least one open account and logged in within the last 90 days.
- **Paid-off loans**: Excluded from outstanding balance metrics — they no longer represent active exposure.

---

## Git Tags (Milestones)

| Tag | Milestone |
|-----|-----------|
| `v0.1.0-bronze` | Bronze layer complete |
| `v0.2.0-silver` | Silver layer complete |
| `v0.3.0-gold` | Gold layer complete |
| `v0.4.0-powerbi` | PowerBI dashboard complete |
| `v1.0.0` | Final submission |

---

## Cleanup

```bash
# Stop services
docker compose down

# Remove volumes (deletes all data)
docker compose down -v

# Remove images
docker compose down -v --rmi local
```

---

## Participant

- **Name**: Luciano Duarte
- **Email**: luchi94dmicrosoft@gmail.com
- **City**: Empalme Sauce, Canelones, Uruguay
- **Cohort**: Qversity 2026