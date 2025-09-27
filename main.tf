terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Best practice: Pin your provider version
      version = "~> 5.0" 
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  # Use a variable for the region for better reusability
  region = var.aws_region 
  profile = "aws-admin" 
}

