terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Best practice: Pin your provider version
      version = "~> 5.0" 
    }
  }
  required_version = ">= 1.0"
  
  # Configure Terraform Cloud backend
  cloud {
    organization = "summit-enterprise"  # Replace with your Terraform Cloud organization
    workspaces {
      name = "summit_ent_aws_terraform"  # Replace with your workspace name
    }
  }
}

provider "aws" {
  # Use a variable for the region for better reusability
  region = var.aws_region 
  profile = "aws-admin" 
}

