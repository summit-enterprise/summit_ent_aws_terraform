variable "AWS_DEFAULT_REGION" {
    description = "AWS default region"
    type = string
    default = "us-east-2"
}

variable "TEST_VAR" {
    description = "A test variable with no default value"
    type = string
    default = "my-custom-value"
}

# VPC Configuration
variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "availability_zones" {
    description = "Availability zones"
    type = list(string)
    default = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
    description = "CIDR blocks for public subnets"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    description = "CIDR blocks for private subnets"
    type = list(string)
    default = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "environment" {
    description = "Environment name"
    type = string
    default = "dev"
}