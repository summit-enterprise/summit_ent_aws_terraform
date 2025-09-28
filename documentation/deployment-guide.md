# AWS Infrastructure Deployment Guide

## 🚀 **Complete Deployment Walkthrough**

This guide provides step-by-step instructions for deploying your AWS infrastructure using Terraform, now organized in a modular DevOps structure.

---

## 🏗️ **Deployment Options**

### **Option 1: Modular Structure (Recommended)**
- **Path**: `terraform/environments/dev/`
- **Benefits**: Modular, scalable, enterprise-ready
- **Use Case**: Production deployments, team collaboration

### **Option 2: Legacy Structure**
- **Path**: Root directory
- **Benefits**: Simple, single-file approach
- **Use Case**: Quick testing, learning

---

## 📋 **Prerequisites**

### **1. Required Tools**
- **Terraform**: Version >= 1.0
- **AWS CLI**: Latest version
- **Git**: For version control
- **jq**: For JSON processing (optional but recommended)

### **2. AWS Account Setup**
- **AWS Account**: Active AWS account
- **IAM User**: With appropriate permissions
- **Access Keys**: AWS Access Key ID and Secret Access Key
- **Region**: us-east-2 (or your preferred region)

### **3. Terraform Cloud Setup**
- **Terraform Cloud Account**: Free tier available
- **Organization**: summit-enterprise
- **Workspace**: summit_ent_aws_terraform
- **VCS Connection**: GitHub integration

---

## 🔧 **Environment Setup**

### **Step 1: Clone Repository**
```bash
# Clone the repository
git clone <your-repository-url>
cd aws-summit-terraform

# Verify files
ls -la
```

### **Step 2A: Modular Structure Deployment**
```bash
# Navigate to dev environment
cd terraform/environments/dev

# Verify modular structure
ls -la
```

### **Step 2B: Legacy Structure Deployment**
```bash
# Set up environment variables
./setup-env.sh

# Edit your environment file
nano .env

# Load environment variables
source load-env.sh
```

---

## 🚀 **Modular Structure Deployment**

### **Step 1: Navigate to Dev Environment**
```bash
# Navigate to dev environment
cd terraform/environments/dev

# Verify modular structure
ls -la
```

### **Step 2: Initialize Terraform**
```bash
# Initialize Terraform
terraform init
```

### **Step 3: Plan Deployment**
```bash
# Review the plan
terraform plan

# Save plan to file (optional)
terraform plan -out=tfplan
```

### **Step 4: Apply Configuration**
```bash
# Apply the configuration
terraform apply

# Or apply from saved plan
terraform apply tfplan
```

### **Step 5: Verify Deployment**
```bash
# Check outputs
terraform output

# Verify resources
terraform show
```

---

## 🚀 **Legacy Structure Deployment**

### **Step 3: Configure AWS Credentials**
```bash
# Option 1: AWS CLI configuration
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-2"

# Option 3: IAM Role (recommended for EC2)
# No additional configuration needed
```

### **Step 4: Verify AWS Access**
```bash
# Test AWS access
aws sts get-caller-identity

# Test region access
aws ec2 describe-regions --region us-east-2
```

---

## 🏗️ **Terraform Deployment**

### **Step 1: Initialize Terraform**
```bash
# Initialize Terraform
terraform init

# Verify initialization
terraform version
```

**Expected Output:**
```
Terraform v1.6.0
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v5.0.0
+ provider registry.terraform.io/hashicorp/random v3.6.0
```

### **Step 2: Validate Configuration**
```bash
# Validate Terraform configuration
terraform validate

# Check for any syntax errors
terraform fmt -check
```

**Expected Output:**
```
Success! The configuration is valid.
```

### **Step 3: Plan Deployment**
```bash
# Create execution plan
terraform plan

# Save plan to file (optional)
terraform plan -out=tfplan
```

**Expected Output:**
```
Plan: 45 to add, 0 to change, 0 to destroy.
```

### **Step 4: Deploy Infrastructure**
```bash
# Apply the configuration
terraform apply

# Or apply from saved plan
terraform apply tfplan
```

**Expected Output:**
```
Apply complete! Resources: 45 added, 0 changed, 0 destroyed.
```

---

## 🔍 **Post-Deployment Verification**

### **Step 1: Check Resource Creation**
```bash
# List all resources
terraform show

# Get specific outputs
terraform output

# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=dev-main-vpc"

# Check S3 buckets
aws s3 ls

# Check ECR repositories
aws ecr describe-repositories
```

### **Step 2: Verify Security Groups**
```bash
# List security groups
aws ec2 describe-security-groups --filters "Name=tag:Environment,Values=dev"

# Check specific security group
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

### **Step 3: Test Network Connectivity**
```bash
# Get instance IPs
terraform output kubernetes_public_ip
terraform output monitoring_public_ip

# Test SSH access (if key pair is configured)
ssh -i ~/.ssh/oci_ed25519 ec2-user@<kubernetes-ip>

# Test web access
curl http://<monitoring-ip>:9090  # Prometheus
curl http://<monitoring-ip>:3000  # Grafana
```

---

## 🎯 **Service-Specific Deployment**

### **1. Enable Databases (Optional)**
```bash
# Edit examples/ec2.tf
nano examples/ec2.tf

# Change count from 0 to 1 for desired resources
# RDS MySQL
resource "aws_db_instance" "mysql" {
  count = 1  # Changed from 0 to 1
  # ... rest of configuration
}

# ElastiCache Redis
resource "aws_elasticache_replication_group" "redis" {
  count = 1  # Changed from 0 to 1
  # ... rest of configuration
}

# Apply changes
terraform plan
terraform apply
```

### **2. Scale ECS Services**
```bash
# Edit ecs.tf
nano ecs.tf

# Change desired count
resource "aws_ecs_service" "data_processing_service" {
  desired_count = 2  # Changed from 0 to 2
  # ... rest of configuration
}

# Apply changes
terraform plan
terraform apply
```

### **3. Enable Elastic IPs**
```bash
# Edit kubernetes.tf and monitoring.tf
nano kubernetes.tf
nano monitoring.tf

# Change count from 0 to 1
resource "aws_eip" "kubernetes" {
  count = 1  # Changed from 0 to 1
  # ... rest of configuration
}

# Apply changes
terraform plan
terraform apply
```

---

## 🔐 **Secrets Management**

### **Step 1: Retrieve Secrets**
```bash
# Get secret ARNs
terraform output secrets_manager_arns

# Retrieve specific secrets
aws secretsmanager get-secret-value \
  --secret-id dev-mysql-credentials \
  --query SecretString --output text | jq .

# Get all secrets
terraform output secrets_retrieval_commands
```

### **Step 2: Use Secrets in Applications**
```bash
# Example: Use MySQL credentials
MYSQL_CREDS=$(aws secretsmanager get-secret-value \
  --secret-id dev-mysql-credentials \
  --query SecretString --output text)

echo $MYSQL_CREDS | jq -r '.password'
echo $MYSQL_CREDS | jq -r '.host'
```

---

## 📊 **Monitoring Setup**

### **Step 1: Access Monitoring Services**
```bash
# Get monitoring URLs
terraform output monitoring_urls

# Access Prometheus
open http://<monitoring-ip>:9090

# Access Grafana
open http://<monitoring-ip>:3000
# Username: admin
# Password: <generated-password>

# Access Kibana
open http://<monitoring-ip>:5601

# Access Jaeger
open http://<monitoring-ip>:16686
```

### **Step 2: Configure Grafana**
```bash
# Get Grafana credentials
aws secretsmanager get-secret-value \
  --secret-id dev-grafana-credentials \
  --query SecretString --output text | jq .

# Login to Grafana
# 1. Go to http://<monitoring-ip>:3000
# 2. Username: admin
# 3. Password: <from-secrets-manager>
# 4. Add Prometheus as data source
# 5. Import dashboards
```

### **Step 3: Set Up Alerts**
```bash
# SSH to monitoring instance
ssh ec2-user@<monitoring-ip>

# Check Prometheus configuration
cat /home/ec2-user/monitoring/prometheus.yml

# Check Grafana configuration
docker exec -it grafana grafana-cli admin reset-admin-password <new-password>
```

---

## ☸️ **Kubernetes Setup**

### **Step 1: Access Kubernetes Cluster**
```bash
# Get Kubernetes access information
terraform output kubernetes_ssh_command
terraform output kubernetes_argocd_url

# SSH to Kubernetes instance
ssh -i ~/.ssh/oci_ed25519 ec2-user@<kubernetes-ip>

# Check Minikube status
minikube status

# Get cluster info
kubectl cluster-info
```

### **Step 2: Access ArgoCD**
```bash
# Get ArgoCD credentials
aws secretsmanager get-secret-value \
  --secret-id dev-argocd-credentials \
  --query SecretString --output text | jq .

# Access ArgoCD web UI
open http://<kubernetes-ip>:30080

# Login with credentials from secrets manager
```

### **Step 3: Deploy Applications with ArgoCD**
```bash
# SSH to Kubernetes instance
ssh -i ~/.ssh/oci_ed25519 ec2-user@<kubernetes-ip>

# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD CLI
argocd login localhost:8080 --username admin --password <password>

# Create application
argocd app create my-app \
  --repo https://github.com/your-org/your-repo \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

---

## 🗄️ **Data Lake Setup**

### **Step 1: Upload Sample Data**
```bash
# Get S3 bucket name
terraform output data_lake_bucket_name

# Create sample data structure
aws s3 mb s3://<bucket-name>/raw/logs/
aws s3 mb s3://<bucket-name>/raw/events/
aws s3 mb s3://<bucket-name>/processed/daily/
aws s3 mb s3://<bucket-name>/curated/analytics/

# Upload sample data
echo '{"timestamp":"2024-01-01T00:00:00Z","user_id":"123","action":"login"}' | \
aws s3 cp - s3://<bucket-name>/raw/events/sample.json
```

### **Step 2: Run Glue Crawlers**
```bash
# Get Glue job names
terraform output glue_job_names

# Start crawlers
aws glue start-crawler --name dev-raw-data-crawler
aws glue start-crawler --name dev-processed-data-crawler

# Check crawler status
aws glue get-crawler --name dev-raw-data-crawler
```

### **Step 3: Run ETL Jobs**
```bash
# Start ETL workflow
aws glue start-workflow-run --name dev-etl-workflow

# Check job status
aws glue get-job-runs --job-name dev-data-processing-job
```

---

## 🐳 **Container Registry Setup**

### **Step 1: Configure ECR Access**
```bash
# Get ECR repository URLs
terraform output ecr_repository_urls

# Login to ECR
aws ecr get-login-password --region us-east-2 | \
docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-2.amazonaws.com
```

### **Step 2: Build and Push Images**
```bash
# Build sample application
docker build -t my-app:latest .

# Tag for ECR
docker tag my-app:latest <ecr-url>:latest

# Push to ECR
docker push <ecr-url>:latest
```

### **Step 3: Deploy to ECS**
```bash
# Update ECS service
aws ecs update-service \
  --cluster dev-data-processing-cluster \
  --service dev-data-processing-service \
  --desired-count 1

# Check service status
aws ecs describe-services \
  --cluster dev-data-processing-cluster \
  --services dev-data-processing-service
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

#### **1. Terraform Cloud Authentication**
```bash
# Check Terraform Cloud token
terraform login

# Verify workspace
terraform workspace list
```

#### **2. AWS Permissions**
```bash
# Check IAM permissions
aws sts get-caller-identity

# Test specific permissions
aws ec2 describe-vpcs
aws s3 ls
aws ecr describe-repositories
```

#### **3. Resource Creation Failures**
```bash
# Check Terraform state
terraform state list

# Check specific resource
terraform state show aws_vpc.main

# Import existing resource (if needed)
terraform import aws_vpc.main vpc-xxxxxxxxx
```

#### **4. Network Connectivity Issues**
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>"

# Test connectivity
telnet <instance-ip> 22
curl http://<instance-ip>:9090
```

#### **5. Monitoring Issues**
```bash
# SSH to monitoring instance
ssh ec2-user@<monitoring-ip>

# Check Docker containers
docker ps

# Check logs
docker logs prometheus
docker logs grafana
docker logs elasticsearch

# Restart services
cd /home/ec2-user/monitoring
docker-compose restart
```

---

## 📊 **Monitoring and Maintenance**

### **Step 1: Set Up Monitoring Dashboards**
```bash
# Access Grafana
open http://<monitoring-ip>:3000

# Import dashboards
# 1. Go to Dashboards > Import
# 2. Use dashboard IDs:
#    - 1860 (Node Exporter)
#    - 315 (Docker)
#    - 6417 (Kubernetes)
```

### **Step 2: Configure Alerts**
```bash
# SSH to monitoring instance
ssh ec2-user@<monitoring-ip>

# Edit Prometheus configuration
nano /home/ec2-user/monitoring/prometheus.yml

# Add alerting rules
cat >> /home/ec2-user/monitoring/prometheus.yml << 'EOF'
rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
EOF

# Restart Prometheus
docker-compose restart prometheus
```

### **Step 3: Set Up Log Aggregation**
```bash
# Check Logstash configuration
cat /home/ec2-user/monitoring/logstash.conf

# Test log ingestion
echo '{"message":"test log","level":"info","timestamp":"2024-01-01T00:00:00Z"}' | \
nc <monitoring-ip> 5044

# Check Elasticsearch
curl http://<monitoring-ip>:9200/_cat/indices
```

---

## 🔄 **Updates and Scaling**

### **Step 1: Update Infrastructure**
```bash
# Make changes to Terraform files
nano main.tf
nano variables.tf

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### **Step 2: Scale Resources**
```bash
# Scale ECS services
aws ecs update-service \
  --cluster dev-data-processing-cluster \
  --service dev-data-processing-service \
  --desired-count 5

# Scale EC2 instances
# Edit terraform files and apply
```

### **Step 3: Update Applications**
```bash
# Update container images
docker build -t my-app:v2.0 .
docker tag my-app:v2.0 <ecr-url>:v2.0
docker push <ecr-url>:v2.0

# Update ECS service
aws ecs update-service \
  --cluster dev-data-processing-cluster \
  --service dev-data-processing-service \
  --task-definition <new-task-definition-arn>
```

---

## 🗑️ **Cleanup and Destruction**

### **Step 1: Backup Important Data**
```bash
# Backup S3 data
aws s3 sync s3://<bucket-name> ./backup/

# Export Terraform state
terraform state pull > terraform.tfstate.backup
```

### **Step 2: Destroy Infrastructure**
```bash
# Plan destruction
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Confirm destruction
# Type 'yes' when prompted
```

### **Step 3: Clean Up Resources**
```bash
# Delete S3 buckets (if not destroyed)
aws s3 rb s3://<bucket-name> --force

# Delete ECR repositories
aws ecr delete-repository --repository-name <repo-name> --force

# Delete CloudWatch logs
aws logs delete-log-group --log-group-name <log-group-name>
```

---

## 📚 **Next Steps**

### **1. Production Readiness**
- [ ] Set up proper monitoring and alerting
- [ ] Configure backup and disaster recovery
- [ ] Implement security best practices
- [ ] Set up CI/CD pipelines
- [ ] Configure auto-scaling policies

### **2. Application Development**
- [ ] Build and deploy applications
- [ ] Set up data pipelines
- [ ] Implement data quality checks
- [ ] Create dashboards and reports
- [ ] Set up machine learning workflows

### **3. Operations**
- [ ] Set up log aggregation
- [ ] Configure monitoring dashboards
- [ ] Implement alerting rules
- [ ] Set up backup procedures
- [ ] Create runbooks and documentation

---

## 🆘 **Support and Resources**

### **Documentation**
- **Infrastructure Overview**: `documentation/INFRASTRUCTURE_OVERVIEW.md`
- **Service Details**: `documentation/SERVICE_DETAILS.md`
- **Terraform Configuration**: `documentation/TERRAFORM_CONFIGURATION.md`
- **Architecture Diagram**: `documentation/ARCHITECTURE_DIAGRAM.md`

### **Useful Commands**
```bash
# Get all outputs
terraform output

# Get specific output
terraform output vpc_id

# Show current state
terraform show

# List all resources
terraform state list

# Refresh state
terraform refresh
```

### **Troubleshooting Resources**
- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform Documentation**: https://terraform.io/docs/
- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/

---

**Your AWS infrastructure is now deployed and ready for development!** 🎉

**Next Steps:**
1. Access your monitoring dashboards
2. Set up your applications
3. Configure data pipelines
4. Start building your data engineering workflows
