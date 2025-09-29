# AWS Infrastructure Access Guide

## 🚀 **Complete Access Guide for Deployed Infrastructure**

This guide provides all the commands, URLs, and access methods for your deployed AWS infrastructure with k3s and monitoring stack.

---

## 📋 **Quick Reference**

### **Infrastructure Overview**
- **EC2-1 (Monitoring)**: Docker Compose stack (Prometheus, Grafana, ELK, Jaeger)
- **EC2-2 (k3s)**: Kubernetes cluster with ArgoCD
- **VPC**: Multi-AZ network with public/private subnets
- **S3**: Data lake with versioning and encryption
- **ECR**: Container registries for images
- **ECS**: Serverless container orchestration (Fargate Spot)

---

## 🔑 **SSH Access Commands**

### **Get Instance Information**
```bash
# Get all outputs
terraform output

# Get specific IPs
terraform output monitoring_public_ip
terraform output kubernetes_public_ip

# Get SSH commands
terraform output monitoring_ssh_command
terraform output kubernetes_ssh_command
```

### **SSH to Monitoring Instance (EC2-1)**
```bash
# SSH command
ssh -i ~/.ssh/terraform-key.pem ec2-user@<MONITORING_IP>

# Check monitoring stack status
docker-compose -f /opt/monitoring/docker-compose.yml ps

# View logs
docker-compose -f /opt/monitoring/docker-compose.yml logs
```

### **SSH to Kubernetes Instance (EC2-2)**
```bash
# SSH command
ssh -i ~/.ssh/terraform-key.pem ec2-user@<K3S_IP>

# Check k3s status
sudo systemctl status k3s

# Check ArgoCD pods
kubectl get pods -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 🌐 **Service URLs and Access**

### **Monitoring Services (EC2-1)**
| **Service** | **URL** | **Credentials** | **Purpose** |
|-------------|---------|-----------------|-------------|
| **Prometheus** | `http://<MONITORING_IP>:9090` | None | Metrics collection |
| **Grafana** | `http://<MONITORING_IP>:3000` | admin / admin123 | Dashboards |
| **Kibana** | `http://<MONITORING_IP>:5601` | None | Log analysis |
| **Jaeger** | `http://<MONITORING_IP>:16686` | None | Distributed tracing |

### **Kubernetes Services (EC2-2)**
| **Service** | **URL** | **Access Method** | **Purpose** |
|-------------|---------|-------------------|-------------|
| **ArgoCD Web UI** | `https://localhost:8080` | SSH tunnel required | GitOps management |
| **k3s Dashboard** | `kubectl proxy` | SSH required | Kubernetes management |

---

## 🔧 **ArgoCD Access (SSH Tunnel Method)**

### **Step 1: SSH to k3s Instance**
```bash
# SSH to k3s instance
ssh -i ~/.ssh/terraform-key.pem ec2-user@<K3S_IP>

# Port forward ArgoCD service
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### **Step 2: Create SSH Tunnel (from your local machine)**
```bash
# In a new terminal on your local machine
ssh -i ~/.ssh/terraform-key.pem -L 8080:localhost:8080 ec2-user@<K3S_IP>
```

### **Step 3: Access ArgoCD**
- **URL**: `https://localhost:8080`
- **Username**: `admin`
- **Password**: Get it by running: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

---

## 📦 **Kubernetes Commands**

### **Basic k3s Commands**
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check k3s service
sudo systemctl status k3s
sudo systemctl restart k3s

# View k3s logs
sudo journalctl -u k3s -f
```

### **ArgoCD Commands**
```bash
# Port forward ArgoCD (run on k3s instance)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD CLI
argocd login localhost:8080 --username admin --password <PASSWORD>

# List applications
argocd app list

# Create application
argocd app create my-app \
  --repo https://github.com/your-org/your-repo \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync application
argocd app sync my-app
```

### **Helm Commands**
```bash
# List Helm repositories
helm repo list

# Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install chart
helm install my-app bitnami/nginx

# List releases
helm list

# Upgrade release
helm upgrade my-app bitnami/nginx
```

---

## 🐳 **Docker Commands**

### **Monitoring Stack (EC2-1)**
```bash
# Check container status
docker ps

# View logs
docker logs prometheus
docker logs grafana
docker logs elasticsearch
docker logs kibana
docker logs jaeger

# Restart services
docker-compose -f /opt/monitoring/docker-compose.yml restart

# Stop services
docker-compose -f /opt/monitoring/docker-compose.yml down

# Start services
docker-compose -f /opt/monitoring/docker-compose.yml up -d
```

---

## 🗄️ **S3 Data Lake Commands**

### **S3 Operations**
```bash
# Get bucket name
terraform output data_lake_bucket_name

# List bucket contents
aws s3 ls s3://<BUCKET_NAME>/

# Upload file
aws s3 cp local-file.txt s3://<BUCKET_NAME>/raw/

# Download file
aws s3 cp s3://<BUCKET_NAME>/raw/local-file.txt ./

# Sync directory
aws s3 sync ./local-dir/ s3://<BUCKET_NAME>/raw/
```

### **S3 Bucket Structure**
```
s3://<BUCKET_NAME>/
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

---

## 🐳 **ECR Container Registry Commands**

### **ECR Operations**
```bash
# Get ECR repository URLs
terraform output ecr_repository_urls

# Login to ECR
aws ecr get-login-password --region us-east-2 | \
docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com

# Build and tag image
docker build -t my-app:latest .
docker tag my-app:latest <ECR_URL>:latest

# Push to ECR
docker push <ECR_URL>:latest

# Pull from ECR
docker pull <ECR_URL>:latest
```

---

## 🚀 **ECS Commands**

### **ECS Operations**
```bash
# List clusters
aws ecs list-clusters

# List services
aws ecs list-services --cluster <CLUSTER_NAME>

# Update service
aws ecs update-service \
  --cluster <CLUSTER_NAME> \
  --service <SERVICE_NAME> \
  --desired-count 1

# Stop service
aws ecs update-service \
  --cluster <CLUSTER_NAME> \
  --service <SERVICE_NAME> \
  --desired-count 0
```

---

## 🔐 **Secrets Manager Commands**

### **Retrieve Secrets**
```bash
# Get secret ARNs
terraform output secrets_manager_arns

# Retrieve specific secret
aws secretsmanager get-secret-value \
  --secret-id <SECRET_NAME> \
  --query SecretString --output text | jq .

# Get all secrets
terraform output secrets_retrieval_commands
```

---

## 📊 **Monitoring Commands**

### **Prometheus Queries**
```bash
# Access Prometheus
curl http://<MONITORING_IP>:9090/api/v1/query?query=up

# Check targets
curl http://<MONITORING_IP>:9090/api/v1/targets
```

### **Grafana Operations**
```bash
# Access Grafana
curl -u admin:admin123 http://<MONITORING_IP>:3000/api/health

# Import dashboard (via API)
curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:admin123 \
  -d @dashboard.json \
  http://<MONITORING_IP>:3000/api/dashboards/db
```

---

## 🔧 **Troubleshooting Commands**

### **Network Troubleshooting**
```bash
# Test connectivity
ping <INSTANCE_IP>
telnet <INSTANCE_IP> 22
curl http://<INSTANCE_IP>:9090

# Check security groups
aws ec2 describe-security-groups --group-ids <SG_ID>

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<VPC_ID>"
```

### **Kubernetes Troubleshooting**
```bash
# Check pod logs
kubectl logs <POD_NAME> -n <NAMESPACE>

# Describe pod
kubectl describe pod <POD_NAME> -n <NAMESPACE>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node resources
kubectl top nodes
kubectl top pods
```

### **Docker Troubleshooting**
```bash
# Check container logs
docker logs <CONTAINER_NAME>

# Inspect container
docker inspect <CONTAINER_NAME>

# Check resource usage
docker stats

# Clean up
docker system prune -a
```

---

## 🚀 **Quick Start Workflows**

### **1. Deploy Infrastructure**
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### **2. Access All Services**
```bash
# Get all outputs
terraform output

# SSH to monitoring
ssh -i ~/.ssh/terraform-key.pem ec2-user@<MONITORING_IP>

# SSH to k3s
ssh -i ~/.ssh/terraform-key.pem ec2-user@<K3S_IP>
```

### **3. Deploy Application with ArgoCD**
```bash
# SSH to k3s instance
ssh -i ~/.ssh/terraform-key.pem ec2-user@<K3S_IP>

# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# In another terminal, create SSH tunnel
ssh -i ~/.ssh/terraform-key.pem -L 8080:localhost:8080 ec2-user@<K3S_IP>

# Access ArgoCD at https://localhost:8080
```

### **4. Monitor Applications**
```bash
# Access Grafana
open http://<MONITORING_IP>:3000

# Access Prometheus
open http://<MONITORING_IP>:9090

# Access Kibana
open http://<MONITORING_IP>:5601
```

---

## 📚 **Useful Scripts**

### **Status Check Script**
```bash
#!/bin/bash
echo "=== Infrastructure Status ==="
echo "Monitoring IP: $(terraform output -raw monitoring_public_ip)"
echo "K3s IP: $(terraform output -raw kubernetes_public_ip)"
echo ""
echo "=== Monitoring Services ==="
curl -s http://$(terraform output -raw monitoring_public_ip):9090/api/v1/query?query=up | jq .
echo ""
echo "=== K3s Status ==="
ssh -i ~/.ssh/terraform-key.pem ec2-user@$(terraform output -raw kubernetes_public_ip) "sudo systemctl status k3s --no-pager"
```

### **ArgoCD Access Script**
```bash
#!/bin/bash
K3S_IP=$(terraform output -raw kubernetes_public_ip)
echo "=== ArgoCD Access ==="
echo "1. SSH to k3s: ssh -i ~/.ssh/terraform-key.pem ec2-user@$K3S_IP"
echo "2. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "3. SSH tunnel: ssh -i ~/.ssh/terraform-key.pem -L 8080:localhost:8080 ec2-user@$K3S_IP"
echo "4. Access: https://localhost:8080"
echo "5. Password: $(ssh -i ~/.ssh/terraform-key.pem ec2-user@$K3S_IP "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d")"
```

---

## 🎯 **Next Steps**

### **Immediate Actions**
1. **Access Services**: Use the URLs and commands above
2. **Deploy Applications**: Use ArgoCD for GitOps deployments
3. **Monitor Infrastructure**: Set up Grafana dashboards
4. **Upload Data**: Start using the S3 data lake

### **Development Workflow**
1. **Build Applications**: Create containerized apps
2. **Push to ECR**: Store images in container registry
3. **Deploy to k3s**: Use ArgoCD for deployments
4. **Monitor**: Use Prometheus and Grafana

### **Production Readiness**
1. **Security**: Review security groups and IAM roles
2. **Backup**: Set up S3 lifecycle policies
3. **Monitoring**: Configure alerts and dashboards
4. **Scaling**: Set up auto-scaling policies

---

## 🆘 **Support and Resources**

### **Documentation**
- **Infrastructure Overview**: `documentation/infrastructure-overview.md`
- **Service Details**: `documentation/service-details.md`
- **Kubernetes Guide**: `documentation/kubernetes-argocd-guide.md`
- **Deployment Guide**: `documentation/deployment-guide.md`

### **Useful Commands**
```bash
# Get all outputs
terraform output

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
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/

---

**Your AWS infrastructure is now fully accessible and ready for development!** 🎉

**Key Benefits:**
- ✅ **Complete Access**: All services accessible with clear commands
- ✅ **Two-EC2 Architecture**: Monitoring and k3s on separate instances
- ✅ **SSH Tunneling**: Secure access to ArgoCD
- ✅ **Comprehensive Monitoring**: Prometheus, Grafana, ELK, Jaeger
- ✅ **GitOps Ready**: ArgoCD for declarative deployments
- ✅ **Production Ready**: Security, monitoring, and cost optimization

**Start building your applications today!** 🚀