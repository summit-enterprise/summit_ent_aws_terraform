# Environment Variables Setup Guide

## 🔧 **Environment Variables Configuration**

This guide helps you set up environment variables for your AWS infrastructure project.

## 📋 **Quick Setup**

### **1. Copy the Template:**
```bash
cp env.template .env
```

### **2. Edit Your Environment File:**
```bash
nano .env
# or
code .env
# or
vim .env
```

### **3. Load Environment Variables:**
```bash
# Load variables into current session
source load-env.sh

# Or add to your shell profile for permanent loading
echo "source $(pwd)/load-env.sh" >> ~/.bashrc
```

## 🔑 **Required Variables**

### **AWS Configuration:**
```bash
AWS_DEFAULT_REGION=us-east-2
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
```

### **Environment Settings:**
```bash
ENVIRONMENT=dev
VPC_CIDR=10.0.0.0/16
```

## 📝 **All Available Variables**

| **Category** | **Variable** | **Default** | **Description** |
|--------------|--------------|-------------|-----------------|
| **AWS** | `AWS_DEFAULT_REGION` | `us-east-2` | AWS region for resources |
| **AWS** | `AWS_ACCESS_KEY_ID` | - | AWS access key |
| **AWS** | `AWS_SECRET_ACCESS_KEY` | - | AWS secret key |
| **Environment** | `ENVIRONMENT` | `dev` | Environment name |
| **Environment** | `VPC_CIDR` | `10.0.0.0/16` | VPC CIDR block |
| **Network** | `AVAILABILITY_ZONES` | `["us-east-2a", "us-east-2b"]` | AZs for subnets |
| **Network** | `PUBLIC_SUBNET_CIDRS` | `["10.0.1.0/24", "10.0.2.0/24"]` | Public subnet CIDRs |
| **Network** | `PRIVATE_SUBNET_CIDRS` | `["10.0.10.0/24", "10.0.20.0/24"]` | Private subnet CIDRs |
| **EC2** | `KUBERNETES_INSTANCE_TYPE` | `t3.small` | Kubernetes instance type |
| **EC2** | `MONITORING_INSTANCE_TYPE` | `t3.small` | Monitoring instance type |
| **Storage** | `KUBERNETES_STORAGE_SIZE` | `20` | Kubernetes storage (GB) |
| **Storage** | `MONITORING_STORAGE_SIZE` | `20` | Monitoring storage (GB) |
| **Monitoring** | `PROMETHEUS_SCRAPE_INTERVAL` | `15s` | Prometheus scrape interval |
| **Monitoring** | `GRAFANA_ADMIN_PASSWORD` | `admin123` | Grafana admin password |
| **ArgoCD** | `ARGOCD_NAMESPACE` | `argocd` | ArgoCD namespace |
| **ArgoCD** | `ARGOCD_NODEPORT` | `30080` | ArgoCD NodePort |
| **S3** | `S3_BUCKET_VERSIONING` | `true` | Enable S3 versioning |
| **S3** | `S3_BUCKET_ENCRYPTION` | `AES256` | S3 encryption type |
| **Glue** | `GLUE_MAX_CAPACITY` | `2` | Glue job max capacity |
| **Glue** | `GLUE_TIMEOUT` | `60` | Glue job timeout (minutes) |
| **ECS** | `ECS_DESIRED_COUNT` | `0` | ECS service desired count |
| **ECS** | `ECS_CPU` | `1024` | ECS task CPU units |
| **ECS** | `ECS_MEMORY` | `2048` | ECS task memory (MB) |
| **Security** | `ENABLE_SSH_ACCESS` | `true` | Enable SSH access |
| **Security** | `ENABLE_ELASTIC_IPS` | `true` | Enable Elastic IPs |
| **Cost** | `USE_SPOT_INSTANCES` | `false` | Use Spot instances |
| **Cost** | `ENABLE_CLOUDWATCH` | `false` | Enable CloudWatch |

## 🚀 **Usage Examples**

### **1. Basic Usage:**
```bash
# Load environment variables
source load-env.sh

# Run Terraform commands
terraform plan
terraform apply
```

### **2. Custom Environment:**
```bash
# Set custom environment
export ENVIRONMENT=prod
export AWS_DEFAULT_REGION=us-west-2

# Load other variables
source load-env.sh
```

### **3. Different Configurations:**
```bash
# Development environment
cp env.template .env.dev
# Edit .env.dev with dev settings
export ENV_FILE=.env.dev
source load-env.sh

# Production environment
cp env.template .env.prod
# Edit .env.prod with prod settings
export ENV_FILE=.env.prod
source load-env.sh
```

## 🔒 **Security Best Practices**

### **1. Never Commit Sensitive Data:**
```bash
# These files are in .gitignore
.env
.env.local
.env.*.local
*.env
secrets/
credentials/
```

### **2. Use AWS IAM Roles (Recommended):**
```bash
# Instead of hardcoding credentials, use IAM roles
# Remove these from .env:
# AWS_ACCESS_KEY_ID=your_access_key_here
# AWS_SECRET_ACCESS_KEY=your_secret_key_here
```

### **3. Environment-Specific Files:**
```bash
# Create environment-specific files
.env.dev          # Development
.env.staging      # Staging
.env.prod         # Production
```

## 🛠️ **Terraform Integration**

### **1. Using Environment Variables in Terraform:**
```hcl
# In your .tf files, you can reference environment variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

# Or use them directly
provider "aws" {
  region = var.aws_region
}
```

### **2. Terraform Cloud Variables:**
```bash
# Set variables in Terraform Cloud
terraform cloud workspace variable set AWS_DEFAULT_REGION us-east-2
terraform cloud workspace variable set ENVIRONMENT dev
```

## 🔍 **Troubleshooting**

### **Common Issues:**

#### **1. Environment Variables Not Loading:**
```bash
# Check if .env file exists
ls -la .env

# Check file permissions
ls -la load-env.sh

# Make script executable
chmod +x load-env.sh
```

#### **2. Missing Required Variables:**
```bash
# Check which variables are missing
source load-env.sh

# Verify variables are set
echo $AWS_DEFAULT_REGION
echo $ENVIRONMENT
```

#### **3. Terraform Not Using Variables:**
```bash
# Check Terraform variable precedence
terraform plan -var="environment=dev"

# Or use .tfvars file
echo 'environment = "dev"' > terraform.tfvars
```

## 📚 **Advanced Usage**

### **1. Multiple Environments:**
```bash
# Create environment-specific configurations
mkdir -p environments/{dev,staging,prod}

# Copy template to each environment
cp env.template environments/dev/.env
cp env.template environments/staging/.env
cp env.template environments/prod/.env

# Load specific environment
export ENV_FILE=environments/dev/.env
source load-env.sh
```

### **2. CI/CD Integration:**
```yaml
# GitHub Actions example
- name: Load environment variables
  run: |
    cp env.template .env
    echo "AWS_ACCESS_KEY_ID=${{ secrets.AWS_ACCESS_KEY_ID }}" >> .env
    echo "AWS_SECRET_ACCESS_KEY=${{ secrets.AWS_SECRET_ACCESS_KEY }}" >> .env
    source load-env.sh
```

### **3. Docker Integration:**
```dockerfile
# Dockerfile example
COPY env.template .env
RUN chmod +x load-env.sh
CMD ["source", "load-env.sh", "&&", "terraform", "apply"]
```

---

**Your environment is now properly configured and secure!** 🔒
