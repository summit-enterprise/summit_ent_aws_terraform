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
    from_port   = 8080
    to_port     = 8080
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
# KEY PAIR
# ========================================

data "aws_key_pair" "terraform_key" {
  key_name = "terraform-key"
}

# ========================================
# KUBERNETES INSTANCE
# ========================================

resource "aws_security_group" "kubernetes" {
  name_prefix = "${var.environment}-k8s-"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API server
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Minikube dashboard
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ArgoCD
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-k8s-sg"
  })
}

resource "aws_instance" "kubernetes" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  key_name      = data.aws_key_pair.terraform_key.key_name

  subnet_id                   = aws_subnet.public[1].id  # Use different subnet
  vpc_security_group_ids      = [aws_security_group.kubernetes.id]
  associate_public_ip_address = true

  # Root volume
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # User data script to install Minikube
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    
    # Install Docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    
    # Install Minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube-linux-amd64
    mv minikube-linux-amd64 /usr/local/bin/minikube
    
    # Start Minikube with optimal resources for t3.small
    su - ec2-user -c "minikube start --driver=docker --memory=1536 --cpus=1"
    
    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install ArgoCD CLI
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    
    # Install ArgoCD in Minikube
    su - ec2-user -c "
      # Add ArgoCD Helm repository
      helm repo add argo https://argoproj.github.io/argo-helm
      helm repo update
      
      # Install ArgoCD
      kubectl create namespace argocd
      helm install argocd argo/argo-cd --namespace argocd --set server.service.type=NodePort --set server.service.nodePortHttp=30080
      
      # Wait for ArgoCD to be ready
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
      
      # Get ArgoCD admin password
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d > /home/ec2-user/argocd-password.txt
      chown ec2-user:ec2-user /home/ec2-user/argocd-password.txt
    "
    
    # Create alias for convenience
    echo 'alias k="kubectl"' >> /home/ec2-user/.bashrc
    echo 'alias m="minikube"' >> /home/ec2-user/.bashrc
    echo 'alias a="argocd"' >> /home/ec2-user/.bashrc
    
    # Install useful tools
    yum install -y git htop tree
    
    # Set up kubectl completion
    echo 'source <(kubectl completion bash)' >> /home/ec2-user/.bashrc
    echo 'complete -F __start_kubectl k' >> /home/ec2-user/.bashrc
    
    # Create ArgoCD access script
    cat > /home/ec2-user/argocd-access.sh << 'ARGOCD_EOF'
#!/bin/bash
echo "=== ArgoCD Access Information ==="
echo "ArgoCD URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):30080"
echo "Username: admin"
echo "Password: $(cat /home/ec2-user/argocd-password.txt)"
echo ""
echo "To access ArgoCD CLI:"
echo "1. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Login: argocd login localhost:8080 --username admin --password \$(cat /home/ec2-user/argocd-password.txt)"
echo "3. Get apps: argocd app list"
ARGOCD_EOF
    chmod +x /home/ec2-user/argocd-access.sh
    chown ec2-user:ec2-user /home/ec2-user/argocd-access.sh
  EOF
  )

  tags = merge(local.common_tags, {
    Name = "${var.environment}-k8s-master"
  })
}

# ========================================
# MONITORING INSTANCE
# ========================================

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name               = data.aws_key_pair.terraform_key.key_name
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  subnet_id             = aws_subnet.public[0].id

  user_data = base64encode(templatefile("${path.module}/monitoring_with_k8s.sh", {
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
# STORAGE MODULE (INCLUDES ATHENA)
# ========================================

module "storage" {
  source = "github.com/summit-enterprise/terraform-aws-storage"

  environment = var.environment
  vpc_id      = aws_vpc.main.id
  tags        = local.common_tags

  # Athena configuration
  data_lake_bucket_name           = aws_s3_bucket.data_lake.bucket
  athena_results_bucket          = null  # Will create new bucket
  create_athena_results_bucket   = true
  athena_engine_version          = "Athena engine version 3"
  enable_athena_query_logging    = true
  athena_log_group_name          = "/aws/athena/${var.environment}-data-warehouse"
  athena_log_retention_days      = 30
  create_athena_sample_queries   = true
  athena_sample_queries = {
    "list_tables" = {
      description = "List all tables in the database"
      query       = "SHOW TABLES;"
    }
    "sample_data_query" = {
      description = "Sample query to test data access"
      query       = "SELECT * FROM information_schema.tables LIMIT 10;"
    }
    "data_lake_exploration" = {
      description = "Explore data lake structure"
      query       = "SELECT * FROM information_schema.tables WHERE table_schema = '${var.environment}_data_warehouse' LIMIT 20;"
    }
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
  value       = "ssh -i ~/.ssh/terraform-key.pem ec2-user@${aws_instance.monitoring.public_ip}"
}

output "kubernetes_public_ip" {
  description = "Public IP of the Kubernetes instance"
  value       = aws_instance.kubernetes.public_ip
}

output "kubernetes_ssh_command" {
  description = "SSH command for Kubernetes instance"
  value       = "ssh -i ~/.ssh/terraform-key.pem ec2-user@${aws_instance.kubernetes.public_ip}"
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = "http://${aws_instance.kubernetes.public_ip}:30080"
}

output "kubernetes_info" {
  description = "Kubernetes cluster information"
  value = {
    public_ip = aws_instance.kubernetes.public_ip
    ssh_command = "ssh -i ~/.ssh/terraform-key.pem ec2-user@${aws_instance.kubernetes.public_ip}"
    argocd_url = "http://${aws_instance.kubernetes.public_ip}:30080"
    minikube_dashboard = "minikube dashboard --url (run on the instance)"
  }
}

output "athena_info" {
  description = "Athena data warehouse information"
  value = {
    workgroup_name = module.storage.athena_workgroup_name
    database_name = module.storage.athena_database_name
    results_bucket = module.storage.athena_results_bucket_name
    console_url = module.storage.athena_console_url
    query_commands = module.storage.athena_query_commands
  }
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = module.storage.athena_workgroup_name
}

output "athena_database_name" {
  description = "Name of the Athena database"
  value       = module.storage.athena_database_name
}

output "athena_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = module.storage.athena_results_bucket_name
}

output "athena_console_url" {
  description = "URL to access Athena console"
  value       = module.storage.athena_console_url
}
