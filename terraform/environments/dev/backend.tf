# ========================================
# TERRAFORM CLOUD BACKEND CONFIGURATION
# ========================================

terraform {
  cloud {
    organization = "summit-enterprise"
    workspaces {
      name = "summit_ent_aws_terraform"
    }
  }
}
