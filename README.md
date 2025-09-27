# AWS Data Engineering Infrastructure

This Terraform configuration creates a complete data engineering stack on AWS with VPC, ECR, S3 Data Lake, AWS Glue, and ECS with Fargate Spot.

## 📁 File Structure

```
terraform/
├── main.tf                 # Provider & backend configuration
├── variables.tf            # All variables
├── outputs.tf             # All outputs
├── vpc.tf                 # VPC, subnets, gateways, route tables
├── security-groups.tf     # All security groups
├── ecr.tf                 # ECR repositories for Docker images
├── s3.tf                  # S3 buckets & data lake structure
├── iam.tf                 # IAM roles & policies
├── glue.tf                # AWS Glue resources (catalog, crawlers, jobs)
├── ecs.tf                 # ECS cluster & tasks with Fargate Spot
└── examples/              # Example EC2 instances (disabled by default)
    └── ec2.tf
```

## 🏗️ Infrastructure Components

### **Core Infrastructure:**
- **VPC** with public/private subnets across 2 AZs
- **Security Groups** for web, database, app, and bastion hosts
- **Internet Gateway** and route tables

### **Data Engineering Stack:**
- **ECR Repositories** (3) for Docker images
- **S3 Data Lake** with 4 zones (raw, processed, analytics, curated)
- **AWS Glue** catalog, crawlers, and ETL jobs
- **ECS Cluster** with Fargate Spot for cost optimization

### **Security & Access:**
- **IAM Roles** for Glue and ECS services
- **S3 encryption** and public access blocking
- **VPC security** with proper subnet isolation

## 🚀 Getting Started

### **1. Prerequisites:**
- AWS CLI configured
- Terraform installed
- Terraform Cloud account

### **2. Deploy Infrastructure:**
```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### **3. Verify Deployment:**
```bash
# Check outputs
terraform output

# List ECR repositories
aws ecr describe-repositories

# List S3 buckets
aws s3 ls
```

## 💰 Cost Optimization

- **Fargate Spot** - 70% cheaper than regular Fargate
- **No scheduled jobs** - Glue crawlers and jobs are ON_DEMAND only
- **Empty resources** - ECR, S3, ECS start with zero usage
- **CloudWatch logs** - 14-day retention only

## 🔧 Usage Examples

### **Push Docker Images:**
```bash
# Login to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-2.amazonaws.com

# Build and push
docker build -t spark-app .
docker tag spark-app:latest <account>.dkr.ecr.us-east-2.amazonaws.com/dev-spark-applications:latest
docker push <account>.dkr.ecr.us-east-2.amazonaws.com/dev-spark-applications:latest
```

### **Run ECS Tasks:**
```bash
# Run data processing task
aws ecs run-task \
  --cluster dev-data-processing-cluster \
  --task-definition dev-data-processing-task \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

### **Upload Data:**
```bash
# Upload sample data
aws s3 cp sample-data.csv s3://dev-data-lake-<random>/raw/
```

## 🎯 Data Flow

```
Raw Data → S3 Raw Zone → Glue Crawler → Data Catalog
    ↓
Glue ETL Job → S3 Processed Zone → Analytics Zone
    ↓
ECS Fargate Spot → Custom Processing → S3 Curated Zone
```

## 📊 Monitoring

- **CloudWatch Logs** for ECS and Glue
- **S3 metrics** for storage usage
- **ECS metrics** for task performance

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy

# Or destroy specific components
terraform destroy -target=aws_ecs_cluster.data_processing
```

## 🔒 Security Notes

- All S3 buckets have encryption enabled
- Public access is blocked on all buckets
- Security groups follow least privilege principle
- IAM roles have minimal required permissions

## 📝 Variables

Key variables in `variables.tf`:
- `environment` - Environment name (default: "dev")
- `aws_region` - AWS region (default: "us-east-2")
- `vpc_cidr` - VPC CIDR block (default: "10.0.0.0/16")
- `availability_zones` - List of AZs to use
- `public_subnet_cidrs` - CIDR blocks for public subnets
- `private_subnet_cidrs` - CIDR blocks for private subnets