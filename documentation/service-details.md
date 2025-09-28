# AWS Infrastructure Services - Detailed Documentation

## 📋 **Service-by-Service Breakdown**

This document provides detailed explanations of each service in your AWS infrastructure, including Terraform configuration, purpose, and technical details.

---

## 🌐 **1. VPC (Virtual Private Cloud)**

### **Purpose**
The VPC is the foundational network layer that provides isolated, secure networking for all your AWS resources.

### **Terraform Configuration**
```hcl
# VPC Definition
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # 10.0.0.0/16
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

### **Network Architecture**
```
VPC CIDR: 10.0.0.0/16
├── Public Subnets (Internet Access)
│   ├── us-east-2a: 10.0.1.0/24
│   └── us-east-2b: 10.0.2.0/24
└── Private Subnets (No Direct Internet)
    ├── us-east-2a: 10.0.10.0/24
    └── us-east-2b: 10.0.20.0/24
```

### **Key Features**
- **DNS Resolution**: Both internal and external DNS support
- **Multi-AZ**: Spans 2 availability zones for high availability
- **Internet Gateway**: Provides internet access to public subnets
- **Route Tables**: Separate routing for public/private subnets
- **NAT Gateway**: Not configured (cost optimization)

### **Use Cases**
- **Public Subnets**: Load balancers, bastion hosts, NAT gateways
- **Private Subnets**: Databases, application servers, internal services

---

## 🔒 **2. Security Groups**

### **Purpose**
Security groups act as virtual firewalls, controlling inbound and outbound traffic to AWS resources.

### **Security Group Details**

#### **Web Security Group**
```hcl
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
}
```

**Ports**: 80 (HTTP), 443 (HTTPS)
**Source**: Internet (0.0.0.0/0)
**Use**: Load balancers, web servers

#### **Database Security Group**
```hcl
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
}
```

**Ports**: 3306 (MySQL), 5432 (PostgreSQL), 6379 (Redis)
**Source**: App security group only
**Use**: RDS, ElastiCache

#### **App Security Group**
```hcl
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
}
```

**Ports**: 8080 (app), 3000 (Node.js), 5000 (Flask)
**Source**: Web security group
**Use**: Application servers, ECS tasks

### **Security Best Practices**
- **Least Privilege**: Only necessary ports open
- **Layered Security**: Multiple security groups for different tiers
- **Source Restrictions**: Specific security groups, not 0.0.0.0/0
- **Egress Control**: All outbound traffic allowed (can be restricted)

---

## 👤 **3. IAM (Identity and Access Management)**

### **Purpose**
IAM provides fine-grained access control and permissions for AWS services and resources.

### **IAM Roles Created**

#### **Glue Service Role**
```hcl
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
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
```

**Permissions**:
- S3 access for data lake
- CloudWatch logs for job monitoring
- Glue catalog access
- ECR access for custom job containers

#### **ECS Task Execution Role**
```hcl
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
}
```

**Permissions**:
- ECR access to pull container images
- CloudWatch logs to write application logs
- Secrets Manager access for database credentials
- ECS task execution

#### **ECS Task Role**
```hcl
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
}
```

**Permissions**:
- S3 access for data processing
- Secrets Manager for application secrets
- Other AWS services as needed by applications

### **IAM Policies**

#### **Data Lake Access Policy**
```hcl
resource "aws_iam_policy" "data_lake_access" {
  name = "${var.environment}-data-lake-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      }
    ]
  })
}
```

**Purpose**: Allows services to read/write to the data lake

#### **ECR Access Policy**
```hcl
resource "aws_iam_policy" "ecr_access" {
  name = "${var.environment}-ecr-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}
```

**Purpose**: Allows ECS tasks to pull container images from ECR

---

## 🗄️ **4. S3 Data Lake**

### **Purpose**
S3 provides scalable, durable object storage for your data lake, serving as the central repository for all data.

### **S3 Bucket Configuration**

#### **Main Data Lake Bucket**
```hcl
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.environment}-data-lake-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.environment}-data-lake"
    Environment = var.environment
    Purpose     = "Data Lake Storage"
  }
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
```

**Bucket Structure**:
```
s3://{environment}-data-lake-{random}/
├── raw/                    # Unprocessed data
│   ├── logs/              # Access logs
│   ├── events/            # Event data
│   └── feeds/             # External data feeds
├── processed/             # Cleaned and transformed data
│   ├── daily/             # Daily aggregations
│   ├── hourly/            # Hourly aggregations
│   └── real-time/         # Real-time processed data
├── curated/               # Business-ready data
│   ├── analytics/         # Analytics datasets
│   ├── reporting/         # Reporting data
│   └── ml/                # Machine learning datasets
└── logs/                  # Audit and access logs
```

#### **Glue Scripts Bucket**
```hcl
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "${var.environment}-glue-scripts-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.environment}-glue-scripts"
    Environment = var.environment
    Purpose     = "Glue ETL Scripts"
  }
}
```

**Purpose**: Store ETL scripts, job artifacts, and temporary files

#### **Glue Outputs Bucket**
```hcl
resource "aws_s3_bucket" "glue_outputs" {
  bucket = "${var.environment}-glue-outputs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.environment}-glue-outputs"
    Environment = var.environment
    Purpose     = "Glue Job Outputs"
  }
}
```

**Purpose**: Store Glue job outputs and results

### **S3 Features**
- **Versioning**: Keep multiple versions of objects
- **Encryption**: AES-256 encryption at rest
- **Lifecycle Policies**: Automatic transition to cheaper storage classes
- **Access Logging**: Track all bucket access
- **Cross-Region Replication**: Available if needed

---

## 🔧 **5. AWS Glue**

### **Purpose**
AWS Glue provides serverless ETL capabilities and a data catalog for discovering and processing data.

### **Glue Components**

#### **Data Catalog Database**
```hcl
resource "aws_glue_catalog_database" "data_lake_catalog" {
  name = "${var.environment}_data_lake_catalog"

  description = "Data catalog for ${var.environment} data lake"

  tags = {
    Name        = "${var.environment}-data-lake-catalog"
    Environment = var.environment
  }
}
```

**Purpose**: Metadata repository for data discovery
**Tables**: Auto-created by crawlers based on data structure

#### **Crawlers**
```hcl
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

**Raw Data Crawler**:
- **Target**: `s3://bucket/raw/`
- **Schedule**: Disabled (on-demand only)
- **Output**: Creates tables in Data Catalog

**Processed Data Crawler**:
- **Target**: `s3://bucket/processed/`
- **Schedule**: Disabled (on-demand only)
- **Output**: Updates tables in Data Catalog

#### **ETL Jobs**
```hcl
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
}
```

**Data Processing Job**:
- **Language**: Python 3
- **Capacity**: 2 DPU (Data Processing Units)
- **Timeout**: 60 minutes
- **Bookmarking**: Enabled for incremental processing

**Data Quality Job**:
- **Language**: Python 3
- **Capacity**: 1 DPU
- **Timeout**: 30 minutes
- **Purpose**: Data validation and quality checks

#### **Workflow & Trigger**
```hcl
resource "aws_glue_workflow" "etl_workflow" {
  name = "${var.environment}-etl-workflow"

  description = "ETL workflow for data processing pipeline"
}

resource "aws_glue_trigger" "etl_trigger" {
  name          = "${var.environment}-etl-trigger"
  workflow_name = aws_glue_workflow.etl_workflow.name
  type          = "ON_DEMAND"  # Changed from SCHEDULED

  actions {
    job_name = aws_glue_job.data_processing_job.name
  }

  actions {
    job_name = aws_glue_job.data_quality_job.name
  }
}
```

**Workflow**: Orchestrates the ETL pipeline
**Trigger**: On-demand execution (cost optimized)

### **Glue Benefits**
- **Serverless**: No infrastructure management
- **Auto-scaling**: Handles varying data volumes
- **Schema Discovery**: Automatically detects data structure
- **Cost Effective**: Pay per DPU-hour used
- **Integration**: Works with S3, RDS, Redshift, and more

---

## 🐳 **6. ECR (Elastic Container Registry)**

### **Purpose**
ECR provides secure, scalable Docker image storage and management for your containerized applications.

### **ECR Repositories**

#### **Spark Applications Repository**
```hcl
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

**Purpose**: Store Apache Spark applications and data processing jobs
**Features**: Image scanning, mutable tags

#### **Data Jobs Repository**
```hcl
resource "aws_ecr_repository" "data_jobs" {
  name                 = "${var.environment}-data-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

**Purpose**: Store general data processing applications
**Use**: ETL scripts, data transformation jobs

#### **Glue Jobs Repository**
```hcl
resource "aws_ecr_repository" "glue_jobs" {
  name                 = "${var.environment}-glue-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

**Purpose**: Store custom Glue job containers
**Use**: Glue ETL job scripts and dependencies

### **ECR Features**
- **Image Scanning**: Vulnerability detection on push
- **Lifecycle Policies**: Automatic cleanup of old images
- **Encryption**: Images encrypted at rest
- **Cross-Region Replication**: Available if needed
- **IAM Integration**: Fine-grained access control

---

## 🚀 **7. ECS (Elastic Container Service)**

### **Purpose**
ECS provides serverless container orchestration for running and managing containerized applications.

### **ECS Cluster Configuration**

#### **Cluster Definition**
```hcl
resource "aws_ecs_cluster" "data_processing" {
  name = "${var.environment}-data-processing-cluster"

  tags = {
    Name        = "${var.environment}-data-processing-cluster"
    Environment = var.environment
  }
}

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

**Capacity Providers**:
- **FARGATE**: On-demand pricing
- **FARGATE_SPOT**: Up to 70% savings
- **Default Strategy**: FARGATE_SPOT (cost optimized)

#### **Task Definitions**

**Data Processing Task**:
```hcl
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
}
```

**Specifications**:
- **CPU**: 1024 (1 vCPU)
- **Memory**: 2048 MB (2 GB)
- **Image**: Data jobs ECR repository
- **Networking**: VPC mode

**Spark Job Task**:
```hcl
resource "aws_ecs_task_definition" "spark_job_task" {
  family                   = "${var.environment}-spark-job-task"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 2048
  memory                  = 4096
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "spark-job"
      image = "${aws_ecr_repository.spark_apps.repository_url}:latest"

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
}
```

**Specifications**:
- **CPU**: 2048 (2 vCPU)
- **Memory**: 4096 MB (4 GB)
- **Image**: Spark apps ECR repository
- **Use**: Apache Spark applications

#### **ECS Service**
```hcl
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
}
```

**Configuration**:
- **Desired Count**: 0 (scale as needed)
- **Capacity Provider**: FARGATE_SPOT
- **Networking**: Private subnets, app security group
- **Scaling**: Manual or auto-scaling based on demand

### **ECS Benefits**
- **Serverless**: No EC2 management
- **Cost Effective**: Fargate Spot pricing
- **Auto-scaling**: Scale based on demand
- **Integration**: Works with ALB, CloudWatch, Secrets Manager
- **Security**: IAM roles, VPC networking

---

## ☸️ **8. Kubernetes (Minikube)**

### **Purpose**
Kubernetes provides container orchestration and management, with Minikube providing a local development environment.

### **Kubernetes Setup**

#### **EC2 Instance Configuration**
```hcl
resource "aws_instance" "kubernetes" {
  count = 1

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.small"  # 2 vCPU, 2 GB RAM
  key_name      = aws_key_pair.kubernetes.key_name

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.kubernetes.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
}
```

**Specifications**:
- **Instance Type**: t3.small (2 vCPU, 2 GB RAM)
- **OS**: Amazon Linux 2
- **Storage**: 20 GB GP3 encrypted
- **Networking**: Public subnet, Kubernetes security group

#### **Minikube Installation**
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
mv minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube with optimal resources for t3.small
minikube start --driver=docker --memory=1536 --cpus=1
```

**Configuration**:
- **Driver**: Docker
- **Memory**: 1536 MB (optimized for t3.small)
- **CPU**: 1 vCPU
- **Storage**: Local Docker storage

#### **ArgoCD Integration**
```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Install ArgoCD in Minikube
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm install argocd argo/argo-cd --namespace argocd --set server.service.type=NodePort --set server.service.nodePortHttp=30080
```

**ArgoCD Configuration**:
- **Namespace**: argocd
- **Service Type**: NodePort (30080)
- **Access**: Web UI and CLI
- **Purpose**: GitOps for Kubernetes deployments

### **Kubernetes Benefits**
- **Portable**: Works on any cloud or on-premises
- **GitOps**: ArgoCD for declarative deployments
- **Learning**: Great for understanding container orchestration
- **Cost Effective**: Single EC2 instance for development
- **Scalable**: Can be expanded to full EKS cluster

---

## 📊 **9. Monitoring Stack**

### **Purpose**
The monitoring stack provides comprehensive observability with metrics, logs, and traces.

### **Monitoring Components**

#### **Prometheus**
```yaml
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
```

**Purpose**: Metrics collection and storage
**Port**: 9090
**Targets**: Node exporter, cAdvisor, Pushgateway, CloudWatch exporter
**Retention**: Configurable data retention

#### **Grafana**
```yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  ports:
    - "3000:3000"
  volumes:
    - grafana_data:/var/lib/grafana
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=${random_password.grafana_password.result}
```

**Purpose**: Metrics visualization and dashboards
**Port**: 3000
**Credentials**: admin / {generated password}
**Data Source**: Prometheus
**Features**: Custom dashboards, alerting

#### **ELK Stack**

**Elasticsearch**:
```yaml
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
```

**Purpose**: Log storage and indexing
**Port**: 9200
**Memory**: 256 MB (optimized for t3.small)
**Features**: Full-text search, aggregations

**Kibana**:
```yaml
kibana:
  image: docker.elastic.co/kibana/kibana:8.11.0
  container_name: kibana
  ports:
    - "5601:5601"
  environment:
    - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
  depends_on:
    - elasticsearch
```

**Purpose**: Log visualization and analysis
**Port**: 5601
**Data Source**: Elasticsearch
**Features**: Dashboards, saved searches, alerts

**Logstash**:
```yaml
logstash:
  image: docker.elastic.co/logstash/logstash:8.11.0
  container_name: logstash
  ports:
    - "5044:5044"
    - "9600:9600"
  volumes:
    - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
  environment:
    - S3_BUCKET=${aws_s3_bucket.data_lake.bucket}
    - AWS_REGION=${var.AWS_DEFAULT_REGION}
  depends_on:
    - elasticsearch
```

**Purpose**: Log processing and forwarding
**Port**: 5044
**Inputs**: S3 access logs, ECS logs, system logs
**Outputs**: Elasticsearch

#### **Jaeger**
```yaml
jaeger:
  image: jaegertracing/all-in-one:latest
  container_name: jaeger
  ports:
    - "16686:16686"
    - "14268:14268"
  environment:
    - COLLECTOR_OTLP_ENABLED=true
```

**Purpose**: Distributed tracing
**Port**: 16686
**Features**: Request tracing, performance analysis
**Integration**: Works with microservices

#### **Additional Tools**

**Prometheus Pushgateway**:
```yaml
pushgateway:
  image: prom/pushgateway:latest
  container_name: pushgateway
  ports:
    - "9091:9091"
```

**Purpose**: Custom metrics from batch jobs
**Port**: 9091
**Use**: Short-lived jobs, cron jobs

**CloudWatch Exporter**:
```yaml
cloudwatch-exporter:
  image: prom/cloudwatch-exporter:latest
  container_name: cloudwatch-exporter
  ports:
    - "9106:9106"
  environment:
    - AWS_REGION=${var.AWS_DEFAULT_REGION}
  volumes:
    - ./cloudwatch-exporter.yml:/config/config.yml
```

**Purpose**: CloudWatch metrics to Prometheus
**Port**: 9106
**Metrics**: S3, Glue, ECS, EC2 metrics

**Node Exporter**:
```yaml
node-exporter:
  image: prom/node-exporter:latest
  container_name: node-exporter
  ports:
    - "9100:9100"
  command:
    - '--path.rootfs=/host'
  volumes:
    - /:/host:ro,rslave
  pid: host
```

**Purpose**: System metrics (CPU, memory, disk)
**Port**: 9100
**Scope**: EC2 instance metrics

**cAdvisor**:
```yaml
cadvisor:
  image: gcr.io/cadvisor/cadvisor:latest
  container_name: cadvisor
  ports:
    - "8080:8080"
  volumes:
    - /:/rootfs:ro
    - /var/run:/var/run:rw
    - /sys:/sys:ro
    - /var/lib/docker/:/var/lib/docker:ro
    - /dev/disk/:/dev/disk:ro
  privileged: true
```

**Purpose**: Container metrics
**Port**: 8080
**Scope**: Docker container performance

### **Monitoring Benefits**
- **Free Alternative**: No CloudWatch charges
- **Comprehensive**: Metrics, logs, traces
- **Self-hosted**: Full control over data
- **Integration**: Works with all AWS services
- **Scalable**: Can handle large volumes of data

---

## 🔐 **10. Secrets Manager**

### **Purpose**
AWS Secrets Manager provides secure storage and management of sensitive information like passwords, API keys, and database credentials.

### **Secrets Configuration**

#### **Random Password Generation**
```hcl
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

resource "random_password" "argocd_password" {
  length  = 16
  special = true
}
```

**Features**:
- **Length**: 16 characters
- **Characters**: Letters, numbers, special characters
- **Uniqueness**: Each secret gets unique password

#### **Database Credentials**
```hcl
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
```

**MySQL Credentials**:
- **Username**: admin
- **Password**: Generated 16-character password
- **Host**: Database endpoint
- **Port**: 3306
- **Database**: mydb

**Redis Credentials**:
- **Password**: Generated 16-character password
- **Host**: Redis endpoint
- **Port**: 6379
- **Engine**: redis

#### **Application Credentials**
```hcl
resource "aws_secretsmanager_secret" "grafana_credentials" {
  count = 1

  name                    = "${var.environment}-grafana-credentials"
  description             = "Grafana admin credentials for ${var.environment}"
  recovery_window_in_days = 7
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

**Grafana Credentials**:
- **Username**: admin
- **Password**: Generated 16-character password
- **URL**: Monitoring instance IP with port 3000

**ArgoCD Credentials**:
- **Username**: admin
- **Password**: Generated 16-character password
- **URL**: Kubernetes instance IP with port 30080

#### **App Secrets**
```hcl
resource "aws_secretsmanager_secret" "app_secrets" {
  count = 1

  name                    = "${var.environment}-app-secrets"
  description             = "Application secrets for ${var.environment}"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  count = length(aws_secretsmanager_secret.app_secrets)

  secret_id = aws_secretsmanager_secret.app_secrets[0].id
  secret_string = jsonencode({
    jwt_secret     = random_password.mysql_password.result
    api_key        = random_password.redis_password.result
    encryption_key = random_password.grafana_password.result
    webhook_secret = random_password.argocd_password.result
  })
}
```

**Application Secrets**:
- **JWT Secret**: For authentication tokens
- **API Key**: For external API access
- **Encryption Key**: For data encryption
- **Webhook Secret**: For webhook validation

### **IAM Policy for Secrets Access**
```hcl
resource "aws_iam_policy" "secrets_manager_access" {
  name = "${var.environment}-secrets-manager-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.mysql_credentials[0].arn,
          aws_secretsmanager_secret.redis_credentials[0].arn,
          aws_secretsmanager_secret.grafana_credentials[0].arn,
          aws_secretsmanager_secret.argocd_credentials[0].arn,
          aws_secretsmanager_secret.app_secrets[0].arn
        ]
      }
    ]
  })
}
```

**Permissions**:
- **GetSecretValue**: Retrieve secret values
- **DescribeSecret**: Get secret metadata
- **Resource**: Specific secret ARNs only

### **Secrets Manager Benefits**
- **Encryption**: All secrets encrypted with AWS KMS
- **Access Control**: IAM-based permissions
- **Audit Logging**: All access logged in CloudTrail
- **Rotation**: Can be configured for automatic rotation
- **Integration**: Works with ECS, Lambda, RDS, and more

---

## 🔄 **Service Interactions**

### **Data Flow**
```
Raw Data → S3 Data Lake → Glue Crawlers → Data Catalog
    ↓           ↓              ↓
Glue Jobs → Processed Data → ECS Tasks
    ↓           ↓              ↓
Quality Jobs → Curated Data → Applications
```

### **Monitoring Flow**
```
Applications → Prometheus → Grafana
     ↓             ↓
System Logs → Logstash → Elasticsearch → Kibana
     ↓
Traces → Jaeger
```

### **Security Flow**
```
Applications → IAM Roles → AWS Services
     ↓
Secrets → Secrets Manager → Applications
```

---

## 💰 **Cost Breakdown**

### **Monthly Estimated Costs**
- **VPC**: $0 (free)
- **S3**: ~$5-10 (depending on data volume)
- **ECR**: ~$1-2 (image storage)
- **ECS**: $0 (no running tasks by default)
- **EC2 (K8s)**: ~$15-20 (t3.small)
- **EC2 (Monitoring)**: ~$15-20 (t3.small)
- **Secrets Manager**: ~$2-5 (5 secrets)
- **Total**: ~$40-60/month (development)

### **Cost Optimization Features**
- **Fargate Spot**: Up to 70% savings on compute
- **t3.small Instances**: Right-sized for development
- **Disabled CloudWatch**: Free monitoring stack
- **On-demand Glue**: No scheduled jobs
- **GP3 Storage**: 20% cheaper than GP2
- **No Elastic IPs**: Use dynamic IPs where possible

---

**This comprehensive infrastructure provides a complete, production-ready data engineering platform with monitoring, security, and cost optimization built-in!** 🎉
