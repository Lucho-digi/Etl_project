import os
import psycopg2

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

HOST = os.getenv("POSTGRES_HOST", "postgres")
DB = os.getenv("POSTGRES_DB")
USER = os.getenv("POSTGRES_USER")
PASS = os.getenv("POSTGRES_PASSWORD")


def create_silver_schema():
  conn = psycopg2.connect(
    host=HOST,
    database=DB,
    user=USER,
    password=PASS
  )
  cursor = conn.cursor()
  cursor.execute("CREATE SCHEMA IF NOT EXISTS silver;")
  conn.commit()
  cursor.close()
  conn.close()

default_args = {
  "owner": "qversity",
  "depends_on_past": False,
  "start_date": datetime(2026, 1, 1),
  "email_on_failure": False,
  "email_on_retry": False,
  "retries": 1,
  "retry_delay": timedelta(minutes=5),
}

dag = DAG(
  "silver_pipeline",
  default_args=default_args,
  description="Silver layer creating for Fintech/Banking ELT Pipeline",
  schedule_interval=None,
  catchup=False,
  tags=["silver", "fintech"],
)

create_silver_schema_task = PythonOperator(
  task_id='create_silver_schema_task',
  python_callable=create_silver_schema,
  dag=dag,
)

dedup_task = BashOperator(
  task_id="dedup_task",
  bash_command="spark-submit --packages org.postgresql:postgresql:42.6.2 /opt/airflow/spark/dedup.py",
  dag=dag
)

flatten_accounts_task = BashOperator(
  task_id="flatten_accounts",
  bash_command="spark-submit --packages org.postgresql:postgresql:42.6.2 /opt/airflow/spark/flatten_accounts.py",
  dag=dag
)

flatten_loans_task = BashOperator(
  task_id="flatten_loans",
  bash_command="spark-submit --packages org.postgresql:postgresql:42.6.2 /opt/airflow/spark/flatten_loans.py",
  dag=dag
)

flatten_transactions_task = BashOperator(
  task_id="flatten_transactions",
  bash_command="spark-submit --packages org.postgresql:postgresql:42.6.2 /opt/airflow/spark/flatten_transactions.py",
  dag=dag
)
dbt_run_task = BashOperator(
  task_id="dbt_run",
  bash_command="cd /opt/airflow/dbt && dbt run --models silver --target-path /tmp/dbt-target",
  dag=dag
)
dbt_test_task = BashOperator(
  task_id="dbt_test",
  bash_command="cd /opt/airflow/dbt && dbt test --models silver --target-path /tmp/dbt-target",
  dag=dag
)

create_silver_schema_task >> dedup_task >> [flatten_accounts_task, flatten_loans_task, flatten_transactions_task] >> dbt_run_task >> dbt_test_task