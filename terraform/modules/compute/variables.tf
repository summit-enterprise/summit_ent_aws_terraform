variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs of the security groups"
  type = object({
    web        = string
    app        = string
    database   = string
    kubernetes = string
    monitoring = string
  })
}

variable "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  type = object({
    spark_apps = string
    data_jobs  = string
    glue_jobs  = string
  })
}

variable "data_lake_bucket_name" {
  description = "Name of the data lake S3 bucket"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
