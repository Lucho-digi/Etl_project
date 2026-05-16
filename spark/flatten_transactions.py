from pyspark.sql.window import Window
import os
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, row_number, from_json, schema_of_json

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
 spark = SparkSession.builder.appName("FlattenTransactions") \
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

transactions_df = df.select(
  col("id"),
  col("load_timestamp"),
  col("data.customer_id").alias("customer_id"),
  explode(col("data.transactions")).alias("transactions")
).select(
  col("customer_id"),
  col("load_timestamp"),
  col("transactions.transaction_id"),
  col("transactions.account_id"),
  col("transactions.date"),
  col("transactions.amount"),
  col("transactions.currency"),
  col("transactions.type"),
  col("transactions.category"),
  col("transactions.merchant"),
  col("transactions.channel"),
  col("transactions.status"),
  col("transactions.description")
)

window = Window.partitionBy("transaction_id").orderBy(col("load_timestamp").asc())

deduplicated_transactions_df = transactions_df.withColumn("row_number", row_number().over(window)) \
    .filter(col("row_number") == 1) \
    .drop("row_number", "load_timestamp")

deduplicated_transactions_df.write.jdbc(url=JDBC_URL, table="silver.stg_customers", mode="overwrite", properties=JDBC_PROPERTIES)