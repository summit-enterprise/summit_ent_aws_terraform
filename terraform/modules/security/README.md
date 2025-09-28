# terraform-aws-security

A Terraform module for AWS security infrastructure.

## Usage

```hcl
module "security" {
  source = "summit-enterprise/security/aws"
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
