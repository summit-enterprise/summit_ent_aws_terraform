# Terraform Configuration Documentation

## 📋 **Terraform Files Structure**

This document explains the Terraform configuration files and their purposes in your AWS infrastructure, now organized in a modular DevOps structure.

---

## 🏗️ **Modular Terraform Structure**

### **Directory Organization**
```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, route tables, IGW
│   ├── security/              # Security groups, IAM roles
│   ├── storage/               # S3, ECR, Glue
│   ├── compute/               # ECS, Kubernetes (Minikube)
│   ├── monitoring/            # Prometheus, Grafana, ELK, Jaeger
│   └── secrets/               # AWS Secrets Manager
├── environments/              # Environment-specific configurations
│   └── dev/                  # Development environment
└── shared/                   # Shared resources (future use)
```

---

## 🏗️ **Environment Configuration Files**

### **1. terraform/environments/dev/main.tf**
**Purpose**: Main configuration using modules

```hcl
# Provider Configuration
provider "aws" {
  region = var.aws_region
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  # ... module configuration
}

# Security Module
module "security" {
  source = "../../modules/security"
  # ... module configuration
}

# Storage Module
module "storage" {
  source = "../../modules/storage"
  # ... module configuration
}

# Compute Module
module "compute" {
  source = "../../modules/compute"
  # ... module configuration
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  # ... module configuration
}

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"
  # ... module configuration
}
```

**Key Components**:
- **Modules**: Reusable infrastructure components
- **Dependencies**: Clear module dependencies
- **Tags**: Consistent tagging strategy
- **Environment**: Isolated environment configuration

**Benefits**:
- **Modularity**: Reusable components
- **Maintainability**: Easy to update individual modules
- **Scalability**: Easy to add new environments
- **Team Collaboration**: Different teams can work on different modules

---

## 🧩 **Module Structure**

### **Module Organization**
Each module follows the standard Terraform module structure:

```
modules/{module-name}/
├── main.tf          # Main resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── README.md        # Module documentation (optional)
```

### **Module Dependencies**
```
networking (VPC, subnets)
    ↓
security (Security groups, IAM)
    ↓
storage (S3, ECR, Glue)
    ↓
compute (ECS, Kubernetes)
    ↓
monitoring (Prometheus, Grafana, etc.)
    ↓
secrets (Secrets Manager)
```

### **Module Benefits**
- **Reusability**: Modules can be used across environments
- **Maintainability**: Single responsibility principle
- **Testing**: Individual modules can be tested
- **Documentation**: Clear module interfaces
- **Versioning**: Module version control

---

## 🏗️ **Legacy Configuration Files**

### **2. variables.tf**
**Purpose**: Input variables and their definitions

```hcl
# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "AWS_DEFAULT_REGION" {
  description = "Default AWS region"
  type        = string
  default     = "us-east-2"
}
```

**Variable Categories**:
- **VPC**: Network configuration
- **Subnets**: CIDR blocks for public/private subnets
- **Environment**: Naming and tagging
- **AWS**: Region and provider settings

**Best Practices**:
- **Descriptions**: Clear descriptions for each variable
- **Types**: Explicit type definitions
- **Defaults**: Sensible default values
- **Validation**: Can add validation rules if needed

---

### **3. outputs.tf**
**Purpose**: Output values for resource information

```hcl
# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}
```

**Output Categories**:
- **VPC**: Network identifiers
- **Security Groups**: Security group IDs
- **ECR**: Repository URLs
- **S3**: Bucket names and ARNs
- **IAM**: Role ARNs
- **Glue**: Job and database names
- **ECS**: Cluster and task definition ARNs
- **Kubernetes**: Instance details and access commands
- **Monitoring**: Service URLs and access information
- **Secrets Manager**: Secret ARNs and retrieval commands

**Benefits**:
- **Resource Discovery**: Easy access to resource identifiers
- **Integration**: Other modules can use these outputs
- **Documentation**: Self-documenting infrastructure
- **Automation**: Scripts can use these values

---

## 🌐 **Network Infrastructure Files**

### **4. vpc.tf**
**Purpose**: VPC, subnets, gateways, and routing

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-main-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-main-igw"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}
```

**Key Resources**:
- **VPC**: Main network container
- **Internet Gateway**: Internet access for public subnets
- **Public Subnets**: Internet-facing resources
- **Private Subnets**: Internal resources
- **Route Tables**: Routing configuration

**Features**:
- **Multi-AZ**: Spans 2 availability zones
- **DNS Support**: Internal and external DNS resolution
- **Public IP Mapping**: Automatic public IP assignment
- **Tagging**: Consistent resource tagging

---

### **5. security-groups.tf**
**Purpose**: Security group definitions and rules

```hcl
# Web Security Group
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
    Purpose     = "Web Tier"
  }
}
```

**Security Groups**:
- **Web**: HTTP/HTTPS access
- **Database**: Database port access
- **App**: Application port access
- **Bastion**: SSH access
- **Kubernetes**: K8s and SSH access
- **Monitoring**: Monitoring service access

**Security Features**:
- **Least Privilege**: Only necessary ports open
- **Layered Security**: Multiple security groups
- **Source Restrictions**: Specific security groups
- **Egress Control**: Controlled outbound access

---

## 🗄️ **Data Platform Files**

### **6. s3.tf**
**Purpose**: S3 buckets for data lake and storage

```hcl
# Random ID for bucket uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Main Data Lake Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.environment}-data-lake-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.environment}-data-lake"
    Environment = var.environment
    Purpose     = "Data Lake Storage"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**S3 Buckets**:
- **Data Lake**: Main storage bucket
- **Glue Scripts**: ETL scripts and artifacts
- **Glue Outputs**: Job outputs and results

**Features**:
- **Versioning**: Object versioning enabled
- **Encryption**: AES-256 encryption at rest
- **Lifecycle Policies**: Automatic cleanup
- **Access Logging**: Audit trail

---

### **7. glue.tf**
**Purpose**: AWS Glue ETL and data catalog

```hcl
# Glue Data Catalog Database
resource "aws_glue_catalog_database" "data_lake_catalog" {
  name = "${var.environment}_data_lake_catalog"

  description = "Data catalog for ${var.environment} data lake"

  tags = {
    Name        = "${var.environment}-data-lake-catalog"
    Environment = var.environment
  }
}

# Glue Crawler for Raw Data
resource "aws_glue_crawler" "raw_data_crawler" {
  database_name = aws_glue_catalog_database.data_lake_catalog.name
  name          = "${var.environment}-raw-data-crawler"
  role          = aws_iam_role.glue_service_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.bucket}/raw/"
  }

  # schedule = "cron(0 2 * * ? *)"  # DISABLED to avoid charges

  tags = {
    Name        = "${var.environment}-raw-data-crawler"
    Environment = var.environment
  }
}
```

**Glue Components**:
- **Data Catalog**: Metadata repository
- **Crawlers**: Schema discovery
- **ETL Jobs**: Data processing
- **Workflow**: Pipeline orchestration
- **Trigger**: Job scheduling

**Cost Optimization**:
- **On-demand**: No scheduled jobs
- **DPU Limits**: Controlled capacity
- **Timeouts**: Prevent runaway jobs

---

### **8. ecr.tf**
**Purpose**: Container registry for Docker images

```hcl
# ECR Repository for Spark Applications
resource "aws_ecr_repository" "spark_apps" {
  name                 = "${var.environment}-spark-apps"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-spark-apps"
    Environment = var.environment
    Purpose     = "Spark Applications"
  }
}
```

**ECR Repositories**:
- **Spark Apps**: Apache Spark applications
- **Data Jobs**: General data processing
- **Glue Jobs**: Custom Glue containers

**Features**:
- **Image Scanning**: Vulnerability detection
- **Lifecycle Policies**: Automatic cleanup
- **Encryption**: Images encrypted at rest
- **IAM Integration**: Access control

---

## 🚀 **Compute Infrastructure Files**

### **9. ecs.tf**
**Purpose**: ECS cluster and task definitions

```hcl
# ECS Cluster
resource "aws_ecs_cluster" "data_processing" {
  name = "${var.environment}-data-processing-cluster"

  tags = {
    Name        = "${var.environment}-data-processing-cluster"
    Environment = var.environment
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "data_processing" {
  cluster_name = aws_ecs_cluster.data_processing.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 1
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 0
  }
}
```

**ECS Components**:
- **Cluster**: Container orchestration
- **Capacity Providers**: Fargate and Fargate Spot
- **Task Definitions**: Container specifications
- **Services**: Running task management

**Cost Optimization**:
- **Fargate Spot**: Up to 70% savings
- **Right-sizing**: Appropriate CPU/memory
- **Desired Count**: 0 by default

---

### **10. kubernetes.tf**
**Purpose**: Kubernetes cluster with Minikube

```hcl
# EC2 Instance for Kubernetes (Minikube)
resource "aws_instance" "kubernetes" {
  count = 1

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.small"  # 2GB RAM - enough for Minikube
  key_name      = aws_key_pair.kubernetes.key_name

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.kubernetes.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y

    # Install Docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # Install Minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube-linux-amd64
    mv minikube-linux-amd64 /usr/local/bin/minikube

    # Start Minikube with optimal resources for t3.small
    su - ec2-user -c "minikube start --driver=docker --memory=1536 --cpus=1"
  EOF
  )
}
```

**Kubernetes Setup**:
- **EC2 Instance**: t3.small for cost optimization
- **Minikube**: Local Kubernetes cluster
- **ArgoCD**: GitOps deployment
- **Docker**: Container runtime

**Features**:
- **SSH Access**: Key pair authentication
- **User Data**: Automated setup
- **ArgoCD**: GitOps integration
- **Monitoring**: Integrated with monitoring stack

---

### **11. monitoring.tf**
**Purpose**: Monitoring and observability stack

```hcl
# EC2 Instance for Monitoring Stack
resource "aws_instance" "monitoring" {
  count = 1

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.small"  # 2 vCPU, 2GB RAM - enough for monitoring stack
  # key_name      = aws_key_pair.kubernetes.key_name  # Uncomment if you have SSH key

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y

    # Install Docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Create monitoring directory
    mkdir -p /home/ec2-user/monitoring
    cd /home/ec2-user/monitoring

    # Create Docker Compose for monitoring stack
    cat > docker-compose.yml << 'COMPOSE_EOF'
    version: '3.8'

    networks:
      monitoring:
        driver: bridge

    services:
      prometheus:
        image: prom/prometheus:latest
        container_name: prometheus
        ports:
          - "9090:9090"
        volumes:
          - ./prometheus.yml:/etc/prometheus/prometheus.yml
          - prometheus_data:/prometheus
        command:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
          - '--web.console.libraries=/usr/share/prometheus/console_libraries'
          - '--web.console.templates=/usr/share/prometheus/consoles'
        networks:
          - monitoring
    COMPOSE_EOF

    # Start monitoring stack
    docker-compose up -d
  EOF
  )
}
```

**Monitoring Components**:
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **ELK Stack**: Log management
- **Jaeger**: Distributed tracing
- **Additional Tools**: Node exporter, cAdvisor, etc.

**Features**:
- **Docker Compose**: Easy management
- **Self-hosted**: No CloudWatch charges
- **Comprehensive**: Metrics, logs, traces
- **Scalable**: Can handle large volumes

---

## 🔐 **Security Files**

### **12. iam.tf**
**Purpose**: IAM roles and policies

```hcl
# Glue Service Role
resource "aws_iam_role" "glue_service_role" {
  name = "${var.environment}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-glue-service-role"
    Environment = var.environment
  }
}
```

**IAM Roles**:
- **Glue Service Role**: ETL job execution
- **ECS Task Execution Role**: Container management
- **ECS Task Role**: Application permissions

**Policies**:
- **Data Lake Access**: S3 permissions
- **ECR Access**: Container registry access
- **Secrets Manager**: Secret retrieval

---

### **13. secrets-manager.tf**
**Purpose**: Secret storage and management

```hcl
# Random password for RDS MySQL
resource "random_password" "mysql_password" {
  length  = 16
  special = true
}

# MySQL Database Secret
resource "aws_secretsmanager_secret" "mysql_credentials" {
  count = 1

  name                    = "${var.environment}-mysql-credentials"
  description             = "MySQL database credentials for ${var.environment}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.environment}-mysql-credentials"
    Environment = var.environment
    Service     = "RDS"
  }
}
```

**Secrets**:
- **Database Credentials**: MySQL, Redis
- **Application Credentials**: Grafana, ArgoCD
- **App Secrets**: JWT, API keys, encryption keys

**Features**:
- **Random Passwords**: 16-character generated passwords
- **Encryption**: AWS KMS encryption
- **Access Control**: IAM-based permissions
- **Audit Logging**: CloudTrail integration

---

## 📁 **Example Files**

### **14. examples/ec2.tf**
**Purpose**: Example database and compute resources

```hcl
# Example: RDS MySQL Database
resource "aws_db_instance" "mysql" {
  count = 0  # Set to 1 to enable

  identifier = "${var.environment}-mysql"
  engine     = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 100

  db_name  = "mydb"
  username = "admin"
  password = random_password.mysql_password.result

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = {
    Name        = "${var.environment}-mysql"
    Environment = var.environment
  }
}
```

**Example Resources**:
- **RDS MySQL**: Database instance
- **ElastiCache Redis**: Cache cluster
- **EC2 Instances**: Web servers

**Features**:
- **Disabled by Default**: Set count = 0
- **Easy Enable**: Change count to 1
- **Cost Control**: Only deploy what you need

---

## 🔧 **Environment Management Files**

### **15. .gitignore**
**Purpose**: Git ignore patterns

```gitignore
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
*.tfplan.*

# Environment variables and secrets
.env
.env.local
.env.*.local
*.env
secrets/
credentials/

# SSH keys and certificates
*.pem
*.key
*.crt
*.p12
*.pfx

# AWS credentials
.aws/
aws-credentials
```

**Ignored Files**:
- **Terraform State**: Local state files
- **Environment Variables**: Sensitive configuration
- **Credentials**: AWS keys and certificates
- **Temporary Files**: Build artifacts

---

### **16. Environment Files**

#### **env.template**
**Purpose**: Environment variable template

```bash
# AWS Configuration
AWS_DEFAULT_REGION=us-east-2
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here

# Environment Settings
ENVIRONMENT=dev
VPC_CIDR=10.0.0.0/16
```

**Template Features**:
- **Safe to Commit**: No sensitive data
- **Comprehensive**: All variables documented
- **Documented**: Clear descriptions

#### **load-env.sh**
**Purpose**: Environment variable loader

```bash
#!/bin/bash
# Load environment variables from .env file

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Verify required variables
if [ -z "$AWS_DEFAULT_REGION" ]; then
    echo "❌ Missing required variable: AWS_DEFAULT_REGION"
    exit 1
fi
```

**Loader Features**:
- **Validation**: Checks for required variables
- **Error Handling**: Clear error messages
- **Flexibility**: Works with different shell types

---

## 🚀 **Deployment Process**

### **1. Environment Setup**
```bash
# Set up environment variables
./setup-env.sh
nano .env
source load-env.sh
```

### **2. Terraform Initialization**
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan
```

### **3. Deployment**
```bash
# Deploy infrastructure
terraform apply

# Get outputs
terraform output
```

### **4. Verification**
```bash
# Check resources
aws ec2 describe-instances
aws s3 ls
aws ecr describe-repositories
```

---

## 🔧 **Best Practices**

### **1. File Organization**
- **Modular Structure**: Separate files by service
- **Clear Naming**: Descriptive file names
- **Consistent Formatting**: Standardized code style
- **Documentation**: Inline comments and descriptions

### **2. Security**
- **Least Privilege**: Minimal required permissions
- **Secrets Management**: Use AWS Secrets Manager
- **Encryption**: Enable encryption at rest
- **Access Control**: IAM roles and policies

### **3. Cost Optimization**
- **Right-sizing**: Appropriate resource sizes
- **Spot Instances**: Use when possible
- **On-demand Services**: Avoid unnecessary scheduling
- **Lifecycle Policies**: Automatic cleanup

### **4. Monitoring**
- **Comprehensive Logging**: All services monitored
- **Alerting**: Proactive issue detection
- **Dashboards**: Visual monitoring
- **Tracing**: Distributed request tracking

---

## 📚 **Documentation Files**

### **Generated Documentation**
- **`INFRASTRUCTURE_OVERVIEW.md`**: Complete system overview
- **`SERVICE_DETAILS.md`**: Detailed service explanations
- **`TERRAFORM_CONFIGURATION.md`**: This file
- **`ARCHITECTURE_DIAGRAM.md`**: Visual architecture
- **`DEPLOYMENT_GUIDE.md`**: Step-by-step deployment
- **`TROUBLESHOOTING.md`**: Common issues and solutions

### **Configuration Files**
- **`env.template`**: Environment variable template
- **`load-env.sh`**: Environment loader script
- **`setup-env.sh`**: Environment setup script
- **`.gitignore`**: Git ignore patterns

---

**This Terraform configuration provides a complete, production-ready infrastructure with proper organization, security, and documentation!** 🎉
