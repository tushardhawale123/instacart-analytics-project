import pandas as pd
import numpy as np
import os

# Define paths
RAW_DATA_PATH = '../../1_data/raw/'
PROCESSED_DATA_PATH = '../../1_data/processed/'

# Create processed directory if it doesn't exist
os.makedirs(PROCESSED_DATA_PATH, exist_ok=True)

def load_and_clean_data():
    """Load and clean all dataset files"""
    print("Loading and cleaning datasets...")
    
    # Load datasets
    products = pd.read_csv(f'{RAW_DATA_PATH}products.csv')
    orders = pd.read_csv(f'{RAW_DATA_PATH}orders.csv')
    order_products_train = pd.read_csv(f'{RAW_DATA_PATH}order_products__train.csv')
    order_products_prior = pd.read_csv(f'{RAW_DATA_PATH}order_products__prior.csv')
    aisles = pd.read_csv(f'{RAW_DATA_PATH}aisles.csv')
    departments = pd.read_csv(f'{RAW_DATA_PATH}departments.csv')
    
    # Check for missing values
    print("\nMissing values in each dataset:")
    for name, df in [('products', products), ('orders', orders), 
                    ('order_products_train', order_products_train),
                    ('order_products_prior', order_products_prior),
                    ('aisles', aisles), ('departments', departments)]:
        print(f"{name}: {df.isna().sum().sum()} missing values")
    
    # Clean orders dataset
    orders['days_since_prior_order'] = orders['days_since_prior_order'].fillna(0)
    
    # Verify data types and convert if necessary
    for df in [products, orders, order_products_train, order_products_prior, aisles, departments]:
        for col in df.columns:
            if 'id' in col:
                df[col] = df[col].astype(np.int64)
    
    # Save cleaned datasets
    products.to_csv(f'{PROCESSED_DATA_PATH}products_cleaned.csv', index=False)
    orders.to_csv(f'{PROCESSED_DATA_PATH}orders_cleaned.csv', index=False)
    order_products_train.to_csv(f'{PROCESSED_DATA_PATH}order_products_train_cleaned.csv', index=False)
    order_products_prior.to_csv(f'{PROCESSED_DATA_PATH}order_products_prior_cleaned.csv', index=False)
    aisles.to_csv(f'{PROCESSED_DATA_PATH}aisles_cleaned.csv', index=False)
    departments.to_csv(f'{PROCESSED_DATA_PATH}departments_cleaned.csv', index=False)
    
    print("Data cleaning completed and saved to processed directory.")
    
    return products, orders, order_products_train, order_products_prior, aisles, departments

if __name__ == "__main__":
    products, orders, order_products_train, order_products_prior, aisles, departments = load_and_clean_data()
    
    # Print dataset summaries
    print("\nDataset summaries:")
    print(f"Products: {products.shape[0]} records")
    print(f"Orders: {orders.shape[0]} records")
    print(f"Order Products (Train): {order_products_train.shape[0]} records")
    print(f"Order Products (Prior): {order_products_prior.shape[0]} records")
    print(f"Aisles: {aisles.shape[0]} records")
    print(f"Departments: {departments.shape[0]} records")