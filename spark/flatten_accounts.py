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
 spark = SparkSession.builder.appName("FlattenAccounts") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.6.20") \
    .getOrCreate()
except Exception as e:
  logging.error(f"Error creating Spark session: {e}")
  raise

df = spark.read.jdbc(url=JDBC_URL, table="silver.stg_raw_deduplicated", properties=JDBC_PROPERTIES)

json_schema = spark.read.json(df.select("data").rdd.map(lambda r: r[0])).schema
df = df.withColumn("data", from_json(col("data").cast("string"), json_schema))

accounts_df = df.select(
  col("data.customer_id").alias("customer_id"),
  explode(col("data.accounts")).alias("accounts")
).select(
  col("customer_id"),
  col("accounts.account_id"),
  col("accounts.account_type"),
  col("accounts.currency"),
  col("accounts.balance"),
  col("accounts.credit_limit"),
  col("accounts.interest_rate"),
  col("accounts.opened_date"),
  col("accounts.status"),
  col("accounts.branch_code")
)

null_count_expr = reduce(operator.add, [
    when(col(c).isNull(), lit(1)).otherwise(lit(0))
    for c in accounts_df.columns
])

accounts_df = accounts_df.withColumn("null_count", null_count_expr)

window = Window.partitionBy("account_id").orderBy(
    col("null_count").asc(),
    col("opened_date").desc()
)

accounts_df = accounts_df.withColumn("rn", row_number().over(window)) \
    .filter(col("rn") == 1) \
    .drop("rn", "null_count")

accounts_df.write.jdbc(url=JDBC_URL, table="silver.stg_accounts", mode="overwrite", properties=JDBC_PROPERTIES)