import os
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode_outer, from_json, schema_of_json

POSTGRES_HOST = os.getenv("POSTGRES_HOST")
POSTGRES_PORT = os.getenv("POSTGRES_PORT")
POSTGRES_DB = os.getenv("POSTGRES_DB")
POSTGRES_USER = os.getenv("POSTGRES_USER")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")

JDBC_URL = f"jdbc:postgresql://{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
JDBC_PROPERTIES = {
  "user": POSTGRES_USER,
  "password": POSTGRES_PASSWORD,
  "driver": "org.postgresql.Driver"
}


try:
 spark = SparkSession.builder.appName("FlattenLoans") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.6.20") \
    .getOrCreate()
except Exception as e:
  logging.error(f"Error creating Spark session: {e}")
  raise

df = spark.read.jdbc(url=JDBC_URL, table="silver.stg_raw_deduplicated", properties=JDBC_PROPERTIES)

# Parse data column from STRING to struct
sample = df.select("data").first()[0]
json_schema = schema_of_json(sample)
df = df.withColumn("data", from_json(col("data").cast("string"), json_schema))

loans_df = df.select(
  col("id"),
  col("load_timestamp"),
  col("data.customer_id").alias("customer_id"),
  explode_outer(col("data.loans")).alias("loans")
).select(
  col("customer_id"),
  col("loans.loan_id"),
  col("loans.type"),
  col("loans.currency"),
  col("loans.principal"),
  col("loans.outstanding_balance"),
  col("loans.interest_rate"),
  col("loans.term_months"),
  col("loans.monthly_payment"),
  col("loans.start_date"),
  col("loans.end_date"),
  col("loans.status"),
  col("loans.days_past_due"),
  col("loans.collateral_type")
)

loans_df.write.jdbc(url=JDBC_URL, table="silver.stg_loans", mode="overwrite", properties=JDBC_PROPERTIES)