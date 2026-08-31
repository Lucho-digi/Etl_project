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


def create_gold_schema():
    conn = psycopg2.connect(
        host=HOST,
        database=DB,
        user=USER,
        password=PASS
    )
    cursor = conn.cursor()
    cursor.execute("CREATE SCHEMA IF NOT EXISTS gold;")
    conn.commit()
    cursor.close()
    conn.close()


default_args = {
    "owner": "elt_platform",
    "depends_on_past": False,
    "start_date": datetime(2026, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

dag = DAG(
    "gold_pipeline",
    default_args=default_args,
    description="Gold layer creating for Fintech/Banking ELT Pipeline",
    schedule_interval=None,
    catchup=False,
    tags=["gold", "fintech", "dbt"],
)

create_gold_schema_task = PythonOperator(
    task_id='create_gold_schema_task',
    python_callable=create_gold_schema,
    dag=dag,
)

dbt_seed_task = BashOperator(
    task_id="dbt_seed",
    bash_command="cd /opt/airflow/dbt && dbt seed --target-path /tmp/dbt-target",
    dag=dag
)

dbt_run_task = BashOperator(
    task_id="dbt_run",
    bash_command="cd /opt/airflow/dbt && dbt run --models gold --target-path /tmp/dbt-target",
    dag=dag
)

dbt_test_task = BashOperator(
    task_id="dbt_test",
    bash_command="cd /opt/airflow/dbt && dbt test --models gold --target-path /tmp/dbt-target",
    dag=dag
)

create_gold_schema_task >> dbt_seed_task >> dbt_run_task >> dbt_test_task
