# Kubernetes + ArgoCD Setup Guide

## 🔑 **SSH Access to Kubernetes EC2**

### **1. Deploy the Infrastructure:**
```bash
terraform apply
```

### **2. Get SSH Command:**
```bash
terraform output kubernetes_ssh_command
```

### **3. SSH into the Instance:**
```bash
ssh -i ~/.ssh/oci_ed25519 ec2-user@<PUBLIC_IP>
```

### **4. Verify Kubernetes is Running:**
```bash
# Check Minikube status
minikube status

# Check kubectl access
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🚀 **ArgoCD Setup & Usage**

### **1. Access ArgoCD Web Interface:**
```bash
# Get ArgoCD URL
terraform output kubernetes_argocd_url

# Or get all ArgoCD info
terraform output kubernetes_argocd_ssh_access
```

**ArgoCD Web UI:** `http://<PUBLIC_IP>:30080`
- **Username:** `admin`
- **Password:** Get it by running the SSH command above

### **2. ArgoCD CLI Access:**

#### **Method 1: Direct SSH Access**
```bash
# SSH into the instance
ssh -i ~/.ssh/oci_ed25519 ec2-user@<PUBLIC_IP>

# Use ArgoCD CLI directly
argocd app list
argocd app create --help
```

#### **Method 2: Port Forward (from your local machine)**
```bash
# SSH with port forwarding
ssh -i ~/.ssh/oci_ed25519 -L 8080:localhost:8080 ec2-user@<PUBLIC_IP>

# In another terminal, login to ArgoCD
argocd login localhost:8080 --username admin --password <PASSWORD>
```

### **3. ArgoCD Management Commands:**

#### **List Applications:**
```bash
argocd app list
```

#### **Create an Application:**
```bash
# Create from Git repository
argocd app create my-app \
  --repo https://github.com/your-org/your-repo \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Create from Helm chart
argocd app create my-helm-app \
  --repo https://charts.bitnami.com/bitnami \
  --helm-chart nginx \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

#### **Sync Applications:**
```bash
# Sync specific app
argocd app sync my-app

# Sync all apps
argocd app sync --all
```

#### **Get Application Status:**
```bash
argocd app get my-app
```

## 📦 **Example Applications to Deploy**

### **1. Simple Nginx Application:**
```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# Check status
kubectl get services
```

### **2. ArgoCD Application from Git:**
```bash
# Create a sample app
argocd app create sample-app \
  --repo https://github.com/argoproj/argocd-example-apps \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync the app
argocd app sync sample-app
```

### **3. Helm Chart Application:**
```bash
# Install Redis via Helm
argocd app create redis \
  --repo https://charts.bitnami.com/bitnami \
  --helm-chart redis \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --set auth.enabled=false
```

## 🔧 **Useful Commands**

### **Kubernetes Commands:**
```bash
# Get all resources
kubectl get all --all-namespaces

# Get Minikube dashboard
minikube dashboard

# Get service URLs
minikube service list

# Access a service
minikube service <service-name>
```

### **ArgoCD Commands:**
```bash
# Get ArgoCD version
argocd version

# Get cluster info
argocd cluster list

# Get application logs
argocd app logs my-app

# Delete application
argocd app delete my-app
```

## 🌐 **Access URLs After Deployment**

| **Service** | **URL** | **Purpose** |
|-------------|---------|-------------|
| **ArgoCD Web UI** | `http://<PUBLIC_IP>:30080` | GitOps management |
| **Minikube Dashboard** | `minikube dashboard` (via SSH) | Kubernetes management |
| **Monitoring Stack** | `http://<MONITORING_IP>:3000` | Grafana dashboards |

## 🚀 **Quick Start Workflow**

### **1. Deploy Infrastructure:**
```bash
terraform apply
```

### **2. Get Access Information:**
```bash
# Get all outputs
terraform output

# Get specific commands
terraform output kubernetes_ssh_command
terraform output kubernetes_argocd_url
```

### **3. SSH and Setup:**
```bash
# SSH into Kubernetes instance
ssh -i ~/.ssh/oci_ed25519 ec2-user@<PUBLIC_IP>

# Check ArgoCD status
./argocd-access.sh

# Verify everything is running
kubectl get pods --all-namespaces
```

### **4. Start Managing Applications:**
```bash
# Create your first app
argocd app create my-first-app \
  --repo https://github.com/argoproj/argocd-example-apps \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync and monitor
argocd app sync my-first-app
argocd app get my-first-app
```

## 💡 **Tips & Best Practices**

### **ArgoCD Best Practices:**
1. **Use Git repositories** for application definitions
2. **Enable auto-sync** for continuous deployment
3. **Use namespaces** to organize applications
4. **Monitor application health** regularly
5. **Use Helm charts** for complex applications

### **Kubernetes Best Practices:**
1. **Use resource limits** in deployments
2. **Implement health checks** (liveness/readiness probes)
3. **Use ConfigMaps and Secrets** for configuration
4. **Monitor resource usage** with `kubectl top`
5. **Use namespaces** for organization

## 🔍 **Troubleshooting**

### **Common Issues:**

#### **ArgoCD Not Accessible:**
```bash
# Check if ArgoCD is running
kubectl get pods -n argocd

# Check service
kubectl get svc -n argocd

# Check logs
kubectl logs -n argocd deployment/argocd-server
```

#### **SSH Connection Issues:**
```bash
# Check security group allows SSH (port 22)
# Verify key permissions
chmod 600 ~/.ssh/oci_ed25519

# Test connection
ssh -i ~/.ssh/oci_ed25519 -v ec2-user@<PUBLIC_IP>
```

#### **Minikube Issues:**
```bash
# Restart Minikube
minikube stop
minikube start --driver=docker --memory=1536 --cpus=1

# Check status
minikube status
```

---

**Your Kubernetes cluster with ArgoCD is now ready for GitOps management!** 🎉
