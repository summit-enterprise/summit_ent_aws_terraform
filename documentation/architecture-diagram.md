# AWS Infrastructure Architecture Diagram

## 🏗️ **Visual Architecture Overview**

This document provides visual representations of your AWS infrastructure architecture using ASCII diagrams and Mermaid diagrams.

---

## 🌐 **Network Architecture**

### **VPC Layout**
```
┌─────────────────────────────────────────────────────────────────┐
│                        VPC: 10.0.0.0/16                        │
│                    Environment: ${var.environment}              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Internet Gateway (IGW)                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Public Subnets                              │
│  ┌─────────────────────┐    ┌─────────────────────┐           │
│  │   us-east-2a        │    │   us-east-2b        │           │
│  │   10.0.1.0/24       │    │   10.0.2.0/24       │           │
│  │                     │    │                     │           │
│  │ • Load Balancers    │    │ • Load Balancers    │           │
│  │ • Bastion Hosts     │    │ • Bastion Hosts     │           │
│  │ • Kubernetes (K8s)  │    │ • Monitoring        │           │
│  │ • NAT Gateway       │    │ • NAT Gateway       │           │
│  └─────────────────────┘    └─────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Private Subnets                             │
│  ┌─────────────────────┐    ┌─────────────────────┐           │
│  │   us-east-2a        │    │   us-east-2b        │           │
│  │   10.0.10.0/24      │    │   10.0.20.0/24      │           │
│  │                     │    │                     │           │
│  │ • Application       │    │ • Application       │           │
│  │   Servers           │    │   Servers           │           │
│  │ • ECS Tasks         │    │ • ECS Tasks         │           │
│  │ • Databases         │    │ • Databases         │           │
│  │ • Cache Clusters    │    │ • Cache Clusters    │           │
│  └─────────────────────┘    └─────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔒 **Security Groups Architecture**

### **Security Group Relationships**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Security Groups                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web SG        │    │   App SG        │    │  Database SG    │
│                 │    │                 │    │                 │
│ • Port 80       │───▶│ • Port 8080     │───▶│ • Port 3306     │
│ • Port 443      │    │ • Port 3000     │    │ • Port 5432     │
│ • Source: 0.0.0.0│    │ • Port 5000     │    │ • Port 6379     │
│                 │    │ • Source: Web   │    │ • Source: App   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Bastion SG     │    │ Kubernetes SG   │    │ Monitoring SG   │
│                 │    │                 │    │                 │
│ • Port 22       │    │ • Port 22       │    │ • Port 9090     │
│ • Source: Your  │    │ • Port 8443     │    │ • Port 3000     │
│   IP Only       │    │ • Port 30000-   │    │ • Port 5601     │
│                 │    │   32767         │    │ • Port 16686    │
│                 │    │ • Source: 0.0.0.0│    │ • Source: 0.0.0.0│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🗄️ **Data Platform Architecture**

### **S3 Data Lake Structure**
```
┌─────────────────────────────────────────────────────────────────┐
│                    S3 Data Lake                                │
│              ${environment}-data-lake-{random}                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        Raw Data                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   logs/     │  │  events/    │  │   feeds/    │            │
│  │             │  │             │  │             │            │
│  │ • Access    │  │ • User      │  │ • External  │            │
│  │   Logs      │  │   Events    │  │   APIs      │            │
│  │ • System    │  │ • Clicks    │  │ • Feeds     │            │
│  │   Logs      │  │ • Views     │  │ • Files     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Glue Crawlers                               │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Raw Data        │              │ Processed Data  │          │
│  │ Crawler         │              │ Crawler         │          │
│  │                 │              │                 │          │
│  │ • Scans raw/    │              │ • Scans         │          │
│  │ • Creates       │              │   processed/    │          │
│  │   tables        │              │ • Updates       │          │
│  │ • Updates       │              │   tables        │          │
│  │   schema        │              │ • Validates     │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Data Catalog                                │
│              ${environment}_data_lake_catalog                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Raw Tables      │  │ Processed       │  │ Curated         │ │
│  │                 │  │ Tables          │  │ Tables          │ │
│  │ • logs_table    │  │ • daily_agg     │  │ • analytics     │ │
│  │ • events_table  │  │ • hourly_agg    │  │ • reporting     │ │
│  │ • feeds_table   │  │ • realtime_agg  │  │ • ml_datasets   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Processed Data                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  daily/     │  │  hourly/    │  │ real-time/  │            │
│  │             │  │             │  │             │            │
│  │ • Daily     │  │ • Hourly    │  │ • Real-time │            │
│  │   Aggs      │  │   Aggs      │  │   Streams   │            │
│  │ • Reports   │  │ • Metrics   │  │ • Alerts    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Curated Data                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ analytics/  │  │ reporting/  │  │    ml/      │            │
│  │             │  │             │  │             │            │
│  │ • Business  │  │ • Dashboards│  │ • Training  │            │
│  │   Metrics   │  │ • Reports   │  │   Data      │            │
│  │ • KPIs      │  │ • Exports   │  │ • Models    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 **ETL Pipeline Architecture**

### **AWS Glue ETL Process**
```
┌─────────────────────────────────────────────────────────────────┐
│                    ETL Pipeline                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Raw Data      │    │   Glue Jobs     │    │ Processed Data  │
│                 │    │                 │    │                 │
│ • S3 Raw/       │───▶│ • Data          │───▶│ • S3 Processed/ │
│ • Various       │    │   Processing    │    │ • Cleaned       │
│   Formats       │    │   Job           │    │   Data          │
│ • Unstructured  │    │                 │    │ • Structured    │
│                 │    │ • Python 3      │    │ • Validated     │
│                 │    │ • 2 DPU         │    │                 │
│                 │    │ • 60 min        │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Crawlers      │    │   Workflow      │    │ Quality Jobs    │
│                 │    │                 │    │                 │
│ • Schema        │    │ • Orchestration│    │ • Data          │
│   Discovery     │    │ • Dependencies  │    │   Validation    │
│ • Table         │    │ • Scheduling    │    │ • Quality       │
│   Creation      │    │ • Error         │    │   Checks        │
│ • Metadata      │    │   Handling      │    │ • Reports       │
│   Updates       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🚀 **Compute Architecture**

### **ECS Cluster Layout**
```
┌─────────────────────────────────────────────────────────────────┐
│                    ECS Cluster                                 │
│              ${environment}-data-processing-cluster            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                Capacity Providers                              │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ FARGATE_SPOT    │              │ FARGATE         │          │
│  │                 │              │                 │          │
│  │ • Up to 70%     │              │ • On-demand     │          │
│  │   Savings       │              │ • Reliable      │          │
│  │ • Interruptible │              │ • Guaranteed    │          │
│  │ • Cost          │              │ • Backup        │          │
│  │   Optimized     │              │                 │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Task Definitions                            │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Data Processing │              │ Spark Jobs      │          │
│  │ Task            │              │ Task            │          │
│  │                 │              │                 │          │
│  │ • 1 vCPU        │              │ • 2 vCPU        │          │
│  │ • 2 GB RAM      │              │ • 4 GB RAM      │          │
│  │ • Data Jobs     │              │ • Spark Apps    │          │
│  │   Image         │              │   Image         │          │
│  │ • S3 Access     │              │ • S3 Access     │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ECS Service                                 │
│              ${environment}-data-processing-service            │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Desired Count   │              │ Scaling         │          │
│  │                 │              │                 │          │
│  │ • 0 (Default)   │              │ • Manual        │          │
│  │ • Scale as      │              │ • Auto-scaling  │          │
│  │   Needed        │              │ • Based on      │          │
│  │                 │              │   Demand        │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## ☸️ **Kubernetes Architecture**

### **Minikube Cluster Layout**
```
┌─────────────────────────────────────────────────────────────────┐
│                    EC2 Instance                                │
│                    t3.small (2 vCPU, 2 GB)                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Minikube Cluster                            │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Docker          │              │ Kubernetes      │          │
│  │ Runtime         │              │ Control Plane   │          │
│  │                 │              │                 │          │
│  │ • Container     │              │ • API Server    │          │
│  │   Engine        │              │ • Scheduler     │          │
│  │ • Image         │              │ • Controller    │          │
│  │   Storage       │              │ • etcd          │          │
│  │ • Networking    │              │                 │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ArgoCD                                      │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ ArgoCD Server   │              │ GitOps          │          │
│  │                 │              │                 │          │
│  │ • Port 30080    │              │ • Git           │          │
│  │ • Web UI        │              │   Integration   │          │
│  │ • CLI Access    │              │ • Declarative   │          │
│  │ • Admin Panel   │              │   Deployments   │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 **Monitoring Architecture**

### **Monitoring Stack Layout**
```
┌─────────────────────────────────────────────────────────────────┐
│                    EC2 Instance                                │
│                    t3.small (2 vCPU, 2 GB)                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Docker Compose                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Prometheus      │  │ Grafana         │  │ Elasticsearch   │ │
│  │                 │  │                 │  │                 │ │
│  │ • Port 9090     │  │ • Port 3000     │  │ • Port 9200     │ │
│  │ • Metrics       │  │ • Dashboards    │  │ • Log Storage   │ │
│  │   Collection    │  │ • Visualization │  │ • Search        │ │
│  │ • Storage       │  │ • Alerting      │  │ • Indexing      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Kibana          │  │ Jaeger          │  │ Logstash        │ │
│  │                 │  │                 │  │                 │ │
│  │ • Port 5601     │  │ • Port 16686    │  │ • Port 5044     │ │
│  │ • Log           │  │ • Distributed   │  │ • Log           │ │
│  │   Visualization │  │   Tracing       │  │   Processing    │ │
│  │ • Search        │  │ • Performance   │  │ • Forwarding    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Additional Tools                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Node Exporter   │  │ cAdvisor        │  │ Pushgateway     │ │
│  │                 │  │                 │  │                 │ │
│  │ • Port 9100     │  │ • Port 8080     │  │ • Port 9091     │ │
│  │ • System        │  │ • Container     │  │ • Custom        │ │
│  │   Metrics       │  │   Metrics       │  │   Metrics       │ │
│  │ • CPU, Memory   │  │ • Performance   │  │ • Batch Jobs    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 **Security Architecture**

### **Secrets Manager Layout**
```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Secrets Manager                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Secrets                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ MySQL           │  │ Redis           │  │ Grafana         │ │
│  │ Credentials     │  │ Credentials     │  │ Credentials     │ │
│  │                 │  │                 │  │                 │ │
│  │ • Username      │  │ • Password      │  │ • Username      │ │
│  │ • Password      │  │ • Host          │  │ • Password      │ │
│  │ • Host          │  │ • Port          │  │ • URL           │ │
│  │ • Port          │  │ • Engine        │  │                 │ │
│  │ • Database      │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ ArgoCD          │  │ App Secrets     │  │ Random          │ │
│  │ Credentials     │  │                 │  │ Passwords       │ │
│  │                 │  │ • JWT Secret    │  │                 │ │
│  │ • Username      │  │ • API Key       │  │ • 16 Character  │ │
│  │ • Password      │  │ • Encryption    │  │ • Special       │ │
│  │ • URL           │  │   Key           │  │   Characters    │ │
│  │                 │  │ • Webhook       │  │ • Unique        │ │
│  │                 │  │   Secret        │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    IAM Access Control                          │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ ECS Task Role   │              │ Glue Service    │          │
│  │                 │              │ Role            │          │
│  │ • GetSecretValue│              │ • GetSecretValue│          │
│  │ • DescribeSecret│              │ • DescribeSecret│          │
│  │ • S3 Access     │              │ • S3 Access     │          │
│  │ • ECR Access    │              │ • Glue Access   │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 **Data Flow Architecture**

### **Complete Data Flow**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Data Flow                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Raw Data      │    │   S3 Data Lake  │    │   Glue ETL      │
│                 │    │                 │    │                 │
│ • External      │───▶│ • Raw/          │───▶│ • Crawlers      │
│   Sources       │    │ • Processed/    │    │ • Jobs          │
│ • APIs          │    │ • Curated/      │    │ • Workflows     │
│ • Files         │    │ • Logs/         │    │ • Quality       │
│ • Streams       │    │                 │    │   Checks        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ECS Tasks     │    │   Data Catalog  │    │   Applications  │
│                 │    │                 │    │                 │
│ • Data          │    │ • Tables        │    │ • Analytics     │
│   Processing    │    │ • Schema        │    │ • Reporting     │
│ • Spark Jobs    │    │ • Metadata      │    │ • ML Models     │
│ • ETL Scripts   │    │ • Discovery     │    │ • Dashboards    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Monitoring    │    │   Secrets       │    │   Kubernetes    │
│                 │    │   Manager       │    │                 │
│ • Prometheus    │    │ • Credentials   │    │ • ArgoCD        │
│ • Grafana       │    │ • Passwords     │    │ • GitOps        │
│ • ELK Stack     │    │ • API Keys      │    │ • Deployments   │
│ • Jaeger        │    │ • Encryption    │    │ • Scaling       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 💰 **Cost Architecture**

### **Cost Optimization Strategy**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Cost Optimization                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Compute Costs                               │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ ECS Fargate     │              │ EC2 Instances   │          │
│  │                 │              │                 │          │
│  │ • Fargate Spot  │              │ • t3.small      │          │
│  │   (70% savings) │              │   (Right-sized) │          │
│  │ • On-demand     │              │ • GP3 Storage   │          │
│  │   (Backup)      │              │   (20% savings) │          │
│  │ • Desired       │              │ • No Elastic    │          │
│  │   Count: 0      │              │   IPs           │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Service Costs                               │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ AWS Glue        │              │ Monitoring      │          │
│  │                 │              │                 │          │
│  │ • On-demand     │              │ • Self-hosted   │          │
│  │   (No schedule) │              │   (No CloudWatch│          │
│  │ • 2 DPU Max     │              │   charges)      │          │
│  │ • 60 min        │              │ • Free tools    │          │
│  │   Timeout       │              │ • Open source   │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Storage Costs                               │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ S3 Storage      │              │ ECR Storage     │          │
│  │                 │              │                 │          │
│  │ • Pay per use   │              │ • Pay per use   │          │
│  │ • Lifecycle     │              │ • Lifecycle     │          │
│  │   Policies      │              │   Policies      │          │
│  │ • Intelligent   │              │ • Image         │          │
│  │   Tiering       │              │   Scanning      │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 **Deployment Architecture**

### **Terraform Cloud Integration**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Terraform Cloud                             │
│              Organization: summit-enterprise                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    VCS Integration                             │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ GitHub          │              │ Terraform       │          │
│  │ Repository      │              │ Cloud           │          │
│  │                 │              │                 │          │
│  │ • Code          │              │ • State         │          │
│  │   Repository    │              │   Management    │          │
│  │ • Version       │              │ • Plan/Apply    │          │
│  │   Control       │              │ • Collaboration │          │
│  │ • Webhooks      │              │ • Security      │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Resources                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ VPC             │  │ S3 Data Lake    │  │ ECS Cluster     │ │
│  │                 │  │                 │  │                 │ │
│  │ • Subnets       │  │ • Buckets       │  │ • Tasks         │ │
│  │ • Security      │  │ • Encryption    │  │ • Services      │ │
│  │   Groups        │  │ • Versioning    │  │ • Scaling       │ │
│  │ • Gateways      │  │ • Lifecycle     │  │ • Monitoring    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Glue ETL        │  │ Kubernetes      │  │ Monitoring      │ │
│  │                 │  │                 │  │                 │ │
│  │ • Crawlers      │  │ • Minikube      │  │ • Prometheus    │ │
│  │ • Jobs          │  │ • ArgoCD        │  │ • Grafana       │ │
│  │ • Workflows     │  │ • GitOps        │  │ • ELK Stack     │ │
│  │ • Catalog       │  │ • Deployments   │  │ • Jaeger        │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 **Monitoring Flow Architecture**

### **Observability Stack**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Monitoring Flow                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Applications  │    │   System        │    │   Containers    │
│                 │    │   Resources     │    │                 │
│ • Custom        │    │ • EC2 Instances │    │ • Docker        │
│   Metrics       │    │ • CPU, Memory   │    │   Containers    │
│ • Business      │    │ • Disk, Network │    │ • Resource      │
│   Metrics       │    │ • Load          │    │   Usage         │
│ • Performance   │    │ • Performance   │    │ • Performance   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Prometheus                                  │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Metrics         │              │ Storage         │          │
│  │ Collection      │              │                 │          │
│  │                 │              │ • Time Series   │          │
│  │ • Scrape        │              │   Database      │          │
│  │   Targets       │              │ • Retention     │          │
│  │ • Rules         │              │ • Compression   │          │
│  │ • Alerts        │              │ • Queries       │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Grafana                                     │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Dashboards      │              │ Alerting        │          │
│  │                 │              │                 │          │
│  │ • Visualizations│              │ • Rules         │          │
│  │ • Queries       │              │ • Notifications │          │
│  │ • Panels        │              │ • Channels      │          │
│  │ • Variables     │              │ • Escalation    │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Log Management                              │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Logstash        │              │ Elasticsearch   │          │
│  │                 │              │                 │          │
│  │ • Log           │              │ • Log Storage   │          │
│  │   Processing    │              │ • Indexing      │          │
│  │ • Parsing       │              │ • Search        │          │
│  │ • Filtering     │              │ • Aggregations  │          │
│  │ • Forwarding    │              │ • Analytics     │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kibana                                      │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Log             │              │ Analytics       │          │
│  │ Visualization   │              │                 │          │
│  │                 │              │ • Discover      │          │
│  │ • Dashboards    │              │ • Visualize     │          │
│  │ • Searches      │              │ • Dashboard     │          │
│  │ • Filters       │              │ • Machine       │          │
│  │ • Alerts        │              │   Learning      │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 **Environment Management**

### **Environment Variables Flow**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Environment Management                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   env.template  │    │      .env       │    │  load-env.sh    │
│                 │    │                 │    │                 │
│ • Template      │    │ • Actual        │    │ • Loader        │
│   File          │    │   Values        │    │   Script        │
│ • Safe to       │    │ • Gitignored    │    │ • Validation    │
│   Commit        │    │ • Sensitive     │    │ • Error         │
│ • Documented    │    │   Data          │    │   Handling      │
│ • Examples      │    │ • Local Only    │    │ • Verification  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Terraform Variables                         │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ VPC Variables   │              │ Service         │          │
│  │                 │              │ Variables       │          │
│  │ • vpc_cidr      │              │                 │          │
│  │ • availability_ │              │ • environment   │          │
│  │   zones         │              │ • AWS_DEFAULT_  │          │
│  │ • subnet_cidrs  │              │   REGION        │          │
│  │ • public/       │              │ • instance_     │          │
│  │   private       │              │   types         │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📚 **Documentation Architecture**

### **Documentation Structure**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Documentation                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Core Documentation                          │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Infrastructure  │              │ Service         │          │
│  │ Overview        │              │ Details         │          │
│  │                 │              │                 │          │
│  │ • Complete      │              │ • Detailed      │          │
│  │   Overview      │              │   Explanations  │          │
│  │ • Architecture  │              │ • Terraform     │          │
│  │   Summary       │              │   Configuration │          │
│  │ • Cost          │              │ • Use Cases     │          │
│  │   Breakdown     │              │ • Benefits      │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Technical Documentation                     │
│  ┌─────────────────┐              ┌─────────────────┐          │
│  │ Terraform       │              │ Architecture    │          │
│  │ Configuration   │              │ Diagram         │          │
│  │                 │              │                 │          │
│  │ • File          │              │ • Visual        │          │
│  │   Structure     │              │   Diagrams      │          │
│  │ • Resource      │              │ • ASCII Art     │          │
│  │   Details       │              │ • Mermaid       │          │
│  │ • Best          │              │ • Flow Charts   │          │
│  │   Practices     │              │ • Network       │          │
│  └─────────────────┘              └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

**This architecture provides a complete, visual representation of your AWS infrastructure with all components, relationships, and data flows clearly documented!** 🎉
