# Athena Data Warehouse Guide

## 📊 **Complete Guide to Using Athena for Data Warehouse Querying**

This guide shows you how to use AWS Athena to query your data warehouse, including setup, querying, and integration with your existing infrastructure.

---

## 🚀 **Quick Start**

### **1. Access Athena Console**
```bash
# Get Athena console URL
terraform output athena_console_url

# Or access directly
open https://console.aws.amazon.com/athena/home?region=us-east-2#workgroups
```

### **2. Basic Athena Commands**
```bash
# Get Athena information
terraform output athena_info

# Example output:
# {
#   "workgroup_name" = "dev-data-warehouse"
#   "database_name" = "dev_data_warehouse"
#   "results_bucket" = "dev-athena-results-abc123"
#   "console_url" = "https://console.aws.amazon.com/athena/home?region=us-east-2#workgroups"
# }
```

---

## 🏗️ **Athena Architecture**

### **Data Flow**
```
S3 Data Lake → Glue Crawler → Data Catalog → Athena → Query Results
     ↓              ↓              ↓           ↓         ↓
Raw/Processed   Schema Discovery  Tables    Queries   S3 Results
```

### **Components**
- **Athena Workgroup**: `dev-data-warehouse`
- **Athena Database**: `dev_data_warehouse`
- **Data Catalog**: `dev_athena_catalog`
- **Results Bucket**: `dev-athena-results-abc123`
- **Data Lake Bucket**: `dev-data-lake-abc123`

---

## 📋 **Setting Up Data for Athena**

### **1. Upload Sample Data to S3**
```bash
# Get data lake bucket name
terraform output data_lake_bucket_name

# Create sample data structure
aws s3 mb s3://$(terraform output -raw data_lake_bucket_name)/raw/sales/
aws s3 mb s3://$(terraform output -raw data_lake_bucket_name)/raw/customers/
aws s3 mb s3://$(terraform output -raw data_lake_bucket_name)/raw/products/

# Upload sample data
echo '{"order_id":"1","customer_id":"C001","product_id":"P001","amount":100.50,"order_date":"2024-01-01"}' | \
aws s3 cp - s3://$(terraform output -raw data_lake_bucket_name)/raw/sales/sales_2024-01-01.json

echo '{"customer_id":"C001","customer_name":"John Doe","email":"john@example.com","city":"New York"}' | \
aws s3 cp - s3://$(terraform output -raw data_lake_bucket_name)/raw/customers/customers.json

echo '{"product_id":"P001","product_name":"Laptop","category":"Electronics","price":999.99}' | \
aws s3 cp - s3://$(terraform output -raw data_lake_bucket_name)/raw/products/products.json
```

### **2. Create Glue Crawler to Discover Schema**
```bash
# Create crawler for sales data
aws glue create-crawler \
  --name dev-sales-crawler \
  --role $(terraform output -raw athena_role_arn) \
  --database-name $(terraform output -raw athena_database_name) \
  --targets '{"S3Targets":[{"Path":"s3://'$(terraform output -raw data_lake_bucket_name)'/raw/sales/"}]}'

# Start crawler
aws glue start-crawler --name dev-sales-crawler

# Check crawler status
aws glue get-crawler --name dev-sales-crawler
```

---

## 🔍 **Basic Athena Queries**

### **1. List Tables**
```sql
-- List all tables in the database
SHOW TABLES;

-- List tables in specific database
SHOW TABLES IN dev_data_warehouse;
```

### **2. Explore Table Structure**
```sql
-- Describe table structure
DESCRIBE sales;

-- Show table properties
SHOW TBLPROPERTIES sales;

-- Get detailed column information
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'sales'
ORDER BY ordinal_position;
```

### **3. Sample Data Queries**
```sql
-- Get sample data
SELECT * FROM sales LIMIT 10;

-- Count total records
SELECT COUNT(*) as total_records FROM sales;

-- Check data types and null values
SELECT 
  COUNT(*) as total_rows,
  COUNT(order_id) as non_null_order_ids,
  COUNT(customer_id) as non_null_customer_ids,
  COUNT(amount) as non_null_amounts
FROM sales;
```

---

## 📊 **Advanced Analytics Queries**

### **1. Sales Analysis**
```sql
-- Daily sales summary
SELECT 
  DATE_TRUNC('day', order_date) as sales_date,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
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
GROUP BY 1
ORDER BY 1;

-- Top customers by revenue
SELECT 
  customer_id,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_order_value
FROM sales
GROUP BY 1
ORDER BY 3 DESC
LIMIT 10;
```

### **2. Customer Analysis**
```sql
-- Customer lifetime value
SELECT 
  customer_id,
  COUNT(*) as total_orders,
  SUM(amount) as lifetime_value,
  AVG(amount) as avg_order_value,
  MIN(order_date) as first_order_date,
  MAX(order_date) as last_order_date
FROM sales
GROUP BY 1
ORDER BY 3 DESC;

-- Customer segmentation
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
```

### **3. Product Analysis**
```sql
-- Top selling products
SELECT 
  product_id,
  COUNT(*) as units_sold,
  SUM(amount) as total_revenue,
  AVG(amount) as avg_price
FROM sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;

-- Product performance by category
SELECT 
  p.category,
  COUNT(*) as total_orders,
  SUM(s.amount) as total_revenue,
  AVG(s.amount) as avg_order_value
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 3 DESC;
```

---

## 🔧 **Using Athena with AWS CLI**

### **1. Run Queries via CLI**
```bash
# Get workgroup name
WORKGROUP=$(terraform output -raw athena_workgroup_name)

# Run a simple query
aws athena start-query-execution \
  --work-group $WORKGROUP \
  --query-string "SHOW TABLES;"

# Run a complex query
aws athena start-query-execution \
  --work-group $WORKGROUP \
  --query-string "SELECT COUNT(*) FROM sales;"
```

### **2. Get Query Results**
```bash
# Get query execution ID from previous command
QUERY_ID="your-query-execution-id"

# Check query status
aws athena get-query-execution --query-execution-id $QUERY_ID

# Get query results
aws athena get-query-results --query-execution-id $QUERY_ID
```

### **3. List Query History**
```bash
# List recent queries
aws athena list-query-executions --work-group $WORKGROUP

# Get specific query details
aws athena get-query-execution --query-execution-id $QUERY_ID
```

---

## 🐍 **Using Athena with Python (boto3)**

### **1. Basic Athena Client**
```python
import boto3
import time
import pandas as pd

# Initialize Athena client
athena_client = boto3.client('athena')
s3_client = boto3.client('s3')

# Configuration
WORKGROUP = 'dev-data-warehouse'
DATABASE = 'dev_data_warehouse'
RESULTS_BUCKET = 'dev-athena-results-abc123'

def run_athena_query(query):
    """Run an Athena query and return results"""
    
    # Start query execution
    response = athena_client.start_query_execution(
        QueryString=query,
        WorkGroup=WORKGROUP,
        ResultConfiguration={
            'OutputLocation': f's3://{RESULTS_BUCKET}/results/'
        }
    )
    
    query_execution_id = response['QueryExecutionId']
    
    # Wait for query to complete
    while True:
        response = athena_client.get_query_execution(
            QueryExecutionId=query_execution_id
        )
        status = response['QueryExecution']['Status']['State']
        
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
            
        time.sleep(1)
    
    if status == 'SUCCEEDED':
        # Get results
        results = athena_client.get_query_results(
            QueryExecutionId=query_execution_id
        )
        return results
    else:
        raise Exception(f"Query failed: {response['QueryExecution']['Status']}")

# Example usage
query = "SELECT COUNT(*) as total_records FROM sales;"
results = run_athena_query(query)
print(results)
```

### **2. Advanced Athena Operations**
```python
def get_query_results_as_dataframe(query):
    """Run query and return results as pandas DataFrame"""
    
    # Run query
    response = athena_client.start_query_execution(
        QueryString=query,
        WorkGroup=WORKGROUP,
        ResultConfiguration={
            'OutputLocation': f's3://{RESULTS_BUCKET}/results/'
        }
    )
    
    query_execution_id = response['QueryExecutionId']
    
    # Wait for completion
    while True:
        response = athena_client.get_query_execution(
            QueryExecutionId=query_execution_id
        )
        status = response['QueryExecution']['Status']['State']
        
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
            
        time.sleep(1)
    
    if status == 'SUCCEEDED':
        # Get results
        results = athena_client.get_query_results(
            QueryExecutionId=query_execution_id
        )
        
        # Convert to DataFrame
        columns = [col['Name'] for col in results['ResultSet']['ResultSetMetadata']['ColumnInfo']]
        rows = []
        
        for row in results['ResultSet']['Rows'][1:]:  # Skip header
            rows.append([field['VarCharValue'] for field in row['Data']])
        
        return pd.DataFrame(rows, columns=columns)
    else:
        raise Exception(f"Query failed: {response['QueryExecution']['Status']}")

# Example usage
df = get_query_results_as_dataframe("SELECT * FROM sales LIMIT 100;")
print(df.head())
```

---

## 🔄 **Integration with Other Services**

### **1. Lambda Function for Athena Queries**
```python
# lambda_function.py
import json
import boto3

def handler(event, context):
    """Lambda function to run Athena queries"""
    
    athena_client = boto3.client('athena')
    
    # Get query from event
    query = event.get('query', 'SHOW TABLES;')
    
    try:
        # Run query
        response = athena_client.start_query_execution(
            QueryString=query,
            WorkGroup='dev-data-warehouse',
            ResultConfiguration={
                'OutputLocation': 's3://dev-athena-results-abc123/results/'
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Query started successfully',
                'queryExecutionId': response['QueryExecutionId']
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
```

### **2. ECS Task for Batch Queries**
```python
# batch_query_processor.py
import boto3
import time
import json

def process_batch_queries():
    """Process batch queries using ECS"""
    
    athena_client = boto3.client('athena')
    
    # List of queries to run
    queries = [
        "SELECT COUNT(*) FROM sales;",
        "SELECT customer_id, SUM(amount) FROM sales GROUP BY 1;",
        "SELECT product_id, COUNT(*) FROM sales GROUP BY 1;"
    ]
    
    results = []
    
    for query in queries:
        try:
            # Run query
            response = athena_client.start_query_execution(
                QueryString=query,
                WorkGroup='dev-data-warehouse',
                ResultConfiguration={
                    'OutputLocation': 's3://dev-athena-results-abc123/batch-results/'
                }
            )
            
            query_id = response['QueryExecutionId']
            
            # Wait for completion
            while True:
                response = athena_client.get_query_execution(
                    QueryExecutionId=query_id
                )
                status = response['QueryExecution']['Status']['State']
                
                if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                    break
                    
                time.sleep(5)
            
            results.append({
                'query': query,
                'queryId': query_id,
                'status': status
            })
            
        except Exception as e:
            results.append({
                'query': query,
                'error': str(e)
            })
    
    return results

if __name__ == "__main__":
    results = process_batch_queries()
    print(json.dumps(results, indent=2))
```

---

## 📈 **Performance Optimization**

### **1. Query Optimization Tips**
```sql
-- Use columnar formats (Parquet)
CREATE TABLE sales_parquet
WITH (
  format = 'PARQUET',
  external_location = 's3://dev-data-lake-abc123/processed/sales/'
) AS
SELECT * FROM sales;

-- Use partitioning
CREATE TABLE sales_partitioned
WITH (
  format = 'PARQUET',
  partitioned_by = ARRAY['year', 'month'],
  external_location = 's3://dev-data-lake-abc123/processed/sales_partitioned/'
) AS
SELECT 
  *,
  EXTRACT(YEAR FROM order_date) as year,
  EXTRACT(MONTH FROM order_date) as month
FROM sales;

-- Use appropriate data types
CREATE TABLE sales_optimized
WITH (
  format = 'PARQUET',
  external_location = 's3://dev-data-lake-abc123/processed/sales_optimized/'
) AS
SELECT 
  CAST(order_id AS VARCHAR) as order_id,
  CAST(customer_id AS VARCHAR) as customer_id,
  CAST(product_id AS VARCHAR) as product_id,
  CAST(amount AS DECIMAL(10,2)) as amount,
  CAST(order_date AS DATE) as order_date
FROM sales;
```

### **2. Cost Optimization**
```sql
-- Use LIMIT for exploration
SELECT * FROM sales LIMIT 100;

-- Use specific columns instead of SELECT *
SELECT customer_id, amount, order_date FROM sales;

-- Use WHERE clauses to limit data scanned
SELECT * FROM sales 
WHERE order_date >= DATE('2024-01-01')
  AND order_date < DATE('2024-02-01');

-- Use approximate functions for large datasets
SELECT APPROX_COUNT_DISTINCT(customer_id) as unique_customers
FROM sales;
```

---

## 🔍 **Monitoring and Debugging**

### **1. CloudWatch Metrics**
```bash
# View Athena metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Athena \
  --metric-name DataScannedInBytes \
  --dimensions Name=WorkGroup,Value=dev-data-warehouse \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### **2. Query Performance Analysis**
```sql
-- Check query execution history
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
```

### **3. Common Issues and Solutions**

#### **Permission Denied**
```bash
# Check IAM role permissions
aws iam get-role --role-name dev-athena-role

# Check S3 bucket permissions
aws s3api get-bucket-policy --bucket dev-athena-results-abc123
```

#### **Query Fails**
```bash
# Check workgroup configuration
aws athena get-work-group --work-group dev-data-warehouse

# Check database exists
aws athena get-database --catalog-name AwsDataCatalog --database-name dev_data_warehouse
```

#### **High Costs**
```bash
# Check query execution history
aws athena list-query-executions --work-group dev-data-warehouse

# Get query execution details
aws athena get-query-execution --query-execution-id your-query-id
```

---

## 🚀 **Best Practices**

### **1. Query Best Practices**
- **Use columnar formats** (Parquet, ORC) for better compression
- **Partition large tables** by date, region, etc.
- **Use appropriate data types** for better performance
- **Limit data scanned** with WHERE clauses and LIMIT
- **Use approximate functions** for large datasets

### **2. Cost Management**
- **Set bytes scanned limits** in workgroup configuration
- **Use result caching** to avoid re-running queries
- **Clean up query results** with S3 lifecycle policies
- **Monitor usage** with CloudWatch metrics

### **3. Security**
- **Encrypt data** with S3 encryption
- **Use least privilege** IAM permissions
- **Enable audit logging** with CloudTrail
- **Use VPC endpoints** for private access

---

## 🔗 **Integration with Your Infrastructure**

### **1. With S3 Data Lake**
```hcl
# Lambda function triggered by S3 uploads
resource "aws_lambda_function" "s3_processor" {
  # ... configuration
  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.data_lake.bucket
      ATHENA_DATABASE = module.athena.database_name
    }
  }
}
```

### **2. With ECS Tasks**
```hcl
# ECS task to run Athena queries
resource "aws_ecs_task_definition" "athena_query_task" {
  # ... configuration
  container_definitions = jsonencode([{
    environment = [
      {
        name  = "ATHENA_WORKGROUP"
        value = module.athena.workgroup_name
      }
    ]
  }])
}
```

### **3. With Monitoring**
```hcl
# CloudWatch alarms for Athena
resource "aws_cloudwatch_metric_alarm" "athena_high_cost" {
  alarm_name          = "athena-high-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DataScannedInBytes"
  namespace           = "AWS/Athena"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000000000"  # 1GB
  alarm_description   = "Athena query scanned more than 1GB"
}
```

---

## 📚 **Useful Commands**

### **Terraform Commands**
```bash
# Get Athena information
terraform output athena_info

# Get specific outputs
terraform output athena_workgroup_name
terraform output athena_database_name
terraform output athena_results_bucket

# Apply Athena module
terraform apply -target=module.athena
```

### **AWS CLI Commands**
```bash
# List workgroups
aws athena list-work-groups

# List databases
aws athena list-databases --catalog-name AwsDataCatalog

# List tables
aws athena list-table-metadata --catalog-name AwsDataCatalog --database-name dev_data_warehouse
```

---

**Your Athena data warehouse is now ready for advanced analytics!** 🎉

**Key Benefits:**
- ✅ **Serverless Querying** - No infrastructure management
- ✅ **Cost Effective** - Pay only for data scanned
- ✅ **Scalable** - Handle any data size
- ✅ **Integrated** - Works with S3, Glue, and other AWS services
- ✅ **SQL Compatible** - Use familiar SQL syntax

**Start querying your data lake today!** 🚀
