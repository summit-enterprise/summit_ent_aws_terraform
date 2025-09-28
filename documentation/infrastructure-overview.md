# AWS Data Engineering Infrastructure - Complete Overview

## 🏗️ **Infrastructure Architecture**

This Terraform configuration creates a comprehensive data engineering and application platform on AWS with the following components:

### **📊 Stack Summary:**
- **Environment**: Development/Production ready
- **Region**: us-east-2 (configurable)
- **Cost Optimized**: Uses Spot instances, Fargate Spot, and free monitoring
- **Security**: VPC isolation, security groups, IAM roles, Secrets Manager
- **Monitoring**: Prometheus, Grafana, ELK Stack, Jaeger
- **Orchestration**: ECS Fargate, Kubernetes (Minikube), ArgoCD
- **Data Platform**: S3 Data Lake, AWS Glue, ECR repositories

---

## 🔧 **Core Infrastructure Services**

### **1. VPC (Virtual Private Cloud)**
**File**: `vpc.tf`
**Purpose**: Network foundation for all services

**Terraform Configuration:**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # 10.0.0.0/16
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

**What it provides:**
- **Isolated Network**: 10.0.0.0/16 CIDR block
- **DNS Resolution**: Internal and external DNS support
- **Multi-AZ Setup**: Spans 2 availability zones (us-east-2a, us-east-2b)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (for load balancers, bastion hosts)
- **Private Subnets**: 10.0.10.0/24, 10.0.20.0/24 (for databases, applications)
- **Internet Gateway**: Routes traffic to/from the internet
- **Route Tables**: Separate routing for public/private subnets

**Security Features:**
- Network isolation from other AWS accounts
- Controlled internet access through IGW
- Private subnets have no direct internet access

---

### **2. Security Groups**
**File**: `security-groups.tf`
**Purpose**: Firewall rules for network security

**Configured Security Groups:**

#### **Web Security Group**
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Source**: 0.0.0.0/0 (internet)
- **Use**: Load balancers, web servers

#### **Database Security Group**
- **Ports**: 3306 (MySQL), 5432 (PostgreSQL), 6379 (Redis)
- **Source**: App security group only
- **Use**: RDS, ElastiCache

#### **App Security Group**
- **Ports**: 8080 (app), 3000 (Node.js), 5000 (Flask)
- **Source**: Web security group
- **Use**: Application servers, ECS tasks

#### **Bastion Security Group**
- **Ports**: 22 (SSH)
- **Source**: Your IP only
- **Use**: Secure access to private resources

#### **Kubernetes Security Group**
- **Ports**: 22 (SSH), 8443 (K8s API), 30000-32767 (NodePort)
- **Source**: 0.0.0.0/0
- **Use**: Minikube cluster access

#### **Monitoring Security Group**
- **Ports**: 9090 (Prometheus), 3000 (Grafana), 5601 (Kibana), 16686 (Jaeger)
- **Source**: 0.0.0.0/0
- **Use**: Monitoring stack access

---

### **3. IAM (Identity and Access Management)**
**File**: `iam.tf`
**Purpose**: Access control and permissions

**IAM Roles Created:**

#### **Glue Service Role**
- **Permissions**: S3 access, CloudWatch logs, Glue catalog
- **Use**: AWS Glue ETL jobs and crawlers
- **Policies**: Data lake access, Glue service permissions

#### **ECS Task Execution Role**
- **Permissions**: ECR access, CloudWatch logs, Secrets Manager
- **Use**: ECS tasks to pull images and write logs
- **Policies**: ECR read access, CloudWatch write access

#### **ECS Task Role**
- **Permissions**: S3 access, Secrets Manager, other AWS services
- **Use**: Application code running in ECS tasks
- **Policies**: Data lake access, secrets retrieval

**Security Features:**
- Least privilege access
- Service-specific roles
- No hardcoded credentials
- Secrets Manager integration

---

## 🗄️ **Data Platform Services**

### **4. S3 Data Lake**
**File**: `s3.tf`
**Purpose**: Centralized data storage and processing

**S3 Buckets Created:**

#### **Main Data Lake Bucket**
- **Structure**:
  - `raw/` - Unprocessed data
  - `processed/` - Cleaned and transformed data
  - `curated/` - Business-ready data
  - `logs/` - Access logs and audit trails
- **Features**: Versioning, encryption, lifecycle policies
- **Access**: Glue, ECS, and monitoring services

#### **Glue Scripts Bucket**
- **Purpose**: Store ETL scripts and job artifacts
- **Access**: Glue service role
- **Structure**: `scripts/`, `temp/`, `outputs/`

#### **Glue Outputs Bucket**
- **Purpose**: Store Glue job outputs and results
- **Access**: Glue service role
- **Features**: Separate from main data lake for organization

**Data Lake Benefits:**
- **Scalable Storage**: Unlimited capacity
- **Cost Effective**: Pay only for what you use
- **Durability**: 99.999999999% (11 9's)
- **Integration**: Works with all AWS analytics services

---

### **5. AWS Glue**
**File**: `glue.tf`
**Purpose**: Serverless ETL and data catalog

**Glue Components:**

#### **Data Catalog Database**
- **Name**: `{environment}_data_lake_catalog`
- **Purpose**: Metadata repository for data discovery
- **Tables**: Auto-created by crawlers

#### **Crawlers**
- **Raw Data Crawler**: Scans `s3://bucket/raw/`
- **Processed Data Crawler**: Scans `s3://bucket/processed/`
- **Schedule**: Disabled (on-demand only) to avoid charges
- **Output**: Creates/updates tables in Data Catalog

#### **ETL Jobs**
- **Data Processing Job**: Transforms raw data to processed
- **Data Quality Job**: Validates data quality and completeness
- **Configuration**: Python 3, 2 DPU max capacity
- **Timeout**: 60 minutes for processing, 30 minutes for quality

#### **Workflow & Trigger**
- **Workflow**: Orchestrates ETL pipeline
- **Trigger**: On-demand execution (cost optimized)
- **Sequence**: Processing job → Quality job

**Glue Benefits:**
- **Serverless**: No infrastructure management
- **Auto-scaling**: Handles varying data volumes
- **Schema Discovery**: Automatically detects data structure
- **Cost Effective**: Pay per DPU-hour used

---

### **6. ECR (Elastic Container Registry)**
**File**: `ecr.tf`
**Purpose**: Docker image storage and management

**ECR Repositories:**

#### **Spark Applications**
- **Name**: `{environment}-spark-apps`
- **Use**: Apache Spark applications and jobs
- **Images**: Custom Spark applications, data processing jobs

#### **Data Jobs**
- **Name**: `{environment}-data-jobs`
- **Use**: General data processing applications
- **Images**: ETL scripts, data transformation jobs

#### **Glue Jobs**
- **Name**: `{environment}-glue-jobs`
- **Use**: AWS Glue ETL job containers
- **Images**: Custom Glue job scripts and dependencies

**ECR Features:**
- **Image Scanning**: Vulnerability detection
- **Lifecycle Policies**: Automatic cleanup of old images
- **Encryption**: Images encrypted at rest
- **Cross-Region Replication**: Available if needed

---

## 🚀 **Compute Services**

### **7. ECS (Elastic Container Service)**
**File**: `ecs.tf`
**Purpose**: Container orchestration and management

**ECS Configuration:**

#### **Cluster**
- **Name**: `{environment}-data-processing-cluster`
- **Capacity Providers**: FARGATE, FARGATE_SPOT
- **Default Strategy**: FARGATE_SPOT (cost optimized)

#### **Task Definitions**

**Data Processing Task:**
- **CPU**: 1024 (1 vCPU)
- **Memory**: 2048 MB (2 GB)
- **Image**: Data jobs ECR repository
- **Environment Variables**: S3 bucket, environment name
- **Networking**: VPC, private subnets

**Spark Job Task:**
- **CPU**: 2048 (2 vCPU)
- **Memory**: 4096 MB (4 GB)
- **Image**: Spark apps ECR repository
- **Environment Variables**: S3 bucket, environment name
- **Networking**: VPC, private subnets

#### **ECS Service**
- **Desired Count**: 0 (scale as needed)
- **Capacity Provider**: FARGATE_SPOT
- **Networking**: Private subnets, app security group
- **Scaling**: Manual or auto-scaling based on demand

**ECS Benefits:**
- **Serverless**: No EC2 management
- **Cost Effective**: Fargate Spot pricing
- **Auto-scaling**: Scale based on demand
- **Integration**: Works with ALB, CloudWatch, Secrets Manager

---

### **8. Kubernetes (Minikube)**
**File**: `kubernetes.tf`
**Purpose**: Container orchestration and GitOps

**Kubernetes Setup:**

#### **EC2 Instance**
- **Type**: t3.small (2 vCPU, 2 GB RAM)
- **OS**: Amazon Linux 2
- **Storage**: 20 GB GP3 encrypted
- **Networking**: Public subnet, Kubernetes security group

#### **Minikube Installation**
- **Driver**: Docker
- **Resources**: 1536 MB RAM, 1 CPU (optimized for t3.small)
- **Add-ons**: Helm, ArgoCD

#### **ArgoCD Integration**
- **Namespace**: argocd
- **Service Type**: NodePort (30080)
- **Access**: Web UI and CLI
- **Purpose**: GitOps for Kubernetes deployments

**Kubernetes Benefits:**
- **Portable**: Works on any cloud or on-premises
- **GitOps**: ArgoCD for declarative deployments
- **Learning**: Great for understanding container orchestration
- **Cost Effective**: Single EC2 instance for development

---

## 📊 **Monitoring & Observability**

### **9. Monitoring Stack**
**File**: `monitoring.tf`
**Purpose**: Comprehensive monitoring and observability

**Monitoring Components:**

#### **Prometheus**
- **Port**: 9090
- **Purpose**: Metrics collection and storage
- **Targets**: Node exporter, cAdvisor, Pushgateway, CloudWatch exporter
- **Retention**: Configurable data retention

#### **Grafana**
- **Port**: 3000
- **Credentials**: admin / {generated password}
- **Purpose**: Metrics visualization and dashboards
- **Data Source**: Prometheus
- **Features**: Custom dashboards, alerting

#### **ELK Stack**

**Elasticsearch:**
- **Port**: 9200
- **Purpose**: Log storage and indexing
- **Memory**: 256 MB (optimized for t3.small)
- **Features**: Full-text search, aggregations

**Kibana:**
- **Port**: 5601
- **Purpose**: Log visualization and analysis
- **Data Source**: Elasticsearch
- **Features**: Dashboards, saved searches, alerts

**Logstash:**
- **Port**: 5044
- **Purpose**: Log processing and forwarding
- **Inputs**: S3 access logs, ECS logs, system logs
- **Outputs**: Elasticsearch

#### **Jaeger**
- **Port**: 16686
- **Purpose**: Distributed tracing
- **Features**: Request tracing, performance analysis
- **Integration**: Works with microservices

#### **Additional Tools**

**Prometheus Pushgateway:**
- **Port**: 9091
- **Purpose**: Custom metrics from batch jobs
- **Use**: Short-lived jobs, cron jobs

**CloudWatch Exporter:**
- **Port**: 9106
- **Purpose**: CloudWatch metrics to Prometheus
- **Metrics**: S3, Glue, ECS, EC2 metrics

**Node Exporter:**
- **Port**: 9100
- **Purpose**: System metrics (CPU, memory, disk)
- **Scope**: EC2 instance metrics

**cAdvisor:**
- **Port**: 8080
- **Purpose**: Container metrics
- **Scope**: Docker container performance

**Monitoring Benefits:**
- **Free Alternative**: No CloudWatch charges
- **Comprehensive**: Metrics, logs, traces
- **Self-hosted**: Full control over data
- **Integration**: Works with all AWS services

---

## 🔐 **Security & Secrets Management**

### **10. Secrets Manager**
**File**: `secrets-manager.tf`
**Purpose**: Secure secret storage and management

**Secrets Created:**

#### **Database Credentials**
- **MySQL**: Username, password, host, port, database
- **Redis**: Password, host, port
- **Encryption**: AWS KMS encryption at rest

#### **Application Credentials**
- **Grafana**: Admin username and password
- **ArgoCD**: Admin username and password
- **App Secrets**: JWT secrets, API keys, encryption keys

#### **Random Password Generation**
- **Length**: 16 characters
- **Characters**: Letters, numbers, special characters
- **Uniqueness**: Each secret gets unique password

**Security Features:**
- **Encryption**: All secrets encrypted with AWS KMS
- **Access Control**: IAM-based permissions
- **Audit Logging**: All access logged in CloudTrail
- **Rotation**: Can be configured for automatic rotation

---

## 🌐 **Network Architecture**

### **Network Flow:**
```
Internet → Internet Gateway → Public Subnets → Private Subnets
    ↓              ↓              ↓              ↓
Load Balancers  Bastion Hosts  Applications  Databases
    ↓              ↓              ↓              ↓
Web Security   SSH Access    App Security   Database Security
   Group          Group         Group          Group
```

### **Data Flow:**
```
Raw Data → S3 Data Lake → Glue Crawlers → Data Catalog
    ↓           ↓              ↓
Glue Jobs → Processed Data → ECS Tasks
    ↓           ↓              ↓
Quality Jobs → Curated Data → Applications
```

### **Monitoring Flow:**
```
Applications → Prometheus → Grafana
     ↓             ↓
System Logs → Logstash → Elasticsearch → Kibana
     ↓
Traces → Jaeger
```

---

## 💰 **Cost Optimization**

### **Cost-Saving Features:**
- **Fargate Spot**: Up to 70% savings on compute
- **t3.small Instances**: Right-sized for development
- **Disabled CloudWatch**: Free monitoring stack
- **On-demand Glue**: No scheduled jobs
- **GP3 Storage**: 20% cheaper than GP2
- **No Elastic IPs**: Use dynamic IPs where possible

### **Estimated Monthly Costs:**
- **VPC**: $0 (free)
- **S3**: ~$5-10 (depending on data volume)
- **ECR**: ~$1-2 (image storage)
- **ECS**: $0 (no running tasks by default)
- **EC2 (K8s)**: ~$15-20 (t3.small)
- **EC2 (Monitoring)**: ~$15-20 (t3.small)
- **Secrets Manager**: ~$2-5 (5 secrets)
- **Total**: ~$40-60/month (development)

---

## 🚀 **Deployment Process**

### **1. Environment Setup:**
```bash
# Set up environment variables
./setup-env.sh
nano .env
source load-env.sh
```

### **2. Deploy Infrastructure:**
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### **3. Access Services:**
```bash
# Get service URLs
terraform output

# SSH to Kubernetes
ssh -i ~/.ssh/oci_ed25519 ec2-user@<kubernetes-ip>

# Access monitoring
# Prometheus: http://<monitoring-ip>:9090
# Grafana: http://<monitoring-ip>:3000
# Kibana: http://<monitoring-ip>:5601
```

---

## 🔧 **Configuration Management**

### **Terraform Files Structure:**
```
├── main.tf              # Provider and backend
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── vpc.tf              # Network infrastructure
├── security-groups.tf  # Security rules
├── iam.tf              # Access control
├── s3.tf               # Data lake storage
├── glue.tf             # ETL services
├── ecr.tf              # Container registry
├── ecs.tf              # Container orchestration
├── kubernetes.tf       # K8s cluster
├── monitoring.tf       # Monitoring stack
├── secrets-manager.tf  # Secret management
└── examples/ec2.tf     # Database examples
```

### **Environment Variables:**
- **Template**: `env.template`
- **Active**: `.env` (gitignored)
- **Loader**: `load-env.sh`
- **Setup**: `setup-env.sh`

---

## 📚 **Documentation Files**

### **Comprehensive Guides:**
- **`INFRASTRUCTURE_OVERVIEW.md`** - This file (complete overview)
- **`SERVICE_DETAILS.md`** - Detailed service explanations
- **`TERRAFORM_CONFIGURATION.md`** - Terraform setup details
- **`ARCHITECTURE_DIAGRAM.md`** - Visual architecture
- **`DEPLOYMENT_GUIDE.md`** - Step-by-step deployment
- **`TROUBLESHOOTING.md`** - Common issues and solutions

---

**This infrastructure provides a complete, production-ready data engineering platform with monitoring, security, and cost optimization built-in!** 🎉
