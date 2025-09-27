# ========================================
# EXAMPLE EC2 INSTANCES (OPTIONAL)
# ========================================

# Example: RDS MySQL Database
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "mysql" {
  count = 0  # Set to 1 to enable

  identifier = "${var.environment}-mysql"
  engine     = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 100

  db_name  = "mydb"
  username = "admin"
  password = "changeme123"  # Use AWS Secrets Manager in production

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = {
    Name        = "${var.environment}-mysql"
    Environment = var.environment
  }
}

# Example: ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-cache-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "redis" {
  count = 0  # Set to 1 to enable

  replication_group_id       = "${var.environment}-redis"
  description                = "Redis cluster for caching"

  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters = 2

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.database.id]

  tags = {
    Name        = "${var.environment}-redis"
    Environment = var.environment
  }
}

# Example: EC2 Web Server
resource "aws_instance" "web" {
  count = 0  # Set to 2 to enable

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI (update for your region)
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  tags = {
    Name        = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
    Type        = "Web"
  }
}

# Example: EC2 Application Server
resource "aws_instance" "app" {
  count = 0  # Set to 1 to enable

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.small"

  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nodejs npm
    # Add your application setup here
  EOF
  )

  tags = {
    Name        = "${var.environment}-app-${count.index + 1}"
    Environment = var.environment
    Type        = "Application"
  }
}

# Example: Bastion Host
resource "aws_instance" "bastion" {
  count = 0  # Set to 1 to enable

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  key_name = "your-key-pair"  # Replace with your key pair name

  tags = {
    Name        = "${var.environment}-bastion"
    Environment = var.environment
    Type        = "Bastion"
  }
}
