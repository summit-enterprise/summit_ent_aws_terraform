# terraform-aws-monitoring

A Terraform module for AWS monitoring infrastructure.

## Usage

```hcl
module "monitoring" {
  source = "summit-enterprise/monitoring/aws"
  version = "1.0.0"
  
  # Add your variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## License

MIT
