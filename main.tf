# ========================================
# SIMPLE WORKING CONFIGURATION
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
# VPC INFRASTRUCTURE
# ========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ========================================
# SECURITY GROUPS
# ========================================

resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-web-sg"
  })
}

resource "aws_security_group" "monitoring" {
  name_prefix = "${var.environment}-monitoring-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-monitoring-sg"
  })
}

# ========================================
# S3 DATA LAKE
# ========================================

resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.environment}-data-lake-${random_string.bucket_suffix.result}"

  tags = local.common_tags
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ========================================
# ECR REPOSITORIES
# ========================================

resource "aws_ecr_repository" "spark_apps" {
  name                 = "${var.environment}-spark-apps"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "data_jobs" {
  name                 = "${var.environment}-data-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# ========================================
# MONITORING INSTANCE
# ========================================

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  subnet_id             = aws_subnet.public[0].id

  user_data = base64encode(templatefile("${path.module}/monitoring_setup.sh", {
    environment = var.environment
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-monitoring"
  })
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ========================================
# OUTPUTS
# ========================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "data_lake_bucket_name" {
  description = "Name of the data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value = {
    spark_apps = aws_ecr_repository.spark_apps.repository_url
    data_jobs  = aws_ecr_repository.data_jobs.repository_url
  }
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_urls" {
  description = "Map of monitoring service URLs"
  value = {
    prometheus = "http://${aws_instance.monitoring.public_ip}:9090"
    grafana    = "http://${aws_instance.monitoring.public_ip}:3000 (admin/admin123)"
    kibana     = "http://${aws_instance.monitoring.public_ip}:5601"
    jaeger     = "http://${aws_instance.monitoring.public_ip}:16686"
  }
}

output "monitoring_ssh_command" {
  description = "SSH command for monitoring instance"
  value       = "ssh -i ~/.ssh/oci_ed25519 ec2-user@${aws_instance.monitoring.public_ip}"
}
