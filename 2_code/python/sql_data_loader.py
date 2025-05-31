import pandas as pd
import pyodbc
import os

# Define paths
PROCESSED_DATA_PATH = '../../1_data/processed/'

# SQL Server connection details
SERVER = 'TUSHAR_NOTEBOOK\\MSSQLSERVER_TUSH'
DATABASE = 'InstacartAnalytics'

def load_data_to_sql():
    """Load processed data into SQL Server"""
    print("Loading data into SQL Server...")

    # Establish connection using Windows Authentication
    conn_str = f'DRIVER={{SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;'
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    # Load departments
    print("Loading departments...")
    departments = pd.read_csv(f'{PROCESSED_DATA_PATH}departments_cleaned.csv')
    for _, row in departments.iterrows():
        cursor.execute(
            "INSERT INTO dbo.Departments (department_id, department) VALUES (?, ?)",
            int(row.department_id), row.department
        )

    # Load aisles
    print("Loading aisles...")
    aisles = pd.read_csv(f'{PROCESSED_DATA_PATH}aisles_cleaned.csv')
    for _, row in aisles.iterrows():
        cursor.execute(
            "INSERT INTO dbo.Aisles (aisle_id, aisle) VALUES (?, ?)",
            int(row.aisle_id), row.aisle
        )

    # Load products
    print("Loading products...")
    products = pd.read_csv(f'{PROCESSED_DATA_PATH}products_cleaned.csv')
    for _, row in products.iterrows():
        cursor.execute(
            "INSERT INTO dbo.Products (product_id, product_name, aisle_id, department_id) VALUES (?, ?, ?, ?)",
            int(row.product_id), row.product_name, int(row.aisle_id), int(row.department_id)
        )

    # Load orders
    print("Loading orders...")
    orders = pd.read_csv(f'{PROCESSED_DATA_PATH}orders_cleaned.csv')
    for _, row in orders.iterrows():
        cursor.execute(
            """INSERT INTO dbo.Orders 
               (order_id, user_id, eval_set, order_number, order_dow, order_hour_of_day, days_since_prior_order) 
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            int(row.order_id), int(row.user_id), row.eval_set, int(row.order_number),
            int(row.order_dow), int(row.order_hour_of_day), 
            None if pd.isna(row.days_since_prior_order) else int(row.days_since_prior_order)
        )

    # Load order products (train)
    print("Loading order products (train)...")
    order_products_train = pd.read_csv(f'{PROCESSED_DATA_PATH}order_products_train_cleaned.csv')
    for _, row in order_products_train.iterrows():
        cursor.execute(
            """INSERT INTO dbo.OrderProducts 
               (order_id, product_id, add_to_cart_order, reordered, data_source) 
               VALUES (?, ?, ?, ?, 'train')""",
            int(row.order_id), int(row.product_id), 
            int(row.add_to_cart_order), int(row.reordered)
        )

    # Load order products (prior)
    print("Loading order products (prior)...")
    order_products_prior = pd.read_csv(f'{PROCESSED_DATA_PATH}order_products_prior_cleaned.csv')
    batch_size = 10000
    for i in range(0, len(order_products_prior), batch_size):
        batch = order_products_prior.iloc[i:i+batch_size]
        for _, row in batch.iterrows():
            cursor.execute(
                """INSERT INTO dbo.OrderProducts 
                   (order_id, product_id, add_to_cart_order, reordered, data_source) 
                   VALUES (?, ?, ?, ?, 'prior')""",
                int(row.order_id), int(row.product_id), 
                int(row.add_to_cart_order), int(row.reordered)
            )
        conn.commit()
        print(f"Processed {i + len(batch)} / {len(order_products_prior)} prior order products")

    # Final commit and close
    conn.commit()
    cursor.close()
    conn.close()

    print("Data loading to SQL Server completed.")

if __name__ == "__main__":
    load_data_to_sql()