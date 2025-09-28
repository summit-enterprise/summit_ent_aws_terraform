#!/bin/bash

# ========================================
# SWITCH TO MODULAR STRUCTURE SCRIPT
# ========================================
# This script converts the simple main.tf to use published modules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    print_error "Please run this script from the aws-summit-terraform directory"
    exit 1
fi

# Backup current main.tf
print_status "Creating backup of current main.tf..."
cp main.tf main-simple.tf.bak
print_success "Backup created: main-simple.tf.bak"

# Create modular main.tf
print_status "Creating modular main.tf..."

cat > main.tf << 'EOF'
# ========================================
# MODULAR TERRAFORM CONFIGURATION
# ========================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  required_version = ">= 1.0"
  
  # Configure Terraform Cloud backend
  cloud {
    organization = "summit-enterprise"
    workspaces {
      name = "summit_ent_aws_terraform"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ========================================
# LOCAL VALUES
# ========================================

locals {
  common_tags = {
    Environment = var.environment
    Project     = "aws-terraform-tutorial"
    ManagedBy   = "terraform"
  }
}

# ========================================
# NETWORKING MODULE
# ========================================
module "networking" {
  source = "summit-enterprise/networking/aws"
  version = "1.0.0"

  environment           = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

# ========================================
# SECURITY MODULE
# ========================================
module "security" {
  source = "summit-enterprise/security/aws"
  version = "1.0.0"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = local.common_tags
}

# ========================================
# STORAGE MODULE
# ========================================
module "storage" {
  source = "summit-enterprise/storage/aws"
  version = "1.0.0"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = local.common_tags
}

# ========================================
# COMPUTE MODULE
# ========================================
module "compute" {
  source = "summit-enterprise/compute/aws"
  version = "1.0.0"

  environment           = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  security_group_ids   = module.security.security_group_ids
  ecr_repository_urls  = module.storage.ecr_repository_urls
  data_lake_bucket_name = module.storage.data_lake_bucket_name
  tags                 = local.common_tags
}

# ========================================
# MONITORING MODULE
# ========================================
module "monitoring" {
  source = "summit-enterprise/monitoring/aws"
  version = "1.0.0"

  environment        = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  tags              = local.common_tags
}

# ========================================
# SECRETS MODULE
# ========================================
module "secrets" {
  source = "summit-enterprise/secrets/aws"
  version = "1.0.0"

  environment = var.environment
  tags        = local.common_tags
}

# ========================================
# OUTPUTS
# ========================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "data_lake_bucket_name" {
  description = "Name of the data lake S3 bucket"
  value       = module.storage.data_lake_bucket_name
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.storage.ecr_repository_urls
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = module.monitoring.monitoring_public_ip
}

output "monitoring_urls" {
  description = "Map of monitoring service URLs"
  value       = module.monitoring.monitoring_urls
}

output "monitoring_ssh_command" {
  description = "SSH command for monitoring instance"
  value       = module.monitoring.monitoring_ssh_command
}
EOF

print_success "Modular main.tf created!"

# Create switch back script
print_status "Creating switch-back script..."

cat > switch-to-simple.sh << 'EOF'
#!/bin/bash
# Switch back to simple structure
if [ -f "main-simple.tf.bak" ]; then
    cp main-simple.tf.bak main.tf
    echo "Switched back to simple structure"
else
    echo "Backup file not found!"
fi
EOF

chmod +x switch-to-simple.sh

print_success "Switch-back script created: switch-to-simple.sh"

print_warning "Note: You may need to run 'terraform init' after switching to modules"
print_status "To switch back to simple structure, run: ./switch-to-simple.sh"
print_success "Ready to use modular structure!"
