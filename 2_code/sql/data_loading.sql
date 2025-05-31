-- SQL Server data loading script for Instacart Analytics Project
-- This script loads data from processed CSV files into SQL Server tables
-- Author: Tushar Dhawale
-- Date: 2025-05-30

USE InstacartAnalytics;
GO

-- Enable bulk insert operations
SET NOCOUNT ON;
GO

-- Create a temporary procedure to handle bulk inserts with error handling
CREATE OR ALTER PROCEDURE dbo.BulkInsertData
    @TableName NVARCHAR(128),
    @FilePath NVARCHAR(512),
    @Delimiter CHAR(1) = ',',
    @FirstRowHasColumnNames BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ErrorMsg NVARCHAR(4000);
    
    BEGIN TRY
        -- Create the dynamic SQL for BCP
        SET @SQL = N'
        BULK INSERT ' + @TableName + '
        FROM ''' + @FilePath + '''
        WITH (
            FORMAT = ''CSV'',
            FIELDTERMINATOR = ''' + @Delimiter + ''',
            FIRSTROW = ' + CASE WHEN @FirstRowHasColumnNames = 1 THEN '2' ELSE '1' END + ',
            TABLOCK,
            MAXERRORS = 0,
            CODEPAGE = ''65001'' -- UTF-8
        );';
        
        -- Execute the dynamic SQL
        EXEC sp_executesql @SQL;
        
        -- Log success
        PRINT 'Successfully loaded data into ' + @TableName;
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();
        RAISERROR('Error loading data into %s: %s', 16, 1, @TableName, @ErrorMsg);
    END CATCH
END;
GO

-- Set the base file path - update this to your actual file location
DECLARE @BasePath NVARCHAR(512) = 'C:\Projects\instacart-analytics-project\1_data\processed\';

-- Clear existing data (if any)
PRINT 'Cleaning existing data...';
DELETE FROM dbo.OrderProducts;
DELETE FROM dbo.Orders;
DELETE FROM dbo.Products;
DELETE FROM dbo.Aisles;
DELETE FROM dbo.Departments;
GO

-- Load departments
PRINT 'Loading departments...';
EXEC dbo.BulkInsertData 
    @TableName = 'dbo.Departments', 
    @FilePath = 'C:\Projects\instacart-analytics-project\1_data\processed\departments_cleaned.csv';

-- Load aisles
PRINT 'Loading aisles...';
EXEC dbo.BulkInsertData 
    @TableName = 'dbo.Aisles', 
    @FilePath = 'C:\Projects\instacart-analytics-project\1_data\processed\aisles_cleaned.csv';

-- Load products
PRINT 'Loading products...';
EXEC dbo.BulkInsertData 
    @TableName = 'dbo.Products', 
    @FilePath = 'C:\Projects\instacart-analytics-project\1_data\processed\products_cleaned.csv';

-- Load orders
PRINT 'Loading orders...';
EXEC dbo.BulkInsertData 
    @TableName = 'dbo.Orders', 
    @FilePath = 'C:\Projects\instacart-analytics-project\1_data\processed\orders_cleaned.csv';

-- Load order products (train)
PRINT 'Loading order products (train)...';
EXEC dbo.BulkInsertData 
    @TableName = 'dbo.OrderProducts', 
    @FilePath = 'C:\Projects\instacart-analytics-project\1_data\processed\order_products_train_cleaned.csv';

-- Update data source for train data
UPDATE dbo.OrderProducts
SET data_source = 'train'
WHERE data_source IS NULL;

-- Load order products (prior)
PRINT 'Loading order products (prior)...';
EXEC dbo.BulkInsertData 
    @TableName = 'dbo.OrderProducts', 
    @FilePath = 'C:\Projects\instacart-analytics-project\1_data\processed\order_products_prior_cleaned.csv';

-- Update data source for prior data
UPDATE dbo.OrderProducts
SET data_source = 'prior'
WHERE data_source IS NULL;

-- Validate loaded data
PRINT 'Validating loaded data...';

SELECT 'Departments' as [Table], COUNT(*) as [Row Count] FROM dbo.Departments
UNION ALL
SELECT 'Aisles', COUNT(*) FROM dbo.Aisles
UNION ALL
SELECT 'Products', COUNT(*) FROM dbo.Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL
SELECT 'OrderProducts (train)', COUNT(*) FROM dbo.OrderProducts WHERE data_source = 'train'
UNION ALL
SELECT 'OrderProducts (prior)', COUNT(*) FROM dbo.OrderProducts WHERE data_source = 'prior';

-- Clean up temporary procedure
DROP PROCEDURE IF EXISTS dbo.BulkInsertData;

PRINT 'Data loading completed successfully.';
GO