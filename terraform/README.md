# Terraform Infrastructure as Code

This directory contains the Terraform configuration for the AWS infrastructure, organized following DevOps best practices.

## 📁 Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, route tables, IGW
│   ├── security/              # Security groups, IAM roles
│   ├── storage/               # S3, ECR, Glue
│   ├── compute/               # ECS, Kubernetes (Minikube)
│   ├── monitoring/            # Prometheus, Grafana, ELK, Jaeger
│   └── secrets/               # AWS Secrets Manager
├── environments/              # Environment-specific configurations
│   ├── dev/                  # Development environment
│   ├── staging/              # Staging environment (future)
│   └── prod/                 # Production environment (future)
└── shared/                   # Shared resources across environments
```

## 🏗️ Architecture

### Modules

Each module is self-contained and follows the standard Terraform module structure:

- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `main.tf` or specific resource files - Resource definitions

### Environments

Each environment has its own configuration:

- `main.tf` - Main configuration using modules
- `variables.tf` - Environment-specific variables
- `outputs.tf` - Environment outputs
- `terraform.tfvars` - Variable values
- `backend.tf` - Backend configuration

## 🚀 Usage

### Development Environment

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Module Development

When working on modules, use the `terraform/environments/dev` directory to test changes.

## 📋 Module Dependencies

```
networking (VPC, subnets)
    ↓
security (Security groups, IAM)
    ↓
storage (S3, ECR, Glue)
    ↓
compute (ECS, Kubernetes)
    ↓
monitoring (Prometheus, Grafana, etc.)
    ↓
secrets (Secrets Manager)
```

## 🔧 Best Practices

1. **Modularity**: Each module has a single responsibility
2. **Reusability**: Modules can be used across environments
3. **Consistency**: Standardized naming and tagging
4. **Security**: Least privilege access patterns
5. **Documentation**: Clear variable and output descriptions

## 📝 Naming Convention

- **Resources**: `{environment}-{service}-{purpose}`
- **Modules**: Descriptive names (networking, security, etc.)
- **Variables**: snake_case
- **Outputs**: snake_case

## 🔐 Security

- All modules use consistent tagging
- IAM roles follow least privilege principle
- Security groups are restrictive by default
- Secrets are managed through AWS Secrets Manager

## 📊 Monitoring

- Prometheus for metrics collection
- Grafana for visualization
- ELK stack for log management
- Jaeger for distributed tracing

## 🚀 Deployment

1. **Development**: Direct terraform apply
2. **Staging/Production**: CI/CD pipeline with approval gates
3. **Backend**: Terraform Cloud for state management
4. **VCS**: GitHub integration for automated runs
