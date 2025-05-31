from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, sum, avg, desc, rank, dense_rank
from pyspark.sql.window import Window
import os

# Initialize Spark session
spark = SparkSession.builder \
    .appName("Instacart Data Analysis") \
    .config("spark.executor.memory", "2g") \
    .getOrCreate()

# Define paths
DATA_PATH = '/home/jovyan/work/1_data/processed/'
OUTPUT_PATH = '/home/jovyan/work/1_data/spark_output/'

# Create output directory if it doesn't exist
os.makedirs(OUTPUT_PATH, exist_ok=True)

# Load datasets
products = spark.read.csv(f"{DATA_PATH}products_cleaned.csv", header=True, inferSchema=True)
orders = spark.read.csv(f"{DATA_PATH}orders_cleaned.csv", header=True, inferSchema=True)
order_products_prior = spark.read.csv(f"{DATA_PATH}order_products_prior_cleaned.csv", header=True, inferSchema=True)
order_products_train = spark.read.csv(f"{DATA_PATH}order_products_train_cleaned.csv", header=True, inferSchema=True)
aisles = spark.read.csv(f"{DATA_PATH}aisles_cleaned.csv", header=True, inferSchema=True)
departments = spark.read.csv(f"{DATA_PATH}departments_cleaned.csv", header=True, inferSchema=True)

# Register temporary views
products.createOrReplaceTempView("products")
orders.createOrReplaceTempView("orders")
order_products_prior.createOrReplaceTempView("order_products_prior")
order_products_train.createOrReplaceTempView("order_products_train")
aisles.createOrReplaceTempView("aisles")
departments.createOrReplaceTempView("departments")

# Combine order products data
order_products = order_products_prior.withColumn("data_source", col("reordered").cast("string")) \
    .union(order_products_train.withColumn("data_source", col("reordered").cast("string")))

# Analysis 1: Most popular products
print("Calculating most popular products...")
popular_products = order_products.groupBy("product_id") \
    .agg(count("*").alias("order_count")) \
    .join(products, "product_id") \
    .join(aisles, "aisle_id") \
    .join(departments, "department_id") \
    .select("product_id", "product_name", "aisle", "department", "order_count") \
    .orderBy(desc("order_count"))

popular_products.write.csv(f"{OUTPUT_PATH}popular_products", header=True, mode="overwrite")

# Analysis 2: Reorder rates by department
print("Calculating reorder rates by department...")
reorder_rates = order_products.groupBy("product_id") \
    .agg(
        count("*").alias("total_orders"),
        sum(col("reordered").cast("int")).alias("reorder_count")
    ) \
    .withColumn("reorder_rate", col("reorder_count") / col("total_orders")) \
    .join(products, "product_id") \
    .join(departments, "department_id") \
    .groupBy("department_id", "department") \
    .agg(avg("reorder_rate").alias("avg_reorder_rate")) \
    .orderBy(desc("avg_reorder_rate"))

reorder_rates.write.csv(f"{OUTPUT_PATH}reorder_rates_by_department", header=True, mode="overwrite")

# Analysis 3: Order patterns by hour of day
print("Analyzing order patterns by hour of day...")
hour_patterns = orders.groupBy("order_hour_of_day") \
    .agg(count("*").alias("order_count")) \
    .orderBy("order_hour_of_day")

hour_patterns.write.csv(f"{OUTPUT_PATH}order_hour_patterns", header=True, mode="overwrite")

# Analysis 4: User purchase frequency
print("Analyzing user purchase patterns...")
user_frequency = orders.groupBy("user_id") \
    .agg(count("*").alias("order_count")) \
    .orderBy(desc("order_count"))

user_frequency.write.csv(f"{OUTPUT_PATH}user_frequency", header=True, mode="overwrite")

# Analysis 5: Top products by aisle
print("Finding top products by aisle...")
windowSpec = Window.partitionBy("aisle_id").orderBy(desc("product_count"))

top_aisle_products = order_products.groupBy("product_id") \
    .agg(count("*").alias("product_count")) \
    .join(products, "product_id") \
    .join(aisles, "aisle_id") \
    .select("aisle_id", "aisle", "product_id", "product_name", "product_count") \
    .withColumn("rank", dense_rank().over(windowSpec)) \
    .filter(col("rank") <= 5) \
    .orderBy("aisle", "rank")

top_aisle_products.write.csv(f"{OUTPUT_PATH}top_aisle_products", header=True, mode="overwrite")

print(f"Spark processing complete. Results saved to {OUTPUT_PATH}")

# Stop Spark session
spark.stop()