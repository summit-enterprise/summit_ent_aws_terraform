# Complete Terraform Infrastructure Tutorial

## 🏗️ **Building AWS Infrastructure from Scratch**

This tutorial walks you through recreating the entire AWS infrastructure setup from the ground up, explaining the reasoning and order of each step.

---

## 📋 **Tutorial Overview**

### **What We'll Build**
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
5. **Monitoring Last**: Observability and management

---

## 🚀 **Phase 1: Foundation Setup**

### **Step 1: Initialize Terraform Project**

**Why First?** We need the basic Terraform structure before building anything.

```bash
# Create project directory
mkdir aws-terraform-tutorial
cd aws-terraform-tutorial

# Initialize Terraform
terraform init
```

**Create `main.tf`:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-2"
}
```

**Why This Configuration?**
- **AWS Provider**: Latest stable version
- **Region**: us-east-2 (cost-effective, good availability)
- **Version Constraints**: Ensures compatibility

### **Step 2: Create Variables**

**Why Variables?** Reusability, consistency, and easy customization.

**Create `variables.tf`:**
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

**Why These Variables?**
- **Environment**: Consistent naming and tagging
- **VPC CIDR**: Large enough for growth (65,536 IPs)
- **Multi-AZ**: High availability across zones
- **Subnet Separation**: Security and network isolation

---

## 🌐 **Phase 2: Network Infrastructure**

### **Step 3: Create VPC**

**Why VPC First?** Everything else depends on the network foundation.

**Create `vpc.tf`:**
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
```

**Why This Configuration?**
- **DNS Support**: Enables internal and external DNS resolution
- **Internet Gateway**: Provides internet access for public subnets
- **Tagging**: Consistent resource identification

### **Step 4: Create Subnets**

**Why Subnets?** Network segmentation for security and organization.

```hcl
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

**Why This Structure?**
- **Public Subnets**: Internet-facing resources (load balancers, bastion hosts)
- **Private Subnets**: Internal resources (databases, applications)
- **Multi-AZ**: High availability across availability zones
- **Count**: Dynamic subnet creation based on variables

### **Step 5: Create Route Tables**

**Why Route Tables?** Control traffic flow between subnets and internet.

```hcl
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
  }
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

**Why This Routing?**
- **Public Routes**: Direct internet access via IGW
- **Private Routes**: No internet access (more secure)
- **Associations**: Connect subnets to appropriate route tables

---

## 🔒 **Phase 3: Security Infrastructure**

### **Step 6: Create Security Groups**

**Why Security Groups?** Virtual firewalls for network security.

**Create `security-groups.tf`:**
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

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-db-"
  vpc_id      = aws_vpc.main.id

  # MySQL
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Redis
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
    Purpose     = "Database Tier"
  }
}

# App Security Group
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  vpc_id      = aws_vpc.main.id

  # Application ports
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # Node.js
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-app-sg"
    Environment = var.environment
    Purpose     = "Application Tier"
  }
}
```

**Why This Security Model?**
- **Layered Security**: Different rules for different tiers
- **Least Privilege**: Only necessary ports open
- **Source Restrictions**: Specific security groups, not 0.0.0.0/0
- **Egress Control**: Controlled outbound access

### **Step 7: Create IAM Roles**

**Why IAM Roles?** Service-specific permissions and access control.

**Create `iam.tf`:**
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

# Attach AWS managed policy
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# ECS Task Execution Role
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

  tags = {
    Name        = "${var.environment}-ecs-task-execution-role"
    Environment = var.environment
  }
}

# Attach AWS managed policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
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

  tags = {
    Name        = "${var.environment}-ecs-task-role"
    Environment = var.environment
  }
}
```

**Why These Roles?**
- **Service-Specific**: Each service gets only what it needs
- **Assume Role**: Services can assume these roles
- **Managed Policies**: AWS-provided permissions
- **Custom Policies**: Additional specific permissions

---

## 🗄️ **Phase 4: Data Infrastructure**

### **Step 8: Create S3 Data Lake**

**Why S3 First?** Data storage is the foundation of data engineering.

**Create `s3.tf`:**
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

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Why This S3 Configuration?**
- **Random Suffix**: Ensures global uniqueness
- **Versioning**: Protects against accidental deletion
- **Encryption**: Data security at rest
- **Public Access Block**: Prevents accidental public exposure

### **Step 9: Create AWS Glue**

**Why Glue?** Serverless ETL and data catalog for data processing.

**Create `glue.tf`:**
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

# Glue Job for Data Processing
resource "aws_glue_job" "data_processing_job" {
  name     = "${var.environment}-data-processing-job"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/data_processing.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                    = "python"
    "--job-bookmark-option"            = "job-bookmark-enable"
    "--enable-metrics"                 = "true"
    "--TempDir"                        = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
  }

  max_capacity = 2
  timeout      = 60

  tags = {
    Name        = "${var.environment}-data-processing-job"
    Environment = var.environment
  }
}
```

**Why This Glue Setup?**
- **Data Catalog**: Centralized metadata repository
- **Crawlers**: Automatic schema discovery
- **ETL Jobs**: Data processing and transformation
- **Cost Optimization**: On-demand execution only

---

## 🐳 **Phase 5: Container Infrastructure**

### **Step 10: Create ECR Repositories**

**Why ECR?** Container registry for Docker images.

**Create `ecr.tf`:**
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

# ECR Repository for Data Jobs
resource "aws_ecr_repository" "data_jobs" {
  name                 = "${var.environment}-data-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-data-jobs"
    Environment = var.environment
    Purpose     = "Data Processing Jobs"
  }
}

# ECR Repository for Glue Jobs
resource "aws_ecr_repository" "glue_jobs" {
  name                 = "${var.environment}-glue-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-glue-jobs"
    Environment = var.environment
    Purpose     = "Glue ETL Jobs"
  }
}
```

**Why These ECR Repositories?**
- **Image Scanning**: Vulnerability detection
- **Mutable Tags**: Flexible image management
- **Separate Repos**: Different purposes, different access
- **Cost Effective**: Pay per use

### **Step 11: Create ECS Cluster**

**Why ECS?** Serverless container orchestration.

**Create `ecs.tf`:**
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

# ECS Task Definition
resource "aws_ecs_task_definition" "data_processing_task" {
  family                   = "${var.environment}-data-processing-task"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 1024
  memory                  = 2048
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "data-processor"
      image = "${aws_ecr_repository.data_jobs.repository_url}:latest"

      environment = [
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.data_lake.bucket
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
    }
  ])

  tags = {
    Name        = "${var.environment}-data-processing-task"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "data_processing_service" {
  name            = "${var.environment}-data-processing-service"
  cluster         = aws_ecs_cluster.data_processing.id
  task_definition = aws_ecs_task_definition.data_processing_task.arn
  desired_count   = 0  # Start with 0, scale up as needed

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 1
  }

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  tags = {
    Name        = "${var.environment}-data-processing-service"
    Environment = var.environment
  }
}
```

**Why This ECS Configuration?**
- **Fargate Spot**: Up to 70% cost savings
- **Private Subnets**: More secure deployment
- **Desired Count 0**: Start empty, scale as needed
- **Task Definitions**: Reusable container specifications

---

## ☸️ **Phase 6: Kubernetes Infrastructure**

### **Step 12: Create Kubernetes Cluster**

**Why Kubernetes?** Container orchestration and GitOps.

**Create `kubernetes.tf`:**
```hcl
# Security Group for Kubernetes
resource "aws_security_group" "kubernetes" {
  name_prefix = "${var.environment}-k8s-"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort range for services
  ingress {
    from_port   = 30000
    to_port     = 32767
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
    Name        = "${var.environment}-k8s-sg"
    Environment = var.environment
    Purpose     = "Kubernetes Cluster"
  }
}

# Key Pair for SSH access
resource "aws_key_pair" "kubernetes" {
  key_name   = "${var.environment}-k8s-key"
  public_key = file("~/.ssh/oci_ed25519.pub")

  tags = {
    Name        = "${var.environment}-k8s-key"
    Environment = var.environment
  }
}

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

  tags = {
    Name        = "${var.environment}-k8s-master"
    Environment = var.environment
    Purpose     = "Kubernetes Cluster (Minikube)"
  }
}
```

**Why This Kubernetes Setup?**
- **Minikube**: Local development cluster
- **t3.small**: Cost-effective instance
- **Public Subnet**: Internet access for downloads
- **User Data**: Automated setup

---

## 📊 **Phase 7: Monitoring Infrastructure**

### **Step 13: Create Monitoring Stack**

**Why Monitoring Last?** It needs other services to monitor.

**Create `monitoring.tf`:**
```hcl
# Security Group for Monitoring Stack
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.environment}-monitoring-"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Elasticsearch
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jaeger
  ingress {
    from_port   = 16686
    to_port     = 16686
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
    Name        = "${var.environment}-monitoring-sg"
    Environment = var.environment
    Purpose     = "Monitoring Stack"
  }
}

# EC2 Instance for Monitoring Stack
resource "aws_instance" "monitoring" {
  count = 1

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.small"  # 2 vCPU, 2GB RAM - enough for monitoring stack

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
        networks:
          - monitoring

      grafana:
        image: grafana/grafana:latest
        container_name: grafana
        ports:
          - "3000:3000"
        volumes:
          - grafana_data:/var/lib/grafana
        environment:
          - GF_SECURITY_ADMIN_PASSWORD=admin123
        networks:
          - monitoring

      elasticsearch:
        image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
        container_name: elasticsearch
        ports:
          - "9200:9200"
        environment:
          - discovery.type=single-node
          - xpack.security.enabled=false
          - "ES_JAVA_OPTS=-Xms256m -Xmx256m"
        volumes:
          - elasticsearch_data:/usr/share/elasticsearch/data
        networks:
          - monitoring

      kibana:
        image: docker.elastic.co/kibana/kibana:8.11.0
        container_name: kibana
        ports:
          - "5601:5601"
        environment:
          - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
        depends_on:
          - elasticsearch
        networks:
          - monitoring

      jaeger:
        image: jaegertracing/all-in-one:latest
        container_name: jaeger
        ports:
          - "16686:16686"
        environment:
          - COLLECTOR_OTLP_ENABLED=true
        networks:
          - monitoring

    volumes:
      prometheus_data:
      grafana_data:
      elasticsearch_data:
    COMPOSE_EOF

    # Start monitoring stack
    docker-compose up -d
  EOF
  )

  tags = {
    Name        = "${var.environment}-monitoring-instance"
    Environment = var.environment
    Purpose     = "Monitoring Stack Host"
  }
}
```

**Why This Monitoring Setup?**
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **ELK Stack**: Log management
- **Jaeger**: Distributed tracing
- **Docker Compose**: Easy management

---

## 🔐 **Phase 8: Secrets Management**

### **Step 14: Create Secrets Manager**

**Why Secrets Manager?** Secure credential storage.

**Create `secrets-manager.tf`:**
```hcl
# Random password generation
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

resource "aws_secretsmanager_secret_version" "mysql_credentials" {
  count = length(aws_secretsmanager_secret.mysql_credentials)

  secret_id = aws_secretsmanager_secret.mysql_credentials[0].id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.mysql_password.result
    engine   = "mysql"
    host     = "mysql-host-placeholder"
    port     = 3306
    dbname   = "mydb"
  })
}

# Grafana Admin Secret
resource "aws_secretsmanager_secret" "grafana_credentials" {
  count = 1

  name                    = "${var.environment}-grafana-credentials"
  description             = "Grafana admin credentials for ${var.environment}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.environment}-grafana-credentials"
    Environment = var.environment
    Service     = "Grafana"
  }
}

resource "aws_secretsmanager_secret_version" "grafana_credentials" {
  count = length(aws_secretsmanager_secret.grafana_credentials)

  secret_id = aws_secretsmanager_secret.grafana_credentials[0].id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana_password.result
    url      = "http://${aws_instance.monitoring[0].public_ip}:3000"
  })
}
```

**Why This Secrets Setup?**
- **Random Passwords**: Secure, unique credentials
- **JSON Format**: Structured secret storage
- **Recovery Window**: 7-day deletion delay
- **Service-Specific**: Different secrets for different services

---

## 📤 **Phase 9: Outputs and Finalization**

### **Step 15: Create Outputs**

**Why Outputs?** Easy access to resource information.

**Create `outputs.tf`:**
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

# Security Group Outputs
output "security_group_ids" {
  description = "IDs of the security groups"
  value = {
    web      = aws_security_group.web.id
    database = aws_security_group.database.id
    app      = aws_security_group.app.id
    kubernetes = aws_security_group.kubernetes.id
    monitoring = aws_security_group.monitoring.id
  }
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    spark_apps = aws_ecr_repository.spark_apps.repository_url
    data_jobs  = aws_ecr_repository.data_jobs.repository_url
    glue_jobs  = aws_ecr_repository.glue_jobs.repository_url
  }
}

# S3 Data Lake Outputs
output "data_lake_bucket_name" {
  description = "Name of the main data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.data_processing.name
}

# Kubernetes Outputs
output "kubernetes_instance_id" {
  description = "ID of the Kubernetes EC2 instance"
  value       = aws_instance.kubernetes[0].id
}

output "kubernetes_public_ip" {
  description = "Public IP of the Kubernetes instance"
  value       = aws_instance.kubernetes[0].public_ip
}

output "kubernetes_ssh_command" {
  description = "SSH command to connect to Kubernetes instance"
  value       = "ssh -i ~/.ssh/oci_ed25519 ec2-user@${aws_instance.kubernetes[0].public_ip}"
}

# Monitoring Outputs
output "monitoring_instance_id" {
  description = "ID of the monitoring EC2 instance"
  value       = aws_instance.monitoring[0].id
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = aws_instance.monitoring[0].public_ip
}

output "monitoring_urls" {
  description = "URLs for monitoring services"
  value = {
    prometheus = "http://${aws_instance.monitoring[0].public_ip}:9090"
    grafana    = "http://${aws_instance.monitoring[0].public_ip}:3000 (admin/admin123)"
    kibana     = "http://${aws_instance.monitoring[0].public_ip}:5601"
    jaeger     = "http://${aws_instance.monitoring[0].public_ip}:16686"
  }
}

# Secrets Manager Outputs
output "secrets_manager_arns" {
  description = "ARNs of the secrets in AWS Secrets Manager"
  value = {
    mysql_credentials = aws_secretsmanager_secret.mysql_credentials[0].arn
    grafana_credentials = aws_secretsmanager_secret.grafana_credentials[0].arn
  }
}
```

**Why These Outputs?**
- **Resource Discovery**: Easy access to resource IDs
- **Integration**: Other modules can use these values
- **Documentation**: Self-documenting infrastructure
- **Automation**: Scripts can use these values

---

## 🚀 **Deployment Process**

### **Step 16: Deploy Infrastructure**

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Get outputs
terraform output
```

### **Step 17: Verify Deployment**

```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev"

# Check S3 buckets
aws s3 ls

# Check ECR repositories
aws ecr describe-repositories

# Check ECS cluster
aws ecs describe-clusters --clusters dev-data-processing-cluster

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"
```

---

## 🎯 **Why This Order?**

### **1. Foundation First (VPC, Subnets, Routes)**
- **Dependency**: Everything else needs network connectivity
- **Security**: Establishes network boundaries
- **Scalability**: Provides room for growth

### **2. Security Second (Security Groups, IAM)**
- **Dependency**: Services need security rules
- **Best Practice**: Security by design
- **Compliance**: Meets security requirements

### **3. Storage Third (S3, Glue)**
- **Dependency**: Data infrastructure needs network
- **Foundation**: Data is the core of data engineering
- **Integration**: Other services will use this data

### **4. Compute Fourth (ECR, ECS, Kubernetes)**
- **Dependency**: Needs network and security
- **Purpose**: Runs applications and processes data
- **Flexibility**: Multiple compute options

### **5. Monitoring Last (Prometheus, Grafana, ELK)**
- **Dependency**: Needs other services to monitor
- **Purpose**: Observability and troubleshooting
- **Value**: Provides insights into system health

---

## 📚 **Key Learnings**

### **Terraform Best Practices**
1. **Modular Structure**: Separate files by service
2. **Variables**: Use variables for reusability
3. **Outputs**: Expose important resource information
4. **Tags**: Consistent tagging for organization
5. **State Management**: Use remote state for teams

### **AWS Best Practices**
1. **Security First**: Least privilege access
2. **Cost Optimization**: Right-size resources
3. **High Availability**: Multi-AZ deployment
4. **Monitoring**: Comprehensive observability
5. **Documentation**: Clear resource documentation

### **Infrastructure as Code**
1. **Version Control**: Track all changes
2. **Testing**: Validate before deployment
3. **Documentation**: Explain the why, not just the what
4. **Automation**: Reduce manual processes
5. **Collaboration**: Team-friendly practices

---

**This tutorial provides a complete foundation for building AWS infrastructure with Terraform!** 🎉

**Next Steps:**
1. **Customize**: Adapt to your specific needs
2. **Extend**: Add more services as needed
3. **Optimize**: Improve based on usage patterns
4. **Scale**: Handle increased load and complexity
5. **Monitor**: Track performance and costs
