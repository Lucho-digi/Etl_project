import os
import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, row_number, when, get_json_object, lit
from functools import reduce
import operator
from pyspark.sql.window import Window

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
  spark = SparkSession.builder.appName("DeduplicateRawData") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.6.2") \
    .getOrCreate()
except Exception as e:
  logging.error(f"Error creating Spark session: {e}")
  raise

df = spark.read.jdbc(url=JDBC_URL, table="bronze.raw_fintech_data", properties=JDBC_PROPERTIES)

df = df.withColumn("customer_id", get_json_object(col("data"), "$.customer_id"))

null_count_expr = reduce(operator.add, [
    when(get_json_object(col("data"), f"$.{field}").isNull(), lit(1)).otherwise(lit(0))
    for field in ["email", "phone_number", "date_of_birth", "address", "kyc_status", "risk_score"]
])

df = df.withColumn("null_count", null_count_expr)
df = df.withColumn("registration_date", get_json_object(col("data"), "$.registration_date"))

window = Window.partitionBy("customer_id").orderBy(
  col("null_count").asc(),
  col("registration_date").asc()
)

deduplicated_df = df.withColumn("rn", row_number().over(window)) \
  .filter(col("rn") == 1) \
  .drop("rn", "null_count", "customer_id", "registration_date")

deduplicated_df.write.jdbc(url=JDBC_URL, table="silver.stg_raw_deduplicated", mode="overwrite", properties=JDBC_PROPERTIES)