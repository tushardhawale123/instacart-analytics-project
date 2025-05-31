USE InstacartAnalytics;
GO

-- Create tables
CREATE TABLE dbo.Departments (
    department_id INT PRIMARY KEY,
    department VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.Aisles (
    aisle_id INT PRIMARY KEY,
    aisle VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    aisle_id INT FOREIGN KEY REFERENCES dbo.Aisles(aisle_id),
    department_id INT FOREIGN KEY REFERENCES dbo.Departments(department_id)
);

CREATE TABLE dbo.Orders (
    order_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    eval_set VARCHAR(10) NOT NULL,
    order_number INT NOT NULL,
    order_dow INT NOT NULL,
    order_hour_of_day INT NOT NULL,
    days_since_prior_order FLOAT NULL
);

CREATE TABLE dbo.OrderProducts (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    add_to_cart_order INT NOT NULL,
    reordered BIT NOT NULL,
    data_source VARCHAR(10) NOT NULL, -- 'train' or 'prior'
    PRIMARY KEY (order_id, product_id, data_source),
    FOREIGN KEY (order_id) REFERENCES dbo.Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES dbo.Products(product_id)
);

-- Create indexes for better performance
CREATE INDEX IX_Orders_UserId ON dbo.Orders(user_id);
CREATE INDEX IX_Products_AisleId ON dbo.Products(aisle_id);
CREATE INDEX IX_Products_DepartmentId ON dbo.Products(department_id);
CREATE INDEX IX_OrderProducts_ProductId ON dbo.OrderProducts(product_id);