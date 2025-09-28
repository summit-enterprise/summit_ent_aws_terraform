# Quick Terraform Registry Publishing Guide

## 🚀 **Quick Start - Publish Your Modules**

### **Step 1: Prerequisites**
```bash
# Install GitHub CLI (if not already installed)
# macOS
brew install gh

# Login to GitHub
gh auth login
```

### **Step 2: Update Configuration**
Edit `publish-modules.sh` and update:
```bash
GITHUB_USERNAME="yourusername"  # Replace with your GitHub username
```

### **Step 3: Publish Modules**

#### **Option A: Publish All Modules**
```bash
./publish-modules.sh --all
```

#### **Option B: Publish Single Module**
```bash
./publish-modules.sh networking
```

### **Step 4: Publish to Terraform Registry**
1. Go to https://app.terraform.io/
2. Click "Registry" → "Publish Module"
3. Connect your GitHub repository
4. Configure module details
5. Click "Publish Module"

---

## 📋 **Manual Steps (Alternative)**

### **1. Create GitHub Repository**
```bash
# Example for networking module
gh repo create terraform-aws-networking --public --description "AWS Networking Terraform Module"
```

### **2. Clone and Setup**
```bash
git clone https://github.com/yourusername/terraform-aws-networking.git
cd terraform-aws-networking
```

### **3. Copy Module Files**
```bash
cp -r ../terraform/modules/networking/* .
```

### **4. Add Required Files**
- `versions.tf` (already created)
- `README.md` (already created)
- `examples/` directory (already created)

### **5. Commit and Tag**
```bash
git add .
git commit -m "Initial commit: AWS Networking module"
git push origin main

git tag v1.0.0
git push origin v1.0.0
```

---

## 🎯 **Using Published Modules**

### **In Your Terraform Configuration**
```hcl
module "networking" {
  source = "yourusername/networking/aws"
  version = "1.0.0"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  tags               = var.tags
}
```

---

## 📚 **Available Modules**

Your modules ready for publishing:
- `networking` - VPC, subnets, route tables, IGW
- `security` - Security groups, IAM roles
- `storage` - S3, ECR, Glue
- `compute` - ECS, Kubernetes
- `monitoring` - Prometheus, Grafana, ELK, Jaeger
- `secrets` - AWS Secrets Manager

---

## 🔧 **Troubleshooting**

### **GitHub CLI Not Installed**
```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### **Not Logged In to GitHub**
```bash
gh auth login
```

### **Repository Already Exists**
```bash
# Delete existing repository
gh repo delete yourusername/terraform-aws-networking --yes

# Or use a different name
gh repo create terraform-aws-networking-v2 --public
```

---

**Ready to publish your modules!** 🚀
