#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
mv minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

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
  - job_name: 'kubernetes'
    static_configs:
      - targets: ['kubernetes.default.svc:443']
EOF

# Start monitoring stack
docker-compose up -d

# Start Minikube
minikube start --driver=docker --memory=2048 --cpus=2

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Create status script
cat > /home/ec2-user/status.sh << 'EOF'
#!/bin/bash
echo "=== Monitoring Stack Status ==="
docker-compose -f /opt/monitoring/docker-compose.yml ps
echo ""
echo "=== Kubernetes Status ==="
kubectl get nodes
kubectl get pods -A
echo ""
echo "=== ArgoCD Status ==="
kubectl get pods -n argocd
echo ""
echo "=== Service URLs ==="
echo "Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000 (admin/admin123)"
echo "Kibana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5601"
echo "Jaeger: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):16686"
echo "ArgoCD: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080 (admin/$ARGOCD_PASSWORD)"
echo ""
echo "=== ArgoCD Admin Password ==="
echo "Password: $ARGOCD_PASSWORD"
EOF

chmod +x /home/ec2-user/status.sh

# Create Kubernetes access script
cat > /home/ec2-user/k8s-access.sh << 'EOF'
#!/bin/bash
echo "=== Kubernetes Cluster Access ==="
echo "To access the cluster:"
echo "1. SSH into this instance"
echo "2. Run: kubectl get nodes"
echo "3. Run: kubectl get pods -A"
echo ""
echo "=== ArgoCD Access ==="
echo "1. Port forward ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Access: https://localhost:8080"
echo "3. Username: admin"
echo "4. Password: $ARGOCD_PASSWORD"
EOF

chmod +x /home/ec2-user/k8s-access.sh

echo "Setup complete! Kubernetes and ArgoCD are now running."
echo "Run /home/ec2-user/status.sh to check status"

