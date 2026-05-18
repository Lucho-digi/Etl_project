import os
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, from_json, row_number, when, lit
from pyspark.sql.window import Window
from functools import reduce
import operator

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

json_schema = spark.read.json(df.select("data").rdd.map(lambda r: r[0])).schema
df = df.withColumn("data", from_json(col("data").cast("string"), json_schema))

transactions_df = df.select(
  col("data.customer_id").alias("customer_id"),
  explode(col("data.transactions")).alias("transactions")
).select(
  col("customer_id"),
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

null_count_expr = reduce(operator.add, [
    when(col(c).isNull(), lit(1)).otherwise(lit(0))
    for c in transactions_df.columns
])

transactions_df = transactions_df.withColumn("null_count", null_count_expr)

window = Window.partitionBy("transaction_id").orderBy(
    col("null_count").asc(),
    col("date").desc()
)

transactions_df = transactions_df.withColumn("rn", row_number().over(window)) \
    .filter(col("rn") == 1) \
    .drop("rn", "null_count")

transactions_df.write.jdbc(url=JDBC_URL, table="silver.stg_transactions", mode="overwrite", properties=JDBC_PROPERTIES)