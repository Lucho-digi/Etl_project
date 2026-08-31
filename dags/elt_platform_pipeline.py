from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

default_args = {
  "owner": "qversity",
  "depends_on_past": False,
  "start_date": datetime(2026, 1, 1),
  "email_on_failure": False,
  "email_on_retry": False,
  "retries": 1,
  "retry_delay": timedelta(minutes=5),
}

with DAG(
  "qversity_pipeline",
  default_args=default_args,
  description="Pipeline to orchestrate the execution of bronze, silver and gold layers for Fintech/Banking ELT Pipeline",
  schedule_interval=None,
  catchup=False,
  tags=["orchestrator", "qversity", "bronze", "silver", "gold"],
) as dag:

  trigger_bronze = TriggerDagRunOperator(
    task_id="trigger_bronze_pipeline",
    trigger_dag_id="bronze_pipeline",
    wait_for_completion=True,
    reset_dag_run=True,
  )

  trigger_silver = TriggerDagRunOperator(
    task_id="trigger_silver_pipeline",
    trigger_dag_id="silver_pipeline",
    wait_for_completion=True,
    reset_dag_run=True,
  )

  trigger_gold = TriggerDagRunOperator(
    task_id="trigger_gold_pipeline",
    trigger_dag_id="gold_pipeline",
    wait_for_completion=True,
    reset_dag_run=True,
  )

  trigger_bronze >> trigger_silver >> trigger_gold
