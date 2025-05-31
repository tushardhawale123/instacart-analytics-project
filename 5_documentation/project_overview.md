# Instacart Online Grocery Analysis

## Project Overview

This project analyzes the Instacart Online Grocery Shopping Dataset to derive actionable insights about customer shopping behavior, product popularity, and reorder patterns. The project demonstrates a complete end-to-end data engineering and analytics workflow using multiple technologies:

- Python (Pandas, NumPy) for data preparation and exploration
- T-SQL in SSMS for data modeling and querying
- PySpark with Docker for distributed data processing
- Azure services for cloud storage and orchestration
- Azure Databricks for advanced analytics and machine learning
- Power BI for dashboarding and reporting

## Business Objectives

1. **Customer Behavior Analysis**: Understand shopping patterns, reorder behavior, and shopping time preferences
2. **Product Popularity**: Identify top-selling products and categories
3. **Basket Analysis**: Discover which products are frequently purchased together
4. **User Segmentation**: Segment customers based on their shopping behaviors
5. **Predictive Modeling**: Build models to predict which products customers will reorder

## Key Findings

1. **Shopping Patterns**:
   - Peak ordering hours are between 10 AM and 2 PM, and 6 PM and 8 PM
   - Most orders occur on weekdays, with weekends showing different product preferences

2. **Product Insights**:
   - Fresh produce, dairy, and snacks are the most frequently purchased departments
   - Products in the "organic" aisles have higher reorder rates than conventional alternatives

3. **Customer Segments**:
   - Identified 4 distinct customer segments based on order frequency, basket size, and reorder behavior
   - "Power users" (15% of customers) account for 35% of all orders

4. **Reorder Prediction**:
   - Developed a model with 82% accuracy in predicting which products customers will reorder
   - Key predictors include previous purchase frequency, days since last order, and product department

## Value Proposition

This analysis provides actionable insights for:

1. **Inventory Management**: Better predict demand for specific products
2. **Marketing Optimization**: Target specific customer segments with relevant promotions
3. **User Experience**: Improve the shopping experience based on time-of-day patterns
4. **Product Recommendations**: Enhance product recommendation systems with basket analysis insights