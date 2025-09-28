# ========================================
# DEV ENVIRONMENT OUTPUTS
# ========================================

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# Security Outputs
output "security_group_ids" {
  description = "IDs of the security groups"
  value       = module.security.security_group_ids
}

output "iam_role_arns" {
  description = "ARNs of the IAM roles"
  value       = module.security.iam_role_arns
}

# Storage Outputs
output "data_lake_bucket_name" {
  description = "Name of the main data lake S3 bucket"
  value       = module.storage.data_lake_bucket_name
}

output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = module.storage.ecr_repository_urls
}

# Compute Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "kubernetes_instance_id" {
  description = "ID of the Kubernetes EC2 instance"
  value       = module.compute.kubernetes_instance_id
}

# Monitoring Outputs
output "monitoring_instance_id" {
  description = "ID of the monitoring EC2 instance"
  value       = module.monitoring.monitoring_instance_id
}

output "monitoring_urls" {
  description = "URLs for monitoring services"
  value       = module.monitoring.monitoring_urls
}

# Secrets Outputs
output "secrets_manager_arns" {
  description = "ARNs of the secrets in AWS Secrets Manager"
  value       = module.secrets.secrets_manager_arns
}
