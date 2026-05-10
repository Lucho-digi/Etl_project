import os
import psycopg2
import requests
import logging
import json

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator


# Constants for cleaner and more organized code.
BUCKET = os.getenv("S3_BUCKET")
KEY = os.getenv("S3_KEY")
URL = f"https://{BUCKET}.s3.amazonaws.com/{KEY}"
HOST = os.getenv("POSTGRES_HOST", "postgres")
DB = os.getenv("POSTGRES_DB")
USR = os.getenv("POSTGRES_USER")
PASS = os.getenv("POSTGRES_PASSWORD")
BATCH_SIZE = 1000

# function to create the bronze Schema and Table
def create_bronze_schema():
  conn = psycopg2.connect(
    host=HOST,
    database=DB,
    user=USR,
    password=PASS
  )
  cursor = conn.cursor()
  cursor.execute("CREATE SCHEMA IF NOT EXISTS bronze;")
  cursor.execute("""
    CREATE TABLE IF NOT EXISTS bronze.raw_fintech_data (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        data JSONB,
        load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  """)
  conn.commit()
  cursor.close()
  conn.close()

# download of the data from S3 and load it
def load_data():
  conn = psycopg2.connect(
    host=HOST,
    database=DB,
    user=USR,
    password=PASS
  )
  cursor = conn.cursor()
  try:
    req = requests.get(URL)
    req.raise_for_status()
    records = req.json()

    for i in range(0, len(records), BATCH_SIZE):
      batch = records[i:i + BATCH_SIZE]
      cursor.executemany(
        # %s is for to data be inserted safely
        "INSERT INTO bronze.raw_fintech_data (data) VALUES (%s)",
        [(json.dumps(record),) for record in batch]
      )
      conn.commit()
  except requests.exceptions.RequestException as e:
    logging.error(f"HTTP error: {e}")
  except Exception as e:
      logging.error(f"DB error: {e}")
      conn.rollback()
  finally:
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
    "bronze_pipeline",
    default_args=default_args,
    description="Bronze layer creating for Fintech/Banking ELT Pipeline",
    schedule_interval=None,
    catchup=False,
    tags=["bronze", "fintech"],
)

bronze_schema_task = PythonOperator(
  task_id='bronze_schema_task',
  python_callable=create_bronze_schema,
  dag=dag,
)

bronze_load_task = PythonOperator(
  task_id='bronze_load_task',
  python_callable=load_data,
  dag=dag,
)

bronze_schema_task >> bronze_load_task