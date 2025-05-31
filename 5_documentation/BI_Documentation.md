# Instacart Analytics Dashboard Documentation

**Project:** Instacart Analytics Dashboard  
**Author:** tushardhawale123  
**Last Updated:** 2025-05-31 11:32:07  
**Version:** 1.0

## 1. Dashboard Overview

This Power BI solution provides comprehensive analytics on Instacart customer behavior and product performance. The dashboard consists of three main pages:

- **Executive Overview:** High-level KPIs and trends
- **Customer Analysis:** Segment-based customer behavior analytics
- **Product Analysis:** Product performance metrics and insights

## 2. Data Model

### 2.1 Tables and Relationships

| Table Name | Primary Key | Connected To | Relationship Type |
|------------|------------|--------------|-------------------|
| Orders | order_id | All Order Products[order_id] | One-to-many |
| Orders | user_id | User Segments[user_id] | Many-to-one |
| Products | product_id | All Order Products[product_id] | One-to-many |
| Departments | department_id | Products[department_id] | One-to-many |
| User Segments | user_id | Orders[user_id] | One-to-many |
| All Order Products | [composite] | Orders, Products | Many-to-one |

### 2.2 Calculated Columns

```DAX
TimeOfDay = 
SWITCH(
    TRUE(),
    'Orders'[order_hour_of_day] >= 5 && 'Orders'[order_hour_of_day] < 9, "Early Morning (5-8)",
    'Orders'[order_hour_of_day] >= 9 && 'Orders'[order_hour_of_day] < 12, "Morning (9-11)",
    'Orders'[order_hour_of_day] >= 12 && 'Orders'[order_hour_of_day] < 15, "Midday (12-14)",
    'Orders'[order_hour_of_day] >= 15 && 'Orders'[order_hour_of_day] < 18, "Afternoon (15-17)",
    'Orders'[order_hour_of_day] >= 18 && 'Orders'[order_hour_of_day] < 21, "Evening (18-20)",
    "Night (21-4)"
)

DayName = 
SWITCH(
    'Orders'[order_dow],
    0, "Sunday",
    1, "Monday",
    2, "Tuesday",
    3, "Wednesday",
    4, "Thursday", 
    5, "Friday",
    6, "Saturday",
    "Unknown"
)

Product Display Name = 
VAR ProductName = SELECTEDVALUE(Products[product_name])
RETURN
IF(LEN(ProductName) > 25, 
   LEFT(ProductName, 22) & "...", 
   ProductName)
```

## 3. Key Measures Documentation

### 3.1 Core KPI Measures

```DAX
Total Products = DISTINCTCOUNT(Products[product_id])

Total Orders = COUNTROWS('Orders')

Avg Products Per Order = 
DIVIDE(
    COUNTROWS('All Order Products'),
    DISTINCTCOUNT('All Order Products'[order_id]),
    0
)

Overall Reorder Rate = 
DIVIDE(
    CALCULATE(
        COUNTROWS('All Order Products'),
        'All Order Products'[reordered] = 1
    ),
    COUNTROWS('All Order Products'),
    0
)

Total Departments = DISTINCTCOUNT(Departments[department])
```

### 3.2 Segment Analysis Measures

```DAX
Orders by Time of Day and Segment Corrected = 
VAR CurrentSegment = SELECTEDVALUE('User Segments'[prediction])
VAR CurrentTimeOfDay = SELECTEDVALUE('Orders'[TimeOfDay])
RETURN
IF(
    ISBLANK(CurrentSegment) || ISBLANK(CurrentTimeOfDay),
    BLANK(),
    CALCULATE(
        COUNTROWS('Orders'),
        'User Segments'[prediction] = CurrentSegment,
        'Orders'[TimeOfDay] = CurrentTimeOfDay,
        USERELATIONSHIP('Orders'[user_id], 'User Segments'[user_id])
    )
)

Orders by Day and Segment Corrected = 
VAR CurrentSegment = SELECTEDVALUE('User Segments'[prediction])
VAR CurrentDOW = SELECTEDVALUE('Orders'[order_dow])
RETURN
IF(
    ISBLANK(CurrentSegment) || ISBLANK(CurrentDOW),
    BLANK(),
    CALCULATE(
        COUNTROWS('Orders'),
        'User Segments'[prediction] = CurrentSegment,
        'Orders'[order_dow] = CurrentDOW,
        USERELATIONSHIP('Orders'[user_id], 'User Segments'[user_id])
    )
)

Basket Size by Order Number Corrected = 
VAR CurrentOrderNum = SELECTEDVALUE('Orders'[order_number])
VAR CurrentSegment = SELECTEDVALUE('User Segments'[prediction])
RETURN
IF(
    ISBLANK(CurrentOrderNum) || ISBLANK(CurrentSegment),
    BLANK(),
    DIVIDE(
        CALCULATE(
            COUNTROWS('All Order Products'),
            'Orders'[order_number] = CurrentOrderNum,
            'User Segments'[prediction] = CurrentSegment,
            USERELATIONSHIP('Orders'[user_id], 'User Segments'[user_id])
        ),
        CALCULATE(
            DISTINCTCOUNT('All Order Products'[order_id]),
            'Orders'[order_number] = CurrentOrderNum,
            'User Segments'[prediction] = CurrentSegment,
            USERELATIONSHIP('Orders'[user_id], 'User Segments'[user_id])
        ),
        0
    )
)
```

### 3.3 Product Analysis Measures

```DAX
Department Product Count Corrected = 
VAR CurrentDept = SELECTEDVALUE(Departments[department])
RETURN
IF(
    ISBLANK(CurrentDept),
    DISTINCTCOUNT(Products[product_id]),
    CALCULATE(
        DISTINCTCOUNT(Products[product_id]),
        Departments[department] = CurrentDept
    )
)

Department Orders = 
CALCULATE(
    COUNTROWS('All Order Products'),
    ALLEXCEPT(Departments, Departments[department])
)

Department Reorder Rate = 
DIVIDE(
    CALCULATE(
        COUNTROWS('All Order Products'),
        'All Order Products'[reordered] = 1,
        ALLEXCEPT(Departments, Departments[department])
    ),
    CALCULATE(
        COUNTROWS('All Order Products'),
        ALLEXCEPT(Departments, Departments[department])
    ),
    0
)

Product Popularity Fix = 
IF(
    HASONEVALUE(Products[product_id]),
    CALCULATE(
        COUNTROWS('All Order Products'),
        FILTER(
            'All Order Products',
            'All Order Products'[product_id] = SELECTEDVALUE(Products[product_id])
        )
    ),
    BLANK()
)

Product Reorder Rate Fix = 
VAR ProductID = SELECTEDVALUE(Products[product_id])
VAR TotalOrders = CALCULATE(
    COUNTROWS('All Order Products'),
    'All Order Products'[product_id] = ProductID
)
VAR ReorderedCount = CALCULATE(
    COUNTROWS('All Order Products'),
    'All Order Products'[product_id] = ProductID,
    'All Order Products'[reordered] = 1
)
RETURN
    IF(TotalOrders > 0, DIVIDE(ReorderedCount, TotalOrders), BLANK())

Avg Product Popularity = AVERAGEX(VALUES(Products[product_id]), [Product Popularity Fix])

Avg Product Reorder Rate = AVERAGEX(VALUES(Products[product_id]), [Product Reorder Rate Fix])

Product Insight = 
VAR ProductName = SELECTEDVALUE(Products[product_name])
VAR Popularity = [Product Popularity Fix]
VAR ReorderRate = [Product Reorder Rate Fix]
VAR AvgReorderRate = AVERAGE('All Order Products'[reordered])
VAR AvgPopularity = AVERAGEX(VALUES(Products[product_id]), [Product Popularity Fix])
RETURN
"Product: " & ProductName & 
UNICHAR(13) & UNICHAR(10) & 
"Orders: " & FORMAT(Popularity, "#,##0") & 
UNICHAR(13) & UNICHAR(10) & 
"Reorder Rate: " & FORMAT(ReorderRate, "0.0%") &
UNICHAR(13) & UNICHAR(10) & 
IF(ReorderRate > AvgReorderRate, "↑ Above avg reorder rate", "↓ Below avg reorder rate")

Department by Time of Day = 
VAR CurrentDept = SELECTEDVALUE(Departments[department])
VAR CurrentTime = SELECTEDVALUE(Orders[TimeOfDay])
RETURN
IF(
    ISBLANK(CurrentDept) || ISBLANK(CurrentTime),
    BLANK(),
    CALCULATE(
        COUNTROWS('All Order Products'),
        Departments[department] = CurrentDept,
        Orders[TimeOfDay] = CurrentTime
    )
)

Department by Day = 
VAR CurrentDept = SELECTEDVALUE(Departments[department])
VAR CurrentDOW = SELECTEDVALUE(Orders[order_dow])
RETURN
IF(
    ISBLANK(CurrentDept) || ISBLANK(CurrentDOW),
    BLANK(),
    CALCULATE(
        COUNTROWS('All Order Products'),
        Departments[department] = CurrentDept,
        Orders[order_dow] = CurrentDOW
    )
)
```

## 4. Visual Configurations & Troubleshooting

### 4.1 Customer Segmentation Line Chart

This visual tracks order volume by day of week for each customer segment.

**Configuration:**
- Visual Type: Line Chart
- X-axis: Orders[DayName] (sorted by Orders[order_dow])
- Y-axis: [Orders by Day and Segment Corrected]
- Legend: User Segments[SegmentName]

**Troubleshooting:**
- If all segments show identical values: Check the relationship between Orders and User Segments
- If days appear in wrong order: Ensure DayName is sorted by order_dow
- If missing data: Verify USERELATIONSHIP in the measure definition

### 4.2 Shopping Times Chart

This visual breaks down preferred shopping times by segment.

**Configuration:**
- Visual Type: Clustered Column Chart
- X-axis: Orders[TimeOfDay]
- Y-axis: [Orders by Time of Day and Segment Corrected]
- Legend: User Segments[SegmentName]

**Troubleshooting:**
- If all segments show identical values: Check filter context in the measure
- If some time periods are missing: Verify the TimeOfDay calculated column logic
- If totals are incorrect: Check USERELATIONSHIP in the measure

### 4.3 Department Metrics Matrix

**Configuration:**
- Visual Type: Matrix
- Rows: Departments[department]
- Values:
  - [Department Product Count Corrected]
  - [Department Orders]
  - [Department Reorder Rate]

**Troubleshooting:**
- If Product Count shows identical values across departments: Use the corrected measure
- If row totals don't match overall: Check for proper context transition
- If formatting breaks: Check measure format settings

### 4.4 Product Popularity vs Reorder Rate Scatter Chart

**Configuration:**
- Visual Type: Scatter Chart
- Details: Products[product_id]
- X-axis: [Product Popularity Fix]
- Y-axis: [Product Reorder Rate Fix]
- Legend: Departments[department]
- Size: [Product Popularity Fix]
- Tooltips: Custom tooltip with [Product Insight]

**Troubleshooting:**
- If chart appears blank: Check that Products[product_id] is in Details field
- If points overlap too much: Apply Top N filter for better visibility
- If departments don't show in different colors: Check department-product relationship

### 4.5 Top Products Table

**Configuration:**
- Visual Type: Table
- Columns:
  - Products[product_name]
  - Departments[department]
  - [Product Popularity Fix]
  - [Product Reorder Rate Fix]
- Sort: By [Product Popularity Fix] descending
- Top N Filter: Top 20 by [Product Popularity Fix]

**Troubleshooting:**
- If values appear incorrect: Verify product_id relationship across tables
- If sorting doesn't work: Check measure context preservation
- If product names show escape characters: Clean in Power Query

## 5. Performance Optimization

### 5.1 Optimized DAX Patterns

For all measures, optimizations applied include:
- Using variables to compute expressions once
- Using SELECTEDVALUE() instead of VALUES() where appropriate
- Explicit context preservation with KEEPFILTERS() when needed
- Pre-filtering with appropriate filter functions
- Using IF(HASONEVALUE()) pattern for better performance

### 5.2 Visual Optimization

- Applied Top N filters on data-heavy visuals
- Reduced marker size on scatter plot for performance
- Limited matrix expansion levels
- Used bookmarks for space optimization

## 6. Maintenance Guidelines

### 6.1 Troubleshooting Common Issues

1. **Identical Values Across All Categories:**
   - Check measure context preservation
   - Verify relationships are active
   - Review filter context preservation

2. **Missing Data:**
   - Verify relationships between tables
   - Check for data integrity issues
   - Review filter interactions between visuals

3. **Performance Issues:**
   - Review complex measures
   - Check for excessive CALCULATE nesting
   - Verify visual interaction settings

### 6.2 QA Checklist

- [ ] Verify all KPIs match expected values
- [ ] Confirm all segment totals match overall total
- [ ] Validate product counts across visualizations
- [ ] Check formatting consistency across pages
- [ ] Verify all filters work as expected
- [ ] Confirm navigation buttons work correctly
- [ ] Test report performance with common filter scenarios

---

