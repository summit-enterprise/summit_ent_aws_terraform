-- ========================================
-- ATHENA QUERY EXAMPLES
-- ========================================
-- This file contains example queries for your Athena data warehouse
-- Replace 'your_database' with your actual database name
-- Replace 'your_table' with your actual table names

-- ========================================
-- 1. BASIC EXPLORATION QUERIES
-- ========================================

-- List all databases
SHOW DATABASES;

-- List all tables in current database
SHOW TABLES;

-- List all tables in specific database
SHOW TABLES IN your_database;

-- Describe table structure
DESCRIBE your_table;

-- Show table properties
SHOW TBLPROPERTIES your_table;

-- Show partitions (if table is partitioned)
SHOW PARTITIONS your_table;

-- ========================================
-- 2. DATA EXPLORATION QUERIES
-- ========================================

-- Get table row count
SELECT COUNT(*) as total_rows FROM your_table;

-- Get sample data (first 10 rows)
SELECT * FROM your_table LIMIT 10;

-- Get column information
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'your_table'
ORDER BY ordinal_position;

-- Check data types and null values
SELECT 
  column_name,
  data_type,
  COUNT(*) as total_rows,
  COUNT(column_name) as non_null_rows,
  COUNT(*) - COUNT(column_name) as null_rows
FROM information_schema.columns
WHERE table_name = 'your_table'
GROUP BY column_name, data_type;

-- ========================================
-- 3. SALES ANALYSIS QUERIES
-- ========================================

-- Daily sales summary
SELECT 
  DATE_TRUNC('day', order_date) as sales_date,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value,
  MIN(amount) as min_order,
  MAX(amount) as max_order
FROM sales
WHERE order_date >= DATE('2024-01-01')
GROUP BY 1
ORDER BY 1;

-- Monthly sales trend
SELECT 
  DATE_TRUNC('month', order_date) as sales_month,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM sales
WHERE order_date >= DATE('2024-01-01')
GROUP BY 1
ORDER BY 1;

-- Top 10 customers by revenue
SELECT 
  customer_id,
  customer_name,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM sales
GROUP BY 1, 2
ORDER BY 4 DESC
LIMIT 10;

-- Sales by product category
SELECT 
  product_category,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM sales
GROUP BY 1
ORDER BY 3 DESC;

-- ========================================
-- 4. CUSTOMER ANALYSIS QUERIES
-- ========================================

-- Customer lifetime value
SELECT 
  customer_id,
  customer_name,
  COUNT(*) as total_orders,
  SUM(amount) as lifetime_value,
  AVG(amount) as avg_order_value,
  MIN(order_date) as first_order_date,
  MAX(order_date) as last_order_date,
  DATE_DIFF('day', MIN(order_date), MAX(order_date)) as customer_lifespan_days
FROM sales
GROUP BY 1, 2
ORDER BY 4 DESC;

-- Customer segmentation by order frequency
SELECT 
  customer_id,
  COUNT(*) as order_count,
  CASE 
    WHEN COUNT(*) >= 10 THEN 'High Frequency'
    WHEN COUNT(*) >= 5 THEN 'Medium Frequency'
    ELSE 'Low Frequency'
  END as customer_segment
FROM sales
GROUP BY 1
ORDER BY 2 DESC;

-- New vs returning customers
SELECT 
  DATE_TRUNC('month', order_date) as month,
  COUNT(DISTINCT customer_id) as total_customers,
  COUNT(DISTINCT CASE 
    WHEN order_date = first_order_date THEN customer_id 
  END) as new_customers,
  COUNT(DISTINCT CASE 
    WHEN order_date > first_order_date THEN customer_id 
  END) as returning_customers
FROM (
  SELECT 
    customer_id,
    order_date,
    MIN(order_date) OVER (PARTITION BY customer_id) as first_order_date
  FROM sales
)
GROUP BY 1
ORDER BY 1;

-- ========================================
-- 5. PRODUCT ANALYSIS QUERIES
-- ========================================

-- Top selling products
SELECT 
  product_id,
  product_name,
  COUNT(*) as units_sold,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_price
FROM sales
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 20;

-- Product performance by category
SELECT 
  product_category,
  COUNT(DISTINCT product_id) as unique_products,
  COUNT(*) as total_orders,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM sales
GROUP BY 1
ORDER BY 4 DESC;

-- Seasonal product analysis
SELECT 
  product_category,
  EXTRACT(MONTH FROM order_date) as month,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue
FROM sales
GROUP BY 1, 2
ORDER BY 1, 2;

-- ========================================
-- 6. TIME-BASED ANALYSIS QUERIES
-- ========================================

-- Hourly sales pattern
SELECT 
  EXTRACT(HOUR FROM order_date) as hour,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue
FROM sales
GROUP BY 1
ORDER BY 1;

-- Day of week analysis
SELECT 
  CASE EXTRACT(DOW FROM order_date)
    WHEN 0 THEN 'Sunday'
    WHEN 1 THEN 'Monday'
    WHEN 2 THEN 'Tuesday'
    WHEN 3 THEN 'Wednesday'
    WHEN 4 THEN 'Thursday'
    WHEN 5 THEN 'Friday'
    WHEN 6 THEN 'Saturday'
  END as day_of_week,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM sales
GROUP BY 1
ORDER BY 2 DESC;

-- Year-over-year growth
SELECT 
  EXTRACT(YEAR FROM order_date) as year,
  EXTRACT(MONTH FROM order_date) as month,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  LAG(SUM(amount)) OVER (ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) as prev_month_revenue,
  ROUND(
    (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date))) / 
    LAG(SUM(amount)) OVER (ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) * 100, 2
  ) as month_over_month_growth_pct
FROM sales
GROUP BY 1, 2
ORDER BY 1, 2;

-- ========================================
-- 7. ADVANCED ANALYTICS QUERIES
-- ========================================

-- Moving averages
SELECT 
  order_date,
  SUM(amount) as daily_revenue,
  AVG(SUM(amount)) OVER (
    ORDER BY order_date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) as seven_day_avg
FROM sales
GROUP BY 1
ORDER BY 1;

-- Customer cohort analysis
WITH customer_cohorts AS (
  SELECT 
    customer_id,
    DATE_TRUNC('month', MIN(order_date)) as cohort_month
  FROM sales
  GROUP BY 1
),
monthly_orders AS (
  SELECT 
    customer_id,
    DATE_TRUNC('month', order_date) as order_month,
    COUNT(*) as order_count
  FROM sales
  GROUP BY 1, 2
)
SELECT 
  c.cohort_month,
  m.order_month,
  COUNT(DISTINCT c.customer_id) as customers,
  SUM(m.order_count) as total_orders
FROM customer_cohorts c
JOIN monthly_orders m ON c.customer_id = m.customer_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- Revenue attribution by channel
SELECT 
  channel,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value,
  ROUND(SUM(amount) / SUM(SUM(amount)) OVER () * 100, 2) as revenue_share_pct
FROM sales
GROUP BY 1
ORDER BY 3 DESC;

-- ========================================
-- 8. DATA QUALITY QUERIES
-- ========================================

-- Check for duplicate orders
SELECT 
  order_id,
  COUNT(*) as duplicate_count
FROM sales
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY 2 DESC;

-- Check for missing values
SELECT 
  'customer_id' as column_name,
  COUNT(*) as total_rows,
  COUNT(customer_id) as non_null_rows,
  COUNT(*) - COUNT(customer_id) as null_rows
FROM sales
UNION ALL
SELECT 
  'order_date' as column_name,
  COUNT(*) as total_rows,
  COUNT(order_date) as non_null_rows,
  COUNT(*) - COUNT(order_date) as null_rows
FROM sales
UNION ALL
SELECT 
  'amount' as column_name,
  COUNT(*) as total_rows,
  COUNT(amount) as non_null_rows,
  COUNT(*) - COUNT(amount) as null_rows
FROM sales;

-- Check for data anomalies
SELECT 
  'Negative amounts' as check_type,
  COUNT(*) as count
FROM sales
WHERE amount < 0
UNION ALL
SELECT 
  'Future dates' as check_type,
  COUNT(*) as count
FROM sales
WHERE order_date > CURRENT_DATE
UNION ALL
SELECT 
  'Zero amounts' as check_type,
  COUNT(*) as count
FROM sales
WHERE amount = 0;

-- ========================================
-- 9. PERFORMANCE OPTIMIZATION QUERIES
-- ========================================

-- Check table statistics
SELECT 
  table_name,
  table_type,
  table_rows,
  data_length,
  index_length
FROM information_schema.tables
WHERE table_schema = 'your_database';

-- Analyze query performance
SELECT 
  query_execution_id,
  query,
  execution_time,
  data_scanned_in_bytes,
  ROUND(data_scanned_in_bytes / 1024 / 1024, 2) as data_scanned_mb
FROM cloudtrail_logs
WHERE event_name = 'StartQueryExecution'
ORDER BY execution_time DESC
LIMIT 10;

-- ========================================
-- 10. BUSINESS INTELLIGENCE QUERIES
-- ========================================

-- Executive dashboard summary
SELECT 
  'Total Revenue' as metric,
  CAST(SUM(amount) as VARCHAR) as value
FROM sales
WHERE order_date >= DATE('2024-01-01')
UNION ALL
SELECT 
  'Total Orders' as metric,
  CAST(COUNT(*) as VARCHAR) as value
FROM sales
WHERE order_date >= DATE('2024-01-01')
UNION ALL
SELECT 
  'Average Order Value' as metric,
  CAST(ROUND(AVG(amount), 2) as VARCHAR) as value
FROM sales
WHERE order_date >= DATE('2024-01-01')
UNION ALL
SELECT 
  'Unique Customers' as metric,
  CAST(COUNT(DISTINCT customer_id) as VARCHAR) as value
FROM sales
WHERE order_date >= DATE('2024-01-01');

-- KPI trends
SELECT 
  DATE_TRUNC('week', order_date) as week,
  COUNT(*) as orders,
  SUM(amount) as revenue,
  COUNT(DISTINCT customer_id) as unique_customers,
  ROUND(SUM(amount) / COUNT(DISTINCT customer_id), 2) as revenue_per_customer
FROM sales
WHERE order_date >= DATE('2024-01-01')
GROUP BY 1
ORDER BY 1;

-- ========================================
-- 11. EXPORT QUERIES
-- ========================================

-- Export data for external analysis
SELECT 
  order_id,
  customer_id,
  customer_name,
  product_id,
  product_name,
  product_category,
  order_date,
  amount,
  channel
FROM sales
WHERE order_date >= DATE('2024-01-01')
ORDER BY order_date DESC;

-- Export customer data
SELECT 
  customer_id,
  customer_name,
  COUNT(*) as total_orders,
  SUM(amount) as lifetime_value,
  MIN(order_date) as first_order,
  MAX(order_date) as last_order
FROM sales
GROUP BY 1, 2
ORDER BY 4 DESC;

-- ========================================
-- 12. MAINTENANCE QUERIES
-- ========================================

-- Check table size and partitions
SELECT 
  table_name,
  table_rows,
  ROUND(data_length / 1024 / 1024, 2) as size_mb
FROM information_schema.tables
WHERE table_schema = 'your_database'
ORDER BY 3 DESC;

-- Check recent query history
SELECT 
  query_execution_id,
  query,
  execution_time,
  data_scanned_in_bytes,
  status
FROM cloudtrail_logs
WHERE event_name = 'StartQueryExecution'
  AND event_time >= CURRENT_TIMESTAMP - INTERVAL '1' DAY
ORDER BY event_time DESC
LIMIT 20;

-- ========================================
-- NOTES
-- ========================================
-- 1. Replace 'your_database' with your actual database name
-- 2. Replace 'your_table' with your actual table names
-- 3. Adjust date ranges as needed
-- 4. Modify column names to match your schema
-- 5. Test queries with LIMIT clause first
-- 6. Use EXPLAIN to analyze query performance
-- 7. Consider partitioning large tables by date
-- 8. Use appropriate data types for better performance
