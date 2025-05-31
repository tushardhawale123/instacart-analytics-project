# Data Dictionary

## Raw Datasets

### Products (`products.csv`)
| Column | Type | Description |
| ------ | ---- | ----------- |
| product_id | INT | Unique identifier for the product |
| product_name | VARCHAR(255) | Name of the product |
| aisle_id | INT | Foreign key to the aisle table |
| department_id | INT | Foreign key to the department table |

### Orders (`orders.csv`)
| Column | Type | Description |
| ------ | ---- | ----------- |
| order_id | INT | Unique identifier for the order |
| user_id | INT | Customer identifier |
| eval_set | VARCHAR(10) | Which evaluation set this order belongs to (prior, train, test) |
| order_number | INT | The order sequence number for this user (1=first, n=nth) |
| order_dow | INT | Day of week the order was placed (0=Sunday, 6=Saturday) |
| order_hour_of_day | INT | Hour of the day the order was placed (0-23) |
| days_since_prior_order | FLOAT | Days since the last order, NULL if order_number=1 |

### Order Products - Train (`order_products__train.csv`)
| Column | Type | Description |
| ------ | ---- | ----------- |
| order_id | INT | Foreign key to the orders table |
| product_id | INT | Foreign key to the products table |
| add_to_cart_order | INT | Order in which each product was added to cart |
| reordered | BIT | 1 if this product has been ordered by this user in the past, 0 otherwise |

### Order Products - Prior (`order_products__prior.csv`)
| Column | Type | Description |
| ------ | ---- | ----------- |
| order_id | INT | Foreign key to the orders table |
| product_id | INT | Foreign key to the products table |
| add_to_cart_order | INT | Order in which each product was added to cart |
| reordered | BIT | 1 if this product has been ordered by this user in the past, 0 otherwise |

### Aisles (`aisles.csv`)
| Column | Type | Description |
| ------ | ---- | ----------- |
| aisle_id | INT | Unique identifier for the aisle |
| aisle | VARCHAR(100) | Name of the aisle |

### Departments (`departments.csv`)
| Column | Type | Description |
| ------ | ---- | ----------- |
| department_id | INT | Unique identifier for the department |
| department | VARCHAR(100) | Name of the department |

## Derived Features

### User Features
| Feature | Description | Calculation |
| ------- | ----------- | ----------- |
| user_total_orders | Total number of orders by user | COUNT(DISTINCT order_id) |
| user_avg_days_between_orders | Average days between orders | AVG(days_since_prior_order) |
| user_avg_basket_size | Average items per order | COUNT(product_id) / COUNT(DISTINCT order_id) |
| user_reorder_ratio | Ratio of reordered products | SUM(reordered) / COUNT(*) |

### Product Features
| Feature | Description | Calculation |
| ------- | ----------- | ----------- |
| product_order_count | Number of orders containing the product | COUNT(*) |
| product_reorder_rate | Rate at which product is reordered | SUM(reordered) / COUNT(*) |
| product_avg_add_to_cart_order | Average position in cart | AVG(add_to_cart_order) |

### Time Features
| Feature | Description | Calculation |
| ------- | ----------- | ----------- |
| time_of_day | Categorized time periods | CASE WHEN statements based on order_hour_of_day |
| is_weekend | Whether order was placed on weekend | CASE WHEN order_dow IN (0, 6) THEN 1 ELSE 0 END |