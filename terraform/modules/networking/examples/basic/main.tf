# Example usage of the networking module

module "networking" {
  source = "../../"
  
  environment         = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones  = ["us-east-2a", "us-east-2b"]
  
  tags = {
    Project     = "ExampleProject"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Output the VPC ID
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}
