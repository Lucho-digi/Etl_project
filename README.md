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

### Diagram of the Architecture

![image](Diagram.png)


```
S3 (JSON) → Airflow → Bronze → PySpark (Silver) → dbt (Silver) → dbt (Gold) → PowerBI
```

## Project Structure

```
qversity-data-2026-montevideo-lucianoduarte/
├── dags/                     # Airflow DAG definitions
|   ├── bronze_dag.py         # DAG for Bronze layer ingestion
|   ├── silver_dag.py         # DAG for Silver layer transformations
|   ├── gold_dag.py           # DAG for Gold layer transformations
│   └── qversity_pipeline.py  # Main DAG orchestrating the pipeline
├── spark/                    # PySpark scripts (NEW in v2)
├── dbt/                      # dbt project
|   ├── macros/               # dbt macros
│   ├── models/
│   │   ├── bronze/           # Raw data staging
│   │   ├── silver/           # Cleaned and normalized data
│   │   └── gold/             # Business analytics
│   ├── tests/                # dbt tests
│   ├── dbt_project.yml       # dbt configuration
│   └── profiles.yml          # Database connections
├── powerbi/                  # PowerBI deliverables (NEW in v2)
│   ├── dashboard.pbix        # PowerBI file with 4 pages of visualizations
│   └── screenshots/          # Dashboard page screenshots
├── data/
│   └── raw/                  # Raw input data
├── docker-compose.yml        # Docker environment setup
├── env.example               # Environment variables template
├── requirements.txt          # Python dependencies
├── .gitignore
├── .pre-commit-config.yaml   # Code quality hooks
└── README.md                 # This file
```

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
It's highly recommended to use POSTGRES_PORT=5432 as it may conflict with an existing local postgres installation and u will need to change the docker-compose.yml file to reflect the new port.

2. **Start services**:
```bash
docker compose up -d --build
```

3. **Verify services are running**:
```bash
docker compose ps
```

4. **Access Airflow UI**: http://localhost:8080 
You need to define the User and Password in the .env file before starting the services, by the way we recommend using the default credentials for testing purposes:
> User: admin \
> Password: admin

5. **Trigger the pipeline** (once you've built it):
```bash
docker compose exec airflow airflow dags trigger qversity_pipeline
```

## Access Points

| Service | URL / Connection | Credentials |
|---------|-----------------|-------------|
| Airflow UI | http://localhost:8080 | define in .env |
| PostgreSQL | localhost:5432 | define in .env |
| Database | qversity | — |

## Common Commands

### Key dbt commands
```bash
# Enter dbt container
docker compose exec dbt bash

# Run all models
dbt run

# Run specific layer
dbt run --models bronze
dbt run --models silver
dbt run --models gold

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
## Architecture

This project implements a **Bronze-Silver-Gold** data lakehouse architecture for a LATAM Fintech/Banking dataset:

- **Bronze Layer**: Raw JSON ingestion from S3 into PostgreSQL (`jsonb`)
- **Silver Layer (PySpark)**: Flatten nested arrays, deduplicate
- **Silver Layer (dbt)**: Clean, standardize, and normalize PySpark output; flatten nested objects
- **Gold Layer (dbt)**: Business-ready analytics and aggregations answering 24 business questions
- **PowerBI**: 4-page dashboard connected to Gold layer tables 

The role of main technologies:
- **Airflow**: Orchestrates the ELT pipeline with DAGs and tasks
- **PostgreSQL**: Stores raw and processed data in a structured format
- **PySpark**: Handles complex transformations on nested JSON data
- **dbt**: Manages SQL transformations, testing for Silver and Gold  
- **PowerBI**: Visualizes key metrics and insights for business stakeholders

## Data Model

The data model consists of 6 main entities: Customers, Accounts, Transactions, Loans, Credit Info and Digital Engagement. Each entity has a corresponding table in the Silver, and Gold layers, with increasing levels of transformation and business logic applied.

For silver we had to flatten the nested arrays and objects in the raw JSON data, while for gold we implemented business logic to create standardized metrics and dimensions for analytics. There is a ERD diagram of silver:

![image](SilverERD.svg)

For more details on the data model and transformations, please refer to [EDA](EDA.md) and the dbt models in the `dbt/models/` directory.

## Git Tags (Milestones)

Submit your work incrementally:

```bash
git tag -a v0.1.0-bronze -m "Bronze layer complete"
git tag -a v0.2.0-silver -m "Silver layer complete"
git tag -a v0.3.0-gold -m "Gold layer complete"
git tag -a v0.4.0-powerbi -m "PowerBI dashboard complete"
git tag -a v1.0.0 -m "Final submission"
```

## Cleanup

```bash
# Stop services
docker compose down

# Remove volumes (deletes all data)
docker compose down -v

# Remove images
docker compose down -v --rmi local
```

## Participant

- **Name**: Luciano Duarte
- **Email**: luchi94dmicrosoft@gmail.com
- **City**: Empalme Sauce, Canelones, Uruguay
- **Cohort**: Qversity 2026

