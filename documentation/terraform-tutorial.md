# Complete Terraform Infrastructure Tutorial

## 🏗️ **Building AWS Infrastructure from Scratch with Modular Structure**

This tutorial walks you through recreating the entire AWS infrastructure setup from the ground up using a modern modular DevOps approach, explaining the reasoning and order of each step.

---

## 📋 **Tutorial Overview**

### **What We'll Build**
- **Modular Structure**: 6 reusable Terraform modules
- **VPC Network**: Multi-AZ network foundation
- **Security Groups**: Layered security architecture
- **IAM Roles**: Service-specific permissions
- **S3 Data Lake**: Scalable data storage
- **AWS Glue**: ETL and data catalog
- **ECR**: Container registry
- **ECS**: Serverless container orchestration
- **Kubernetes**: Minikube cluster with ArgoCD
- **Monitoring**: Prometheus, Grafana, ELK, Jaeger
- **Secrets Manager**: Secure credential storage

### **Why This Order?**
1. **Foundation First**: VPC and networking
2. **Security Second**: IAM and security groups
3. **Storage Third**: S3 and data infrastructure
4. **Compute Fourth**: ECS and Kubernetes
5. **Monitoring Fifth**: Observability and management
6. **Secrets Last**: Secure credential storage

### **Modern Approach**
- **Modular Design**: Reusable components
- **Published Modules**: GitHub and Terraform Registry
- **Environment Isolation**: Dev/staging/prod separation
- **Best Practices**: Enterprise-grade structure

---

## 🚀 **Phase 1: Foundation Setup**

### **Step 1: Create Modular Project Structure**

**Why First?** We need the modular structure before building any resources.

```bash
# Create project directory
mkdir aws-terraform-tutorial
cd aws-terraform-tutorial

# Create modular directory structure
mkdir -p terraform/{modules,environments/{dev,staging,prod},shared}
mkdir -p terraform/modules/{networking,security,storage,compute,monitoring,secrets}
mkdir -p documentation
```

**Project Structure:**
```
aws-terraform-tutorial/
├── terraform/
│   ├── modules/                    # Reusable modules
│   │   ├── networking/            # VPC, subnets, IGW
│   │   ├── security/              # Security groups, IAM
│   │   ├── storage/               # S3, ECR, Glue
│   │   ├── compute/               # ECS, Kubernetes
│   │   ├── monitoring/            # Prometheus, Grafana, ELK
│   │   └── secrets/               # Secrets Manager
│   ├── environments/              # Environment configs
│   │   ├── dev/                  # Development
│   │   ├── staging/              # Staging
│   │   └── prod/                 # Production
│   └── shared/                   # Shared resources
├── documentation/                 # All documentation
└── publish-modules.sh            # Module publishing script
```

### **Step 2: Initialize Root Configuration**

**Create `main.tf` (Root):**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  required_version = ">= 1.0"
  
  # Terraform Cloud backend
  cloud {
    organization = "your-organization"
    workspaces {
      name = "aws-terraform-tutorial"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

**Create `variables.tf` (Root):**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```

---

## 🌐 **Phase 2: Create Networking Module**

### **Step 3: Build the Networking Module**

**Why First?** Everything else depends on the network foundation.

**Create `terraform/modules/networking/main.tf`:**
```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.environment}-main-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.environment}-main-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-public-rt"
  })
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.environment}-private-rt"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

**Create `terraform/modules/networking/variables.tf`:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}

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

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
```

**Create `terraform/modules/networking/outputs.tf`:**
```hcl
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

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}
```

**Create `terraform/modules/networking/versions.tf`:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**Why This Module Structure?**
- **Reusable**: Can be used across environments
- **Configurable**: Variables for customization
- **Outputs**: Exposes values for other modules
- **Versioned**: Provider version constraints

---

## 🔒 **Phase 3: Create Security Module**

### **Step 4: Build the Security Module**

**Why Second?** Security groups and IAM roles are needed before compute resources.

**Create `terraform/modules/security/main.tf`:**
```hcl
# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = merge(var.tags, {
    Name = "${var.environment}-web-sg"
  })
}

resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-database-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-database-sg"
  })
}

resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-app-sg"
  })
}

# IAM Roles
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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}
```

**Create `terraform/modules/security/variables.tf`:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
```

**Create `terraform/modules/security/outputs.tf`:**
```hcl
output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    web      = aws_security_group.web.id
    database = aws_security_group.database.id
    app      = aws_security_group.app.id
  }
}

output "iam_role_arns" {
  description = "Map of IAM role ARNs"
  value = {
    glue_service_role      = aws_iam_role.glue_service_role.arn
    ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.arn
    ecs_task_role          = aws_iam_role.ecs_task_role.arn
  }
}
```

---

## 💾 **Phase 4: Create Storage Module**

### **Step 5: Build the Storage Module**

**Why Third?** Storage resources are needed before compute can use them.

**Create `terraform/modules/storage/main.tf`:**
```hcl
# ECR Repositories
resource "aws_ecr_repository" "spark_apps" {
  name                 = "${var.environment}-spark-apps"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_repository" "data_jobs" {
  name                 = "${var.environment}-data-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_repository" "glue_jobs" {
  name                 = "${var.environment}-glue-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# S3 Data Lake
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.environment}-data-lake-${random_string.bucket_suffix.result}"

  tags = var.tags
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# AWS Glue
resource "aws_glue_catalog_database" "data_lake_catalog" {
  name = "${var.environment}-data-lake-catalog"

  tags = var.tags
}

resource "aws_glue_crawler" "data_lake_crawler" {
  database_name = aws_glue_catalog_database.data_lake_catalog.name
  name          = "${var.environment}-data-lake-crawler"
  role          = var.glue_service_role_arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.bucket}/raw/"
  }

  tags = var.tags
}

resource "aws_glue_job" "data_processing_job" {
  name     = "${var.environment}-data-processing-job"
  role_arn = var.glue_service_role_arn

  command {
    script_location = "s3://${aws_s3_bucket.data_lake.bucket}/scripts/data_processing.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language" = "python"
    "--job-bookmark-option" = "job-bookmark-enable"
  }

  tags = var.tags
}
```

**Create `terraform/modules/storage/variables.tf`:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "glue_service_role_arn" {
  description = "ARN of the Glue service role"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
```

**Create `terraform/modules/storage/outputs.tf`:**
```hcl
output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value = {
    spark_apps = aws_ecr_repository.spark_apps.repository_url
    data_jobs  = aws_ecr_repository.data_jobs.repository_url
    glue_jobs  = aws_ecr_repository.glue_jobs.repository_url
  }
}

output "data_lake_bucket_name" {
  description = "Name of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "data_lake_bucket_arn" {
  description = "ARN of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.arn
}
```

---

## 🖥️ **Phase 5: Create Compute Module**

### **Step 6: Build the Compute Module**

**Why Fourth?** Compute resources need networking, security, and storage.

**Create `terraform/modules/compute/main.tf`:**
```hcl
# ECS Cluster
resource "aws_ecs_cluster" "data_processing" {
  name = "${var.environment}-data-processing"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "data_processing" {
  cluster_name = aws_ecs_cluster.data_processing.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "data_processing_task" {
  family                   = "${var.environment}-data-processing-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "data-processor"
      image = "${var.ecr_repository_urls.data_jobs}:latest"
      
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "S3_BUCKET"
          value = var.data_lake_bucket_name
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}-data-processing"
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# Kubernetes EC2 Instance
resource "aws_instance" "kubernetes" {
  count = var.enable_kubernetes ? 1 : 0

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name              = var.kubernetes_key_name
  vpc_security_group_ids = [var.kubernetes_security_group_id]
  subnet_id             = var.public_subnet_ids[0]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-kubernetes"
  })
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

**Create `terraform/modules/compute/user_data.sh`:**
```bash
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Start Minikube
minikube start --driver=docker

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create ArgoCD access script
cat > /home/ec2-user/argocd-access.sh << 'EOF'
#!/bin/bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
echo "ArgoCD UI available at: http://localhost:8080"
echo "Admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
EOF

chmod +x /home/ec2-user/argocd-access.sh
```

**Create `terraform/modules/compute/variables.tf`:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Map of security group IDs"
  type = object({
    web      = string
    database = string
    app      = string
  })
}

variable "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  type = object({
    spark_apps = string
    data_jobs  = string
    glue_jobs  = string
  })
}

variable "data_lake_bucket_name" {
  description = "Name of the data lake S3 bucket"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "kubernetes_security_group_id" {
  description = "ID of the Kubernetes security group"
  type        = string
}

variable "kubernetes_key_name" {
  description = "Name of the EC2 key pair for Kubernetes"
  type        = string
  default     = ""
}

variable "enable_kubernetes" {
  description = "Enable Kubernetes instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
```

---

## 📊 **Phase 6: Create Monitoring Module**

### **Step 7: Build the Monitoring Module**

**Why Fifth?** Monitoring needs compute resources to monitor.

**Create `terraform/modules/monitoring/main.tf`:**
```hcl
# Monitoring EC2 Instance
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [var.monitoring_security_group_id]
  subnet_id             = var.public_subnet_ids[0]

  user_data = base64encode(templatefile("${path.module}/monitoring_setup.sh", {
    environment = var.environment
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-monitoring"
  })
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

**Create `terraform/modules/monitoring/monitoring_setup.sh`:**
```bash
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create monitoring directory
mkdir -p /opt/monitoring
cd /opt/monitoring

# Create docker-compose.yml for monitoring stack
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana-storage:/var/lib/grafana

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-storage:/usr/share/elasticsearch/data

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

  jaeger:
    image: jaegertracing/all-in-one:latest
    container_name: jaeger
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true

volumes:
  grafana-storage:
  elasticsearch-storage:
EOF

# Create Prometheus configuration
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Start monitoring stack
docker-compose up -d
```

---

## 🔐 **Phase 7: Create Secrets Module**

### **Step 8: Build the Secrets Module**

**Why Last?** Secrets are needed by all other modules but don't depend on them.

**Create `terraform/modules/secrets/main.tf`:**
```hcl
# Random passwords
resource "random_password" "mysql_password" {
  length  = 16
  special = true
}

resource "random_password" "redis_password" {
  length  = 16
  special = true
}

resource "random_password" "grafana_password" {
  length  = 16
  special = true
}

# Secrets Manager secrets
resource "aws_secretsmanager_secret" "mysql_credentials" {
  name = "${var.environment}-mysql-credentials"
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "mysql_credentials" {
  secret_id = aws_secretsmanager_secret.mysql_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.mysql_password.result
    host     = "mysql.${var.environment}.local"
    port     = 3306
  })
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  name = "${var.environment}-redis-credentials"
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_credentials" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id
  secret_string = jsonencode({
    password = random_password.redis_password.result
    host     = "redis.${var.environment}.local"
    port     = 6379
  })
}

resource "aws_secretsmanager_secret" "grafana_credentials" {
  name = "${var.environment}-grafana-credentials"
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "grafana_credentials" {
  secret_id = aws_secretsmanager_secret.grafana_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana_password.result
  })
}
```

---

## 🏗️ **Phase 8: Create Environment Configuration**

### **Step 9: Build the Dev Environment**

**Create `terraform/environments/dev/main.tf`:**
```hcl
# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = "aws-terraform-tutorial"
    ManagedBy   = "terraform"
  }
}

# ========================================
# NETWORKING MODULE
# ========================================
module "networking" {
  source = "../../modules/networking"

  environment           = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

# ========================================
# SECURITY MODULE
# ========================================
module "security" {
  source = "../../modules/security"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = local.common_tags
}

# ========================================
# STORAGE MODULE
# ========================================
module "storage" {
  source = "../../modules/storage"

  environment           = var.environment
  glue_service_role_arn = module.security.iam_role_arns.glue_service_role
  tags                  = local.common_tags
}

# ========================================
# COMPUTE MODULE
# ========================================
module "compute" {
  source = "../../modules/compute"

  environment           = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  security_group_ids   = module.security.security_group_ids
  ecr_repository_urls  = module.storage.ecr_repository_urls
  data_lake_bucket_name = module.storage.data_lake_bucket_name
  ecs_task_role_arn    = module.security.iam_role_arns.ecs_task_role
  ecs_task_execution_role_arn = module.security.iam_role_arns.ecs_task_execution_role
  kubernetes_security_group_id = module.security.security_group_ids.app
  tags                 = local.common_tags
}

# ========================================
# MONITORING MODULE
# ========================================
module "monitoring" {
  source = "../../modules/monitoring"

  environment        = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  monitoring_security_group_id = module.security.security_group_ids.app
  tags              = local.common_tags
}

# ========================================
# SECRETS MODULE
# ========================================
module "secrets" {
  source = "../../modules/secrets"

  environment = var.environment
  tags        = local.common_tags
}
```

**Create `terraform/environments/dev/variables.tf`:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

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
```

**Create `terraform/environments/dev/outputs.tf`:**
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.storage.ecr_repository_urls
}

output "data_lake_bucket_name" {
  description = "Name of the data lake S3 bucket"
  value       = module.storage.data_lake_bucket_name
}

output "monitoring_urls" {
  description = "Map of monitoring service URLs"
  value = {
    prometheus = "http://${module.monitoring.monitoring_public_ip}:9090"
    grafana    = "http://${module.monitoring.monitoring_public_ip}:3000"
    kibana     = "http://${module.monitoring.monitoring_public_ip}:5601"
    jaeger     = "http://${module.monitoring.monitoring_public_ip}:16686"
  }
}
```

---

## 🚀 **Phase 9: Deploy and Test**

### **Step 10: Deploy the Infrastructure**

```bash
# Navigate to dev environment
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### **Step 11: Verify Deployment**

```bash
# Check outputs
terraform output

# Verify resources
terraform show

# Test connectivity
curl http://$(terraform output -raw monitoring_public_ip):9090
```

---

## 📚 **Phase 10: Publish Modules**

### **Step 12: Publish to GitHub**

**Create `publish-modules.sh`:**
```bash
#!/bin/bash

# Configuration
GITHUB_USERNAME="your-username"
MODULES_DIR="terraform/modules"
GITHUB_ORG=""  # Leave empty for personal account

# Function to publish a module
publish_module() {
    local module_name=$1
    local module_path="$MODULES_DIR/$module_name"
    
    echo "Publishing $module_name module..."
    
    # Create GitHub repository
    gh repo create "terraform-aws-$module_name" --public --source="$module_path" --remote=origin
    
    # Initialize git in module directory
    cd "$module_path"
    git init
    git add .
    git commit -m "Initial commit: $module_name module"
    
    # Add remote and push
    git remote add origin "https://github.com/$GITHUB_USERNAME/terraform-aws-$module_name.git"
    git branch -M main
    git push -u origin main
    
    # Create and push tag
    git tag v1.0.0
    git push origin v1.0.0
    
    cd - > /dev/null
    echo "✅ $module_name module published successfully!"
}

# Publish all modules
for module in networking security storage compute monitoring secrets; do
    publish_module "$module"
done

echo "🎉 All modules published successfully!"
```

**Make it executable and run:**
```bash
chmod +x publish-modules.sh
./publish-modules.sh
```

---

## 🎯 **Summary**

### **What We Built**
1. **6 Reusable Modules**: Networking, Security, Storage, Compute, Monitoring, Secrets
2. **Environment Isolation**: Dev/staging/prod separation
3. **Published Modules**: GitHub repositories with versioning
4. **Complete Infrastructure**: VPC, ECS, Kubernetes, Monitoring, Secrets
5. **Best Practices**: Modular design, proper tagging, security

### **Key Benefits**
- **Reusable**: Modules can be used across environments
- **Maintainable**: Clear separation of concerns
- **Scalable**: Easy to add new environments
- **Secure**: Proper IAM and security groups
- **Cost-Effective**: Optimized for development

### **Next Steps**
1. **Test in Staging**: Deploy to staging environment
2. **Add Production**: Create production environment
3. **CI/CD Pipeline**: Automate deployments
4. **Monitoring**: Set up alerts and dashboards
5. **Documentation**: Keep documentation updated

**Congratulations! You've built a complete, modular AWS infrastructure with Terraform!** 🎉