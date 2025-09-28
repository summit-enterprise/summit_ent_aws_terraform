# terraform-aws-networking

A Terraform module for creating AWS networking infrastructure including VPC, subnets, route tables, and internet gateway.

## Description

This module creates a complete AWS networking setup with:
- VPC with DNS hostnames and support enabled
- Public and private subnets across multiple availability zones
- Internet Gateway for public subnet internet access
- Route tables for public and private subnets
- Proper tagging for all resources

## Usage

```hcl
module "networking" {
  source = "yourusername/networking/aws"
  version = "1.0.0"
  
  environment         = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones  = ["us-east-2a", "us-east-2b"]
  tags               = {
    Project     = "MyProject"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| public_subnet_cidrs | List of CIDR blocks for public subnets | `list(string)` | n/a | yes |
| private_subnet_cidrs | List of CIDR blocks for private subnets | `list(string)` | n/a | yes |
| availability_zones | List of availability zones to use for subnets | `list(string)` | n/a | yes |
| tags | A map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the main VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| public_route_table_id | The ID of the public route table |
| private_route_table_id | The ID of the private route table |

## Examples

### Basic Usage

```hcl
module "networking" {
  source = "yourusername/networking/aws"
  
  environment         = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones  = ["us-east-2a", "us-east-2b"]
}
```

### With Custom Tags

```hcl
module "networking" {
  source = "yourusername/networking/aws"
  
  environment         = "production"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones  = ["us-east-2a", "us-east-2b"]
  
  tags = {
    Project     = "MyProject"
    Environment = "production"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
  }
}
```

## Resources Created

- `aws_vpc` - Main VPC
- `aws_internet_gateway` - Internet Gateway
- `aws_subnet` - Public and private subnets
- `aws_route_table` - Route tables for public and private subnets
- `aws_route_table_association` - Associations between subnets and route tables

## License

MIT

## Authors

- Your Name <your.email@example.com>
