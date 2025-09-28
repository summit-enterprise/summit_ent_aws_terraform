# ========================================
# FREE MONITORING STACK
# ========================================

# Security Group for Monitoring Stack
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.environment}-monitoring-"
  vpc_id      = aws_vpc.main.id

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Elasticsearch
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jaeger
  ingress {
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
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

  tags = {
    Name        = "${var.environment}-monitoring-sg"
    Environment = var.environment
    Purpose     = "Monitoring Stack"
  }
}

# EC2 Instance for Monitoring Stack
resource "aws_instance" "monitoring" {
  count = 1  # Set to 0 to disable

  ami           = "ami-0c02fb55956c7d3"  # Amazon Linux 2 AMI
  instance_type = "t3.small"  # 2 vCPU, 2GB RAM - enough for monitoring stack
  # key_name      = aws_key_pair.kubernetes.key_name  # Uncomment if you have SSH key

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  # Root volume
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # User data script to install monitoring stack
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    
    # Install Docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Create monitoring directory
    mkdir -p /home/ec2-user/monitoring
    cd /home/ec2-user/monitoring
    
    # Create Prometheus configuration
    cat > prometheus.yml << 'PROMETHEUS_EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
  
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
  
  - job_name: 'pushgateway'
    static_configs:
      - targets: ['pushgateway:9091']
  
  - job_name: 'cloudwatch-exporter'
    static_configs:
      - targets: ['cloudwatch-exporter:9106']
    scrape_interval: 60s
PROMETHEUS_EOF

    # Create Docker Compose for monitoring stack
    cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  # Prometheus - Metrics collection
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

  # Grafana - Dashboards
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${random_password.grafana_password.result}
    networks:
      - monitoring

  # Node Exporter - System metrics
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

  # cAdvisor - Container metrics
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    networks:
      - monitoring

  # Elasticsearch - Log storage (optimized for t3.small)
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms256m -Xmx256m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - monitoring

  # Kibana - Log visualization
  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - monitoring

  # Jaeger - Distributed tracing
  jaeger:
    image: jaegertracing/all-in-one:latest
    container_name: jaeger
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    networks:
      - monitoring

  # Logstash - Log processing and forwarding
  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    container_name: logstash
    ports:
      - "5044:5044"
      - "9600:9600"
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    environment:
      - S3_BUCKET=${aws_s3_bucket.data_lake.bucket}
      - AWS_REGION=${var.AWS_DEFAULT_REGION}
    depends_on:
      - elasticsearch
    networks:
      - monitoring

  # Prometheus Pushgateway - For custom metrics
  pushgateway:
    image: prom/pushgateway:latest
    container_name: pushgateway
    ports:
      - "9091:9091"
    networks:
      - monitoring

  # AWS CloudWatch Exporter - CloudWatch metrics to Prometheus
  cloudwatch-exporter:
    image: prom/cloudwatch-exporter:latest
    container_name: cloudwatch-exporter
    ports:
      - "9106:9106"
    environment:
      - AWS_REGION=${var.AWS_DEFAULT_REGION}
      - AWS_ACCESS_KEY_ID=placeholder
      - AWS_SECRET_ACCESS_KEY=placeholder
    volumes:
      - ./cloudwatch-exporter.yml:/config/config.yml
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:
  elasticsearch_data:

networks:
  monitoring:
    driver: bridge
COMPOSE_EOF

    # Start monitoring stack
    docker-compose up -d
    
    # Create Logstash configuration for AWS services
    cat > logstash.conf << 'LOGSTASH_EOF'
input {
  # S3 access logs
  s3 {
    bucket => "${aws_s3_bucket.data_lake.bucket}"
    prefix => "logs/"
    region => "${var.AWS_DEFAULT_REGION}"
    type => "s3_access"
  }
  
  # ECS logs
  tcp {
    port => 5044
    type => "ecs_logs"
  }
  
  # EC2 system logs
  file {
    path => "/var/log/messages"
    type => "system_logs"
  }
}

filter {
  if [type] == "s3_access" {
    grok {
      match => { "message" => "%%{COMBINEDAPACHELOG}" }
    }
  }
  
  if [type] == "ecs_logs" {
    json {
      source => "message"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "aws-logs-%%{+YYYY.MM.dd}"
  }
}
LOGSTASH_EOF

    # Create CloudWatch Exporter configuration
    cat > cloudwatch-exporter.yml << 'CW_EOF'
region: us-east-2
metrics:
  - aws_namespace: AWS/S3
    aws_metric_name: BucketSizeBytes
    aws_dimensions: [BucketName]
    aws_statistics: [Average]
  - aws_namespace: AWS/Glue
    aws_metric_name: GlueJobRuns
    aws_dimensions: [JobName]
    aws_statistics: [Sum]
  - aws_namespace: AWS/ECS
    aws_metric_name: CPUUtilization
    aws_dimensions: [ServiceName, ClusterName]
    aws_statistics: [Average]
  - aws_namespace: AWS/EC2
    aws_metric_name: CPUUtilization
    aws_dimensions: [InstanceId]
    aws_statistics: [Average]
CW_EOF

    # Create startup script
    cat > start_monitoring.sh << 'START_EOF'
#!/bin/bash
cd /home/ec2-user/monitoring
docker-compose up -d
echo "Monitoring stack started!"
echo "Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000 (admin/admin123)"
echo "Kibana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5601"
echo "Jaeger: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):16686"
echo "Pushgateway: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9091"
echo "CloudWatch Exporter: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9106"
START_EOF

    chmod +x start_monitoring.sh
    
    # Create stop script
    cat > stop_monitoring.sh << 'STOP_EOF'
#!/bin/bash
cd /home/ec2-user/monitoring
docker-compose down
echo "Monitoring stack stopped!"
STOP_EOF

    chmod +x stop_monitoring.sh
    
    # Set ownership
    chown -R ec2-user:ec2-user /home/ec2-user/monitoring
  EOF
  )

  tags = {
    Name        = "${var.environment}-monitoring"
    Environment = var.environment
    Purpose     = "Monitoring Stack (Prometheus, Grafana, ELK, Jaeger)"
  }
}

# Elastic IP for Monitoring (optional)
resource "aws_eip" "monitoring" {
  count = 1  # Set to 0 to disable

  instance = aws_instance.monitoring[0].id
  domain   = "vpc"

  tags = {
    Name        = "${var.environment}-monitoring-eip"
    Environment = var.environment
  }
}
