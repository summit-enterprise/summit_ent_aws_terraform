# Terraform Registry Publishing Guide

## 🚀 **Complete Guide to Publishing Modules to Terraform Registry**

This guide shows you how to publish your Terraform modules to the Terraform Registry for use with Terraform Cloud and public sharing.

---

## 📋 **Prerequisites**

### **1. Required Accounts**
- **GitHub Account**: For hosting module repositories
- **Terraform Cloud Account**: For publishing to registry
- **Git**: For version control

### **2. Required Tools**
- **Terraform CLI**: Latest version
- **Git**: For repository management
- **GitHub CLI** (optional): For easier repository management

---

## 🏗️ **Module Structure Requirements**

### **Standard Module Structure**
Each module must follow this structure:
```
module-name/
├── README.md          # Module documentation
├── main.tf           # Main resource definitions
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Provider version constraints
└── examples/         # Usage examples (optional)
    └── main.tf
```

### **Required Files**

#### **1. README.md**
Must include:
- Module description
- Usage examples
- Input/output documentation
- Requirements
- Providers

#### **2. versions.tf**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

## 🚀 **Publishing Process**

### **Step 1: Create Separate Repositories**

For each module, create a separate GitHub repository:

```bash
# Example: Create networking module repository
gh repo create terraform-aws-networking --public --description "AWS Networking Terraform Module"
git clone https://github.com/yourusername/terraform-aws-networking.git
cd terraform-aws-networking
```

### **Step 2: Prepare Module Files**

#### **Create versions.tf**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### **Create README.md**
```markdown
# terraform-aws-networking

A Terraform module for creating AWS networking infrastructure including VPC, subnets, route tables, and internet gateway.

## Usage

```hcl
module "networking" {
  source = "yourusername/networking/aws"
  
  environment         = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones  = ["us-east-2a", "us-east-2b"]
  tags               = {
    Project = "MyProject"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | n/a | yes |
| public_subnet_cidrs | List of public subnet CIDRs | `list(string)` | n/a | yes |
| private_subnet_cidrs | List of private subnet CIDRs | `list(string)` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| public_route_table_id | The ID of the public route table |
| private_route_table_id | The ID of the private route table |

## License

MIT
```

### **Step 3: Create Git Tags**

Terraform Registry uses Git tags for versioning:

```bash
# Initial commit
git add .
git commit -m "Initial commit: AWS Networking module"
git push origin main

# Create version tag
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0
```

### **Step 4: Publish to Terraform Registry**

#### **Method 1: Using Terraform Cloud UI**

1. **Go to Terraform Cloud**: https://app.terraform.io/
2. **Navigate to Registry**: Click "Registry" in the top menu
3. **Publish Module**: Click "Publish Module"
4. **Connect Repository**: Connect your GitHub repository
5. **Configure Module**: Set module details
6. **Publish**: Click "Publish Module"

#### **Method 2: Using Terraform CLI**

```bash
# Login to Terraform Cloud
terraform login

# Publish module (if supported)
terraform registry publish yourusername/networking/aws
```

---

## 🔧 **Alternative: Private Module Registry**

### **Using Terraform Cloud Private Registry**

1. **Create Organization**: In Terraform Cloud
2. **Enable Private Registry**: In organization settings
3. **Publish Modules**: Upload modules to private registry
4. **Use Modules**: Reference with `app.terraform.io/yourorg/module-name/aws`

---

## 📝 **Module Examples**

### **Example 1: Networking Module**

```bash
# Create repository
gh repo create terraform-aws-networking --public

# Clone and setup
git clone https://github.com/yourusername/terraform-aws-networking.git
cd terraform-aws-networking

# Copy module files
cp -r ../../modules/networking/* .

# Add required files
# ... (create versions.tf, README.md, etc.)

# Commit and tag
git add .
git commit -m "Initial commit"
git push origin main
git tag v1.0.0
git push origin v1.0.0
```

### **Example 2: Security Module**

```bash
# Create repository
gh repo create terraform-aws-security --public

# Clone and setup
git clone https://github.com/yourusername/terraform-aws-security.git
cd terraform-aws-security

# Copy module files
cp -r ../../modules/security/* .

# Add required files and commit
# ... (same process as above)
```

---

## 🎯 **Using Published Modules**

### **In Your Terraform Configuration**

```hcl
# Using published modules
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

module "security" {
  source = "yourusername/security/aws"
  version = "1.0.0"
  
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  tags        = var.tags
}
```

---

## 🔄 **Version Management**

### **Semantic Versioning**
- **Major (1.0.0)**: Breaking changes
- **Minor (1.1.0)**: New features, backward compatible
- **Patch (1.1.1)**: Bug fixes, backward compatible

### **Creating New Versions**
```bash
# Make changes to module
git add .
git commit -m "Add new feature"
git push origin main

# Create new version tag
git tag -a v1.1.0 -m "Version 1.1.0: Add new feature"
git push origin v1.1.0
```

---

## 🛠️ **Best Practices**

### **1. Module Design**
- **Single Responsibility**: One module, one purpose
- **Reusable**: Generic enough for multiple use cases
- **Well Documented**: Clear README and examples
- **Versioned**: Use semantic versioning

### **2. Documentation**
- **README.md**: Comprehensive documentation
- **Examples**: Real-world usage examples
- **Input/Output**: Complete variable and output documentation
- **Requirements**: Clear provider and Terraform version requirements

### **3. Testing**
- **Examples**: Test with example configurations
- **Validation**: Use `terraform validate`
- **Format**: Use `terraform fmt`

---

## 🚀 **Quick Start Commands**

### **Publish All Modules**

```bash
#!/bin/bash
# Script to publish all modules

modules=("networking" "security" "storage" "compute" "monitoring" "secrets")

for module in "${modules[@]}"; do
  echo "Publishing $module module..."
  
  # Create repository
  gh repo create "terraform-aws-$module" --public --description "AWS $module Terraform Module"
  
  # Clone repository
  git clone "https://github.com/yourusername/terraform-aws-$module.git"
  cd "terraform-aws-$module"
  
  # Copy module files
  cp -r "../modules/$module"/* .
  
  # Add required files (versions.tf, README.md)
  # ... (create these files)
  
  # Commit and tag
  git add .
  git commit -m "Initial commit: AWS $module module"
  git push origin main
  git tag v1.0.0
  git push origin v1.0.0
  
  cd ..
  echo "Published $module module successfully!"
done
```

---

## 🎉 **Benefits of Terraform Registry**

### **1. Reusability**
- Share modules across teams
- Use modules from the community
- Version control for modules

### **2. Terraform Cloud Integration**
- Works seamlessly with Terraform Cloud
- Remote execution support
- Team collaboration

### **3. Discovery**
- Easy to find and use modules
- Documentation and examples
- Community contributions

---

## 📚 **Resources**

- **Terraform Registry**: https://registry.terraform.io/
- **Module Publishing Guide**: https://www.terraform.io/docs/registry/modules/publish.html
- **Terraform Cloud**: https://app.terraform.io/
- **Semantic Versioning**: https://semver.org/

---

**Your modules are now ready to be published to the Terraform Registry!** 🚀
