USE InstacartAnalytics;
GO

-- 1. Most Popular Products
-- Identifies top products by order frequency
CREATE OR ALTER VIEW dbo.vw_MostPopularProducts AS
SELECT TOP 100
    p.product_id,
    p.product_name,
    a.aisle,
    d.department,
    COUNT(DISTINCT op.order_id) AS order_count,
    SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS reorder_count,
    CAST(SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS FLOAT) / 
        COUNT(op.order_id) AS reorder_rate
FROM 
    dbo.OrderProducts op
    JOIN dbo.Products p ON op.product_id = p.product_id
    JOIN dbo.Aisles a ON p.aisle_id = a.aisle_id
    JOIN dbo.Departments d ON p.department_id = d.department_id
GROUP BY 
    p.product_id, p.product_name, a.aisle, d.department
ORDER BY 
    order_count DESC;
GO

-- 2. Product Reorder Rates by Department
-- Analyzes which departments have the highest reorder rates
CREATE OR ALTER VIEW dbo.vw_ReorderRatesByDepartment AS
SELECT 
    d.department_id,
    d.department,
    COUNT(DISTINCT op.order_id) AS total_orders,
    SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS reordered_count,
    CAST(SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS FLOAT) / 
        COUNT(op.order_id) AS reorder_rate
FROM 
    dbo.OrderProducts op
    JOIN dbo.Products p ON op.product_id = p.product_id
    JOIN dbo.Departments d ON p.department_id = d.department_id
GROUP BY 
    d.department_id, d.department;
GO


-- 3. Order Distribution by Hour and Day of Week
-- Shows when customers tend to place orders
CREATE OR ALTER VIEW dbo.vw_OrderDistribution AS
SELECT
    order_dow AS day_of_week,
    CASE order_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    order_hour_of_day AS hour_of_day,
    COUNT(*) AS order_count,
    CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER() AS percentage_of_total
FROM
    dbo.Orders
GROUP BY
    order_dow, order_hour_of_day;
GO


-- 4. Customer Segmentation by Order Frequency
-- Segments customers based on their ordering patterns
CREATE OR ALTER VIEW dbo.vw_CustomerSegmentation AS
WITH CustomerStats AS (
    SELECT
        user_id,
        COUNT(DISTINCT order_id) AS total_orders,
        AVG(CAST(days_since_prior_order AS FLOAT)) AS avg_days_between_orders,
        MAX(order_number) AS max_order_number
    FROM
        dbo.Orders
    GROUP BY
        user_id
)
SELECT
    user_id,
    total_orders,
    avg_days_between_orders,
    max_order_number,
    CASE
        WHEN total_orders >= 10 AND avg_days_between_orders <= 10 THEN 'Frequent Shopper'
        WHEN total_orders >= 5 AND avg_days_between_orders <= 15 THEN 'Regular Shopper'
        WHEN total_orders >= 2 THEN 'Occasional Shopper'
        ELSE 'One-time Shopper'
    END AS customer_segment
FROM
    CustomerStats;
GO

-- 5. Product Association Analysis
-- Finds products that are frequently purchased together
CREATE OR ALTER VIEW dbo.vw_ProductAssociations AS
WITH OrderPairs AS (
    SELECT
        a.order_id,
        a.product_id AS product_id_1,
        b.product_id AS product_id_2
    FROM
        dbo.OrderProducts a
        JOIN dbo.OrderProducts b ON a.order_id = b.order_id AND a.product_id < b.product_id
)
SELECT TOP 1000
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    COUNT(*) AS pair_frequency,
    CAST(COUNT(*) AS FLOAT) / (
        SELECT COUNT(*) FROM dbo.Orders
    ) AS support
FROM
    OrderPairs op
    JOIN dbo.Products p1 ON op.product_id_1 = p1.product_id
    JOIN dbo.Products p2 ON op.product_id_2 = p2.product_id
GROUP BY
    p1.product_name, p2.product_name
HAVING
    COUNT(*) >= 10
ORDER BY
    pair_frequency DESC;
GO

-- 6. Basket Size Analysis
-- Analyzes the number of items per order and trends
CREATE OR ALTER VIEW dbo.vw_BasketSizeAnalysis AS
WITH BasketSizes AS (
    SELECT
        o.order_id,
        o.user_id,
        o.order_dow,
        o.order_hour_of_day,
        COUNT(op.product_id) AS basket_size
    FROM
        dbo.Orders o
        JOIN dbo.OrderProducts op ON o.order_id = op.order_id
    GROUP BY
        o.order_id, o.user_id, o.order_dow, o.order_hour_of_day
)
SELECT
    order_dow,
    CASE order_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    order_hour_of_day,
    AVG(basket_size) OVER (PARTITION BY order_dow, order_hour_of_day) AS avg_basket_size,
    MIN(basket_size) OVER (PARTITION BY order_dow, order_hour_of_day) AS min_basket_size,
    MAX(basket_size) OVER (PARTITION BY order_dow, order_hour_of_day) AS max_basket_size,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY basket_size) 
        OVER (PARTITION BY order_dow, order_hour_of_day) AS median_basket_size,
    COUNT(*) OVER (PARTITION BY order_dow, order_hour_of_day) AS order_count
FROM
    BasketSizes;
GO



-- 7. Aisle Popularity by Time of Day
-- Shows which aisles are popular at different times of day
CREATE OR ALTER VIEW dbo.vw_AislePopularityByTime AS
SELECT
    a.aisle_id,
    a.aisle,
    CASE
        WHEN o.order_hour_of_day BETWEEN 5 AND 8 THEN 'Early Morning (5-8)'
        WHEN o.order_hour_of_day BETWEEN 9 AND 11 THEN 'Morning (9-11)'
        WHEN o.order_hour_of_day BETWEEN 12 AND 14 THEN 'Midday (12-14)'
        WHEN o.order_hour_of_day BETWEEN 15 AND 17 THEN 'Afternoon (15-17)'
        WHEN o.order_hour_of_day BETWEEN 18 AND 20 THEN 'Evening (18-20)'
        ELSE 'Night (21-4)'
    END AS time_of_day,
    COUNT(*) AS order_count,
    CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER (
        PARTITION BY a.aisle_id
    ) AS percentage_of_aisle_total
FROM
    dbo.OrderProducts op
    JOIN dbo.Orders o ON op.order_id = o.order_id
    JOIN dbo.Products p ON op.product_id = p.product_id
    JOIN dbo.Aisles a ON p.aisle_id = a.aisle_id
GROUP BY
    a.aisle_id, a.aisle, 
    CASE
        WHEN o.order_hour_of_day BETWEEN 5 AND 8 THEN 'Early Morning (5-8)'
        WHEN o.order_hour_of_day BETWEEN 9 AND 11 THEN 'Morning (9-11)'
        WHEN o.order_hour_of_day BETWEEN 12 AND 14 THEN 'Midday (12-14)'
        WHEN o.order_hour_of_day BETWEEN 15 AND 17 THEN 'Afternoon (15-17)'
        WHEN o.order_hour_of_day BETWEEN 18 AND 20 THEN 'Evening (18-20)'
        ELSE 'Night (21-4)'
    END;
GO


-- 8. Customer Purchase Patterns
-- Detailed analysis of user-product relationships
CREATE OR ALTER VIEW dbo.vw_CustomerPurchasePatterns AS
WITH UserProductStats AS (
    SELECT
        o.user_id,
        op.product_id,
        COUNT(*) AS purchase_count,
        SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS reorder_count,
        CAST(SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS FLOAT) / 
            COUNT(*) AS reorder_rate,
        AVG(op.add_to_cart_order) AS avg_cart_position
    FROM
        dbo.Orders o
        JOIN dbo.OrderProducts op ON o.order_id = op.order_id
    GROUP BY
        o.user_id, op.product_id
)
SELECT
    ups.user_id,
    ups.product_id,
    p.product_name,
    a.aisle,
    d.department,
    ups.purchase_count,
    ups.reorder_count,
    ups.reorder_rate,
    ups.avg_cart_position,
    DENSE_RANK() OVER (
        PARTITION BY ups.user_id
        ORDER BY ups.purchase_count DESC
    ) AS product_rank_by_user
FROM
    UserProductStats ups
    JOIN dbo.Products p ON ups.product_id = p.product_id
    JOIN dbo.Aisles a ON p.aisle_id = a.aisle_id
    JOIN dbo.Departments d ON p.department_id = d.department_id
WHERE
    ups.purchase_count >= 2; -- Focus on products purchased at least twice
GO

-- Example queries to execute the views
SELECT * FROM dbo.vw_MostPopularProducts;
SELECT * FROM dbo.vw_ReorderRatesByDepartment;
SELECT * FROM dbo.vw_OrderDistribution;
SELECT * FROM dbo.vw_CustomerSegmentation;
SELECT * FROM dbo.vw_ProductAssociations;
SELECT * FROM dbo.vw_BasketSizeAnalysis;
SELECT * FROM dbo.vw_AislePopularityByTime;
SELECT * FROM dbo.vw_CustomerPurchasePatterns WHERE user_id IN (
    SELECT TOP 10 user_id FROM dbo.Orders GROUP BY user_id ORDER BY COUNT(*) DESC
);
GO