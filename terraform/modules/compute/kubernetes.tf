# ========================================
# KUBERNETES CLUSTER (MINIKUBE ON EC2)
# ========================================

# Security Group for Kubernetes
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

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-k8s-sg"
    Environment = var.environment
    Purpose     = "Kubernetes Cluster"
  }
}

# Key Pair for SSH access (optional)
# Uncomment and configure if you have an SSH key
# resource "aws_key_pair" "kubernetes" {
#   key_name   = "${var.environment}-k8s-key"
#   public_key = file("~/.ssh/oci_ed25519.pub")
#
#   tags = {
#     Name        = "${var.environment}-k8s-key"
#     Environment = var.environment
#   }
# }

# EC2 Instance for Kubernetes (Minikube)
resource "aws_instance" "kubernetes" {
  count = 1  # Set to 0 to disable

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.small"  # 2GB RAM - enough for Minikube
  # key_name      = aws_key_pair.kubernetes.key_name  # Uncomment if using SSH key

  subnet_id                   = aws_subnet.public[0].id
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

  tags = {
    Name        = "${var.environment}-k8s-master"
    Environment = var.environment
    Purpose     = "Kubernetes Cluster (Minikube)"
  }
}

# Elastic IP for Kubernetes (optional - for static IP)
resource "aws_eip" "kubernetes" {
  count = 0  # Set to 0 to disable

  instance = aws_instance.kubernetes[0].id
  domain   = "vpc"

  tags = {
    Name        = "${var.environment}-k8s-eip"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Kubernetes - DISABLED
# Uncomment the block below to enable CloudWatch logging
# resource "aws_cloudwatch_log_group" "kubernetes" {
#   name              = "/aws/ec2/kubernetes/${var.environment}"
#   retention_in_days = 7

#   tags = {
#     Name        = "${var.environment}-k8s-logs"
#     Environment = var.environment
#   }
# }
