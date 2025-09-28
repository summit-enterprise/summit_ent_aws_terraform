# ========================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
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
}

# Provider Configuration
provider "aws" {
  region = var.aws_region
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ========================================
# NETWORKING MODULE
# ========================================
module "networking" {
  source = "../../modules/networking"

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
  source = "../../modules/security"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = local.common_tags
}

# ========================================
# STORAGE MODULE
# ========================================
module "storage" {
  source = "../../modules/storage"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = local.common_tags
}

# ========================================
# COMPUTE MODULE
# ========================================
module "compute" {
  source = "../../modules/compute"

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
  source = "../../modules/monitoring"

  environment        = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  tags              = local.common_tags
}

# ========================================
# SECRETS MODULE
# ========================================
module "secrets" {
  source = "../../modules/secrets"

  environment = var.environment
  tags        = local.common_tags
}
