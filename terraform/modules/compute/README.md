# terraform-aws-compute

A Terraform module for AWS compute infrastructure.

## Usage

```hcl
module "compute" {
  source = "summit-enterprise/compute/aws"
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
