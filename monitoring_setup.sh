#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create monitoring directory
mkdir -p /opt/monitoring
cd /opt/monitoring

# Create docker-compose.yml for monitoring stack
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana-storage:/var/lib/grafana

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-storage:/usr/share/elasticsearch/data

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

  jaeger:
    image: jaegertracing/all-in-one:latest
    container_name: jaeger
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true

volumes:
  grafana-storage:
  elasticsearch-storage:
EOF

# Create Prometheus configuration
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Start monitoring stack
docker-compose up -d

# Create status script
cat > /home/ec2-user/status.sh << 'EOF'
#!/bin/bash
echo "=== Monitoring Stack Status ==="
docker-compose -f /opt/monitoring/docker-compose.yml ps
echo ""
echo "=== Service URLs ==="
echo "Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000 (admin/admin123)"
echo "Kibana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5601"
echo "Jaeger: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):16686"
EOF

chmod +x /home/ec2-user/status.sh
