# ========================================
# TERRAFORM CONFIGURATION
# ========================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Best practice: Pin your provider version
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

# ========================================
# AWS PROVIDER CONFIGURATION
# ========================================

provider "aws" {
  # Use a variable for the region for better reusability
  region = var.AWS_DEFAULT_REGION 
  # profile = "aws-admin"  # Commented out - use default profile
}