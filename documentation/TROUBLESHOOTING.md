# Troubleshooting Guide

## 🚨 **Common Issues and Solutions**

This guide helps you diagnose and resolve common issues with your AWS infrastructure deployment.

---

## 🔧 **Terraform Issues**

### **Issue 1: Terraform Cloud Authentication**
**Problem**: `Error: Failed to get existing workspaces`

**Symptoms**:
```
Error: Failed to get existing workspaces
Error: failed to get workspaces: failed to get workspaces: 401 Unauthorized
```

**Solutions**:
```bash
# Check Terraform Cloud token
terraform login

# Verify token in ~/.terraform.d/credentials.tfrc.json
cat ~/.terraform.d/credentials.tfrc.json

# Re-authenticate
rm ~/.terraform.d/credentials.tfrc.json
terraform login
```

**Prevention**:
- Keep Terraform Cloud token secure
- Use environment variables for CI/CD
- Regularly rotate tokens

---

### **Issue 2: AWS Provider Authentication**
**Problem**: `Error: No valid credential sources found`

**Symptoms**:
```
Error: No valid credential sources found for AWS Provider
Error: failed to get caller identity: operation error STS: GetCallerIdentity
```

**Solutions**:
```bash
# Check AWS credentials
aws sts get-caller-identity

# Configure AWS CLI
aws configure

# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-2"

# Check AWS profile
aws configure list
```

**Prevention**:
- Use IAM roles when possible
- Store credentials securely
- Use least privilege principles

---

### **Issue 3: Resource Already Exists**
**Problem**: `Error: resource already exists`

**Symptoms**:
```
Error: creating S3 Bucket: BucketAlreadyExists: The requested bucket name is not available
Error: creating ECR Repository: RepositoryAlreadyExistsException
```

**Solutions**:
```bash
# Import existing resource
terraform import aws_s3_bucket.data_lake <bucket-name>

# Check existing resources
aws s3 ls
aws ecr describe-repositories

# Use different names
# Edit variables.tf or use random suffixes
```

**Prevention**:
- Use unique naming conventions
- Include random suffixes
- Check existing resources before deployment

---

### **Issue 4: State Lock Issues**
**Problem**: `Error: state is locked`

**Symptoms**:
```
Error: Error acquiring the state lock
Error: state lock info: Lock ID: <lock-id>
```

**Solutions**:
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>

# Check lock status
terraform show

# Wait for lock to expire (default: 5 minutes)
# Or contact team member who has the lock
```

**Prevention**:
- Use Terraform Cloud for state management
- Implement proper locking mechanisms
- Coordinate with team members

---

## 🌐 **Network Issues**

### **Issue 5: VPC Creation Fails**
**Problem**: `Error: creating VPC`

**Symptoms**:
```
Error: creating VPC: InvalidParameterValue: The CIDR '10.0.0.0/16' is not available
Error: creating VPC: VpcLimitExceeded: The maximum number of VPCs has been reached
```

**Solutions**:
```bash
# Check existing VPCs
aws ec2 describe-vpcs

# Use different CIDR block
# Edit variables.tf
variable "vpc_cidr" {
  default = "10.1.0.0/16"  # Changed from 10.0.0.0/16
}

# Check VPC limits
aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE
```

**Prevention**:
- Use unique CIDR blocks
- Monitor VPC limits
- Clean up unused VPCs

---

### **Issue 6: Security Group Rules Conflict**
**Problem**: `Error: creating security group rule`

**Symptoms**:
```
Error: creating Security Group Rule: InvalidPermission.Duplicate
Error: creating Security Group Rule: SecurityGroupRuleLimitExceeded
```

**Solutions**:
```bash
# Check existing security groups
aws ec2 describe-security-groups --filters "Name=tag:Environment,Values=dev"

# Check security group rules
aws ec2 describe-security-group-rules --group-ids <sg-id>

# Clean up duplicate rules
# Edit security-groups.tf and remove duplicates
```

**Prevention**:
- Use consistent naming
- Avoid duplicate rules
- Monitor security group limits

---

### **Issue 7: Subnet Creation Fails**
**Problem**: `Error: creating subnet`

**Symptoms**:
```
Error: creating Subnet: InvalidSubnet.Conflict
Error: creating Subnet: SubnetLimitExceeded
```

**Solutions**:
```bash
# Check existing subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"

# Use different CIDR blocks
# Edit variables.tf
variable "public_subnet_cidrs" {
  default = ["10.0.11.0/24", "10.0.12.0/24"]  # Changed from 10.0.1.0/24, 10.0.2.0/24
}

# Check subnet limits
aws service-quotas get-service-quota --service-code vpc --quota-code L-0263D0A3
```

**Prevention**:
- Use unique CIDR blocks
- Monitor subnet limits
- Plan subnet allocation

---

## 🗄️ **Storage Issues**

### **Issue 8: S3 Bucket Creation Fails**
**Problem**: `Error: creating S3 bucket`

**Symptoms**:
```
Error: creating S3 Bucket: BucketAlreadyExists
Error: creating S3 Bucket: InvalidBucketName
```

**Solutions**:
```bash
# Check existing buckets
aws s3 ls

# Use different bucket name
# Edit s3.tf to use random suffix
resource "random_id" "bucket_suffix" {
  byte_length = 8  # Increased from 4
}

# Check bucket naming rules
# Bucket names must be globally unique
# Use lowercase letters, numbers, and hyphens only
```

**Prevention**:
- Use random suffixes
- Follow S3 naming conventions
- Check global uniqueness

---

### **Issue 9: ECR Repository Creation Fails**
**Problem**: `Error: creating ECR repository`

**Symptoms**:
```
Error: creating ECR Repository: RepositoryAlreadyExistsException
Error: creating ECR Repository: LimitExceededException
```

**Solutions**:
```bash
# Check existing repositories
aws ecr describe-repositories

# Delete unused repositories
aws ecr delete-repository --repository-name <repo-name> --force

# Use different names
# Edit ecr.tf
resource "aws_ecr_repository" "spark_apps" {
  name = "${var.environment}-spark-apps-${random_id.bucket_suffix.hex}"
}
```

**Prevention**:
- Use unique naming
- Clean up unused repositories
- Monitor ECR limits

---

## 🚀 **Compute Issues**

### **Issue 10: ECS Cluster Creation Fails**
**Problem**: `Error: creating ECS cluster`

**Symptoms**:
```
Error: creating ECS Cluster: ClusterAlreadyExistsException
Error: creating ECS Cluster: LimitExceededException
```

**Solutions**:
```bash
# Check existing clusters
aws ecs list-clusters

# Delete unused clusters
aws ecs delete-cluster --cluster <cluster-name>

# Use different names
# Edit ecs.tf
resource "aws_ecs_cluster" "data_processing" {
  name = "${var.environment}-data-processing-cluster-${random_id.bucket_suffix.hex}"
}
```

**Prevention**:
- Use unique naming
- Clean up unused clusters
- Monitor ECS limits

---

### **Issue 11: EC2 Instance Launch Fails**
**Problem**: `Error: launching EC2 instance`

**Symptoms**:
```
Error: launching EC2 instance: InstanceLimitExceeded
Error: launching EC2 instance: InsufficientInstanceCapacity
```

**Solutions**:
```bash
# Check instance limits
aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3

# Use different instance type
# Edit kubernetes.tf or monitoring.tf
resource "aws_instance" "kubernetes" {
  instance_type = "t3.medium"  # Changed from t3.small
}

# Use different availability zone
# Edit variables.tf
variable "availability_zones" {
  default = ["us-east-2c", "us-east-2d"]  # Changed from us-east-2a, us-east-2b
}
```

**Prevention**:
- Monitor instance limits
- Use different AZs
- Have backup instance types

---

### **Issue 12: Key Pair Issues**
**Problem**: `Error: creating key pair`

**Symptoms**:
```
Error: creating Key Pair: InvalidKeyPair.Duplicate
Error: creating Key Pair: InvalidKeyPair.Format
```

**Solutions**:
```bash
# Check existing key pairs
aws ec2 describe-key-pairs

# Delete unused key pairs
aws ec2 delete-key-pair --key-name <key-name>

# Use different key name
# Edit kubernetes.tf
resource "aws_key_pair" "kubernetes" {
  key_name = "${var.environment}-k8s-key-${random_id.bucket_suffix.hex}"
}

# Check key format
# Ensure public key is in correct format
cat ~/.ssh/oci_ed25519.pub
```

**Prevention**:
- Use unique key names
- Validate key format
- Clean up unused keys

---

## 🔐 **Security Issues**

### **Issue 13: IAM Role Creation Fails**
**Problem**: `Error: creating IAM role`

**Symptoms**:
```
Error: creating IAM Role: EntityAlreadyExists
Error: creating IAM Role: LimitExceeded
```

**Solutions**:
```bash
# Check existing roles
aws iam list-roles --query 'Roles[?contains(RoleName, `dev`)]'

# Delete unused roles
aws iam delete-role --role-name <role-name>

# Use different names
# Edit iam.tf
resource "aws_iam_role" "glue_service_role" {
  name = "${var.environment}-glue-service-role-${random_id.bucket_suffix.hex}"
}
```

**Prevention**:
- Use unique naming
- Clean up unused roles
- Monitor IAM limits

---

### **Issue 14: Secrets Manager Issues**
**Problem**: `Error: creating secret`

**Symptoms**:
```
Error: creating Secret: ResourceExistsException
Error: creating Secret: LimitExceededException
```

**Solutions**:
```bash
# Check existing secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `dev`)]'

# Delete unused secrets
aws secretsmanager delete-secret --secret-id <secret-name> --force-delete-without-recovery

# Use different names
# Edit secrets-manager.tf
resource "aws_secretsmanager_secret" "mysql_credentials" {
  name = "${var.environment}-mysql-credentials-${random_id.bucket_suffix.hex}"
}
```

**Prevention**:
- Use unique naming
- Clean up unused secrets
- Monitor Secrets Manager limits

---

## 📊 **Monitoring Issues**

### **Issue 15: Prometheus Not Starting**
**Problem**: Prometheus container fails to start

**Symptoms**:
```
Error: prometheus container exited with code 1
Error: prometheus: error loading config: couldn't load configuration
```

**Solutions**:
```bash
# SSH to monitoring instance
ssh ec2-user@<monitoring-ip>

# Check container status
docker ps -a

# Check logs
docker logs prometheus

# Check configuration
cat /home/ec2-user/monitoring/prometheus.yml

# Restart container
docker-compose restart prometheus
```

**Prevention**:
- Validate configuration files
- Check container logs
- Test configurations locally

---

### **Issue 16: Grafana Access Issues**
**Problem**: Cannot access Grafana web interface

**Symptoms**:
```
Error: Connection refused
Error: 404 Not Found
```

**Solutions**:
```bash
# Check container status
docker ps | grep grafana

# Check port binding
docker port grafana

# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Restart container
docker-compose restart grafana

# Check logs
docker logs grafana
```

**Prevention**:
- Verify security group rules
- Check port configurations
- Monitor container health

---

### **Issue 17: Elasticsearch Issues**
**Problem**: Elasticsearch container fails to start

**Symptoms**:
```
Error: elasticsearch container exited with code 1
Error: elasticsearch: max virtual memory areas vm.max_map_count is too low
```

**Solutions**:
```bash
# SSH to monitoring instance
ssh ec2-user@<monitoring-ip>

# Fix vm.max_map_count
sudo sysctl -w vm.max_map_count=262144

# Make it permanent
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Restart container
docker-compose restart elasticsearch
```

**Prevention**:
- Set proper system limits
- Use appropriate memory settings
- Monitor resource usage

---

## ☸️ **Kubernetes Issues**

### **Issue 18: Minikube Not Starting**
**Problem**: Minikube fails to start

**Symptoms**:
```
Error: minikube start: failed to start node
Error: minikube start: insufficient memory
```

**Solutions**:
```bash
# SSH to Kubernetes instance
ssh -i ~/.ssh/oci_ed25519 ec2-user@<kubernetes-ip>

# Check system resources
free -h
df -h

# Start Minikube with less memory
minikube start --driver=docker --memory=1024 --cpus=1

# Check Docker status
sudo systemctl status docker
```

**Prevention**:
- Use appropriate instance sizes
- Monitor resource usage
- Configure proper limits

---

### **Issue 19: ArgoCD Not Accessible**
**Problem**: Cannot access ArgoCD web interface

**Symptoms**:
```
Error: Connection refused
Error: 404 Not Found
```

**Solutions**:
```bash
# Check ArgoCD status
kubectl get pods -n argocd

# Check service
kubectl get svc -n argocd

# Check port forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Check logs
kubectl logs -n argocd deployment/argocd-server
```

**Prevention**:
- Verify service configurations
- Check network policies
- Monitor pod health

---

## 🔄 **Data Pipeline Issues**

### **Issue 20: Glue Job Fails**
**Problem**: Glue job execution fails

**Symptoms**:
```
Error: Glue job failed with exit code 1
Error: Glue job timeout
```

**Solutions**:
```bash
# Check job status
aws glue get-job-runs --job-name dev-data-processing-job

# Check job logs
aws logs describe-log-groups --log-group-name-prefix /aws-glue

# Check S3 permissions
aws s3 ls s3://<bucket-name>/

# Test job manually
aws glue start-job-run --job-name dev-data-processing-job
```

**Prevention**:
- Validate job scripts
- Check IAM permissions
- Monitor job performance

---

### **Issue 21: ECS Task Fails**
**Problem**: ECS task fails to start

**Symptoms**:
```
Error: ECS task stopped with exit code 1
Error: ECS task failed to start
```

**Solutions**:
```bash
# Check task status
aws ecs describe-tasks --cluster <cluster-name> --tasks <task-arn>

# Check task definition
aws ecs describe-task-definition --task-definition <task-definition-arn>

# Check logs
aws logs describe-log-groups --log-group-name-prefix /ecs

# Check ECR permissions
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-2.amazonaws.com
```

**Prevention**:
- Validate container images
- Check IAM permissions
- Monitor task health

---

## 🛠️ **General Troubleshooting Commands**

### **System Health Checks**
```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform version
terraform validate

# Check Docker
docker --version
docker ps

# Check Kubernetes
kubectl version
kubectl cluster-info
```

### **Resource Verification**
```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev"

# Check subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Environment,Values=dev"

# Check instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"
```

### **Log Analysis**
```bash
# Check CloudWatch logs
aws logs describe-log-groups
aws logs get-log-events --log-group-name <log-group-name> --log-stream-name <log-stream-name>

# Check container logs
docker logs <container-name>
docker logs <container-name> --tail 100

# Check system logs
sudo journalctl -u docker
sudo journalctl -u kubelet
```

### **Network Troubleshooting**
```bash
# Test connectivity
ping <instance-ip>
telnet <instance-ip> 22
curl http://<instance-ip>:9090

# Check DNS
nslookup <instance-ip>
dig <instance-ip>

# Check routing
traceroute <instance-ip>
```

---

## 📞 **Getting Help**

### **AWS Support**
- **Documentation**: https://docs.aws.amazon.com/
- **Support Center**: https://console.aws.amazon.com/support/
- **Community Forums**: https://forums.aws.amazon.com/

### **Terraform Support**
- **Documentation**: https://terraform.io/docs/
- **Community**: https://discuss.hashicorp.com/
- **GitHub**: https://github.com/hashicorp/terraform

### **Monitoring Tools**
- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/
- **ELK Stack**: https://www.elastic.co/guide/

### **Kubernetes Support**
- **Documentation**: https://kubernetes.io/docs/
- **Community**: https://kubernetes.io/community/
- **GitHub**: https://github.com/kubernetes/kubernetes

---

## 🔍 **Diagnostic Checklist**

### **Before Deployment**
- [ ] AWS credentials configured
- [ ] Terraform Cloud access verified
- [ ] Required tools installed
- [ ] Environment variables set
- [ ] Resource limits checked

### **During Deployment**
- [ ] Terraform plan successful
- [ ] No resource conflicts
- [ ] All dependencies resolved
- [ ] State file updated
- [ ] Resources created successfully

### **After Deployment**
- [ ] All services accessible
- [ ] Monitoring working
- [ ] Logs flowing
- [ ] Alerts configured
- [ ] Backup procedures in place

---

**Remember: Most issues can be resolved by checking logs, verifying permissions, and ensuring proper resource configuration!** 🔧
