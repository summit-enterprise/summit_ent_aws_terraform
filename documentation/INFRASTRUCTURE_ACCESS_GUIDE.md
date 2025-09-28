# 🚀 AWS Infrastructure Access Guide

## 📋 **Quick Reference**

### **Instance IPs**
- **Monitoring Instance:** `3.145.125.199`
- **Kubernetes Instance:** `18.118.197.25`

### **SSH Key Location**
- **Key File:** `~/.ssh/terraform-key.pem`
- **Permissions:** `chmod 600 ~/.ssh/terraform-key.pem`

---

## 🖥️ **SSH Access Commands**

### **Connect to Monitoring Instance**
```bash
ssh -i ~/.ssh/terraform-key.pem ec2-user@3.145.125.199
```

### **Connect to Kubernetes Instance**
```bash
ssh -i ~/.ssh/terraform-key.pem ec2-user@18.118.197.25
```

---

## 🌐 **Web Services Access**

### **Monitoring Services (IP: 3.145.125.199)**
- **Prometheus:** http://3.145.125.199:9090
- **Grafana:** http://3.145.125.199:3000 (admin/admin123)
- **Kibana:** http://3.145.125.199:5601
- **Jaeger:** http://3.145.125.199:16686

### **Kubernetes Services (IP: 18.118.197.25)**
- **ArgoCD:** http://18.118.197.25:30080
- **Minikube Dashboard:** Run `minikube dashboard --url` on the instance

---

## 🐳 **Kubernetes & Minikube Commands**

### **SSH into Kubernetes Instance First**
```bash
ssh -i ~/.ssh/terraform-key.pem ec2-user@18.118.197.25
```

### **Minikube Management**
```bash
# Check Minikube status
minikube status

# Start Minikube (if needed)
minikube start --driver=docker --memory=1800

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete

# Get Minikube dashboard URL
minikube dashboard --url

# Check cluster info
kubectl cluster-info
```

### **Kubernetes Cluster Commands**
```bash
# Get all nodes
kubectl get nodes

# Get all pods in all namespaces
kubectl get pods -A

# Get pods in specific namespace
kubectl get pods -n argocd

# Get services
kubectl get services -A

# Get namespaces
kubectl get namespaces
```

---

## 🚀 **ArgoCD Commands**

### **Get ArgoCD Admin Password**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### **ArgoCD CLI Commands**
```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD CLI
argocd login localhost:8080 --username admin --password <PASSWORD>

# List applications
argocd app list

# Get ArgoCD server info
argocd version
```

### **ArgoCD Web Access**
- **URL:** http://18.118.197.25:30080
- **Username:** admin
- **Password:** Get from the command above

---

## 📦 **Helm Commands**

### **Basic Helm Operations**
```bash
# List Helm repositories
helm repo list

# Add a repository
helm repo add <name> <url>
helm repo add argo https://argoproj.github.io/argo-helm

# Update repositories
helm repo update

# List installed charts
helm list -A

# Install a chart
helm install <name> <chart> --namespace <namespace>

# Uninstall a chart
helm uninstall <name> --namespace <namespace>
```

### **Example: Install Nginx**
```bash
# Add Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install Nginx
helm install nginx bitnami/nginx --namespace default

# Check status
kubectl get pods
kubectl get services
```

---

## 🗄️ **Storage & Data Lake**

### **S3 Data Lake**
- **Bucket Name:** `dev-data-lake-x56pxrmj`
- **Region:** us-east-2

### **ECR Repositories**
- **Spark Apps:** `184499164265.dkr.ecr.us-east-2.amazonaws.com/dev-spark-apps`
- **Data Jobs:** `184499164265.dkr.ecr.us-east-2.amazonaws.com/dev-data-jobs`

### **AWS CLI Commands**
```bash
# List S3 buckets
aws s3 ls

# Upload file to data lake
aws s3 cp local-file.csv s3://dev-data-lake-x56pxrmj/raw/

# List ECR repositories
aws ecr describe-repositories

# Login to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 184499164265.dkr.ecr.us-east-2.amazonaws.com
```

---

## 🔧 **Docker Commands**

### **On Kubernetes Instance**
```bash
# Check Docker status
sudo systemctl status docker

# List running containers
docker ps

# List all containers
docker ps -a

# Build and push to ECR
docker build -t my-app .
docker tag my-app:latest 184499164265.dkr.ecr.us-east-2.amazonaws.com/dev-spark-apps:latest
docker push 184499164265.dkr.ecr.us-east-2.amazonaws.com/dev-spark-apps:latest
```

---

## 📊 **Monitoring Commands**

### **On Monitoring Instance**
```bash
# Check Docker Compose services
cd /opt/monitoring
docker-compose ps

# View logs
docker-compose logs prometheus
docker-compose logs grafana
docker-compose logs elasticsearch
docker-compose logs kibana
docker-compose logs jaeger

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Start all services
docker-compose up -d
```

---

## 🛠️ **Troubleshooting Commands**

### **Check Instance Status**
```bash
# Check if instances are running
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table

# Check security groups
aws ec2 describe-security-groups --query 'SecurityGroups[].{Name:GroupName,Id:GroupId,Ingress:IpPermissions[].FromPort}' --output table
```

### **Kubernetes Troubleshooting**
```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top nodes
kubectl top pods
```

### **Minikube Troubleshooting**
```bash
# Check Minikube logs
minikube logs

# Reset Minikube
minikube delete
minikube start --driver=docker --memory=1800

# Check Minikube addons
minikube addons list
```

---

## 🚀 **Quick Start Workflows**

### **1. Deploy a Simple App to Kubernetes**
```bash
# SSH to Kubernetes instance
ssh -i ~/.ssh/terraform-key.pem ec2-user@18.118.197.25

# Create a simple deployment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# Get the service URL
kubectl get services
minikube service nginx --url
```

### **2. Set Up ArgoCD Application**
```bash
# SSH to Kubernetes instance
ssh -i ~/.ssh/terraform-key.pem ec2-user@18.118.197.25

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD CLI
argocd login localhost:8080 --username admin --password <PASSWORD>
```

### **3. Upload Data to S3**
```bash
# Upload a file to the data lake
aws s3 cp my-data.csv s3://dev-data-lake-x56pxrmj/raw/

# List files in data lake
aws s3 ls s3://dev-data-lake-x56pxrmj/raw/
```

---

## 📝 **Useful Aliases**

Add these to your `~/.bashrc` on the Kubernetes instance:

```bash
# Kubernetes aliases
alias k='kubectl'
alias m='minikube'
alias a='argocd'

# Docker aliases
alias d='docker'
alias dc='docker-compose'

# Quick access
alias pods='kubectl get pods -A'
alias services='kubectl get services -A'
alias nodes='kubectl get nodes'
```

---

## 🔐 **Security Notes**

- **SSH Key:** Keep `terraform-key.pem` secure and never commit to version control
- **ArgoCD Password:** Change the default password after first login
- **Firewall:** Security groups are configured for necessary ports only
- **Encryption:** S3 bucket and EBS volumes are encrypted

---

## 📞 **Support & Resources**

- **Terraform Cloud:** https://app.terraform.io/app/summit-enterprise/summit_ent_aws_terraform
- **AWS Console:** https://console.aws.amazon.com/
- **ArgoCD Docs:** https://argo-cd.readthedocs.io/
- **Kubernetes Docs:** https://kubernetes.io/docs/
- **Helm Docs:** https://helm.sh/docs/

---

**🎉 Your AWS infrastructure is ready for development and experimentation!**
