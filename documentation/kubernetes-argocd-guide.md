# Kubernetes (k3s) + ArgoCD Setup Guide

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
ssh -i ~/.ssh/terraform-key.pem ec2-user@<PUBLIC_IP>
```

### **4. Verify Kubernetes is Running:**
```bash
# Check k3s status
sudo systemctl status k3s

# Check kubectl access
kubectl get nodes
kubectl get pods --all-namespaces

# Check ArgoCD pods
kubectl get pods -n argocd
```

## 🚀 **ArgoCD Setup & Usage**

### **1. Access ArgoCD Web Interface (SSH Tunnel Required):**

**Step 1: SSH to k3s instance and port-forward ArgoCD:**
```bash
# SSH to k3s instance
ssh -i ~/.ssh/terraform-key.pem ec2-user@<K3S_IP>

# Port forward ArgoCD service
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Step 2: Create SSH tunnel from your local machine:**
```bash
# In a new terminal on your local machine
ssh -i ~/.ssh/terraform-key.pem -L 8080:localhost:8080 ec2-user@<K3S_IP>
```

**Step 3: Access ArgoCD:**
- **URL:** `https://localhost:8080`
- **Username:** `admin`
- **Password:** Get it by running: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### **2. ArgoCD CLI Access:**

#### **Method 1: Direct SSH Access**
```bash
# SSH into the k3s instance
ssh -i ~/.ssh/terraform-key.pem ec2-user@<K3S_IP>

# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# In another terminal, login to ArgoCD
argocd login localhost:8080 --username admin --password <PASSWORD>
```

#### **Method 2: SSH Tunnel (from your local machine)**
```bash
# SSH with port forwarding
ssh -i ~/.ssh/terraform-key.pem -L 8080:localhost:8080 ec2-user@<K3S_IP>

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

# Check k3s status
sudo systemctl status k3s

# Get service URLs
kubectl get services --all-namespaces

# Port forward a service
kubectl port-forward svc/<service-name> -n <namespace> <local-port>:<service-port>
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
| **ArgoCD Web UI** | `https://localhost:8080` (SSH tunnel) | GitOps management |
| **k3s Dashboard** | `kubectl proxy` (via SSH) | Kubernetes management |
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
# SSH into k3s instance
ssh -i ~/.ssh/terraform-key.pem ec2-user@<K3S_IP>

# Check k3s status
sudo systemctl status k3s

# Check ArgoCD status
kubectl get pods -n argocd

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

#### **k3s Issues:**
```bash
# Restart k3s
sudo systemctl restart k3s

# Check status
sudo systemctl status k3s

# Check logs
sudo journalctl -u k3s -f
```

---

**Your Kubernetes cluster with ArgoCD is now ready for GitOps management!** 🎉
