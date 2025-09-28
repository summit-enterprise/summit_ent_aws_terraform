# terraform-aws-storage

A Terraform module for AWS storage infrastructure.

## Usage

```hcl
module "storage" {
  source = "summit-enterprise/storage/aws"
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
