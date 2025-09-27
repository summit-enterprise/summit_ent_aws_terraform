# ========================================
# OUTPUTS
# ========================================

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    spark_apps = aws_ecr_repository.spark_apps.repository_url
    data_jobs  = aws_ecr_repository.data_jobs.repository_url
    glue_jobs  = aws_ecr_repository.glue_jobs.repository_url
  }
}

# S3 Outputs
output "data_lake_bucket_name" {
  description = "Name of the main data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "data_lake_bucket_arn" {
  description = "ARN of the main data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "glue_scripts_bucket_name" {
  description = "Name of the Glue scripts S3 bucket"
  value       = aws_s3_bucket.glue_scripts.bucket
}

# Glue Outputs
output "glue_catalog_database_name" {
  description = "Name of the Glue Data Catalog database"
  value       = aws_glue_catalog_database.data_lake_catalog.name
}

output "glue_job_names" {
  description = "Names of the Glue jobs"
  value = {
    data_processing = aws_glue_job.data_processing_job.name
    data_quality    = aws_glue_job.data_quality_job.name
  }
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.data_processing.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.data_processing.arn
}

output "ecs_task_definition_arns" {
  description = "ARNs of the ECS task definitions"
  value = {
    data_processing = aws_ecs_task_definition.data_processing_task.arn
    spark_job       = aws_ecs_task_definition.spark_job_task.arn
  }
}

# Security Group Outputs
output "security_group_ids" {
  description = "IDs of the security groups"
  value = {
    web      = aws_security_group.web.id
    database = aws_security_group.database.id
    app      = aws_security_group.app.id
    bastion  = aws_security_group.bastion.id
  }
}

# IAM Outputs
output "iam_role_arns" {
  description = "ARNs of the IAM roles"
  value = {
    glue_service_role      = aws_iam_role.glue_service_role.arn
    ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.arn
    ecs_task_role          = aws_iam_role.ecs_task_role.arn
  }
}

# Kubernetes Outputs
output "kubernetes_instance_id" {
  description = "ID of the Kubernetes EC2 instance"
  value       = aws_instance.kubernetes[0].id
}

output "kubernetes_public_ip" {
  description = "Public IP of the Kubernetes instance"
  value       = aws_instance.kubernetes[0].public_ip
}

output "kubernetes_public_dns" {
  description = "Public DNS of the Kubernetes instance"
  value       = aws_instance.kubernetes[0].public_dns
}

output "kubernetes_ssh_command" {
  description = "SSH command to connect to Kubernetes instance"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.kubernetes[0].public_ip}"
}

output "kubernetes_minikube_dashboard" {
  description = "Minikube dashboard access command"
  value       = "ssh -i ~/.ssh/id_rsa -L 8080:localhost:8080 ec2-user@${aws_instance.kubernetes[0].public_ip} 'minikube dashboard --url'"
}
