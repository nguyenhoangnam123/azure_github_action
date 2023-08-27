locals {
  environment = "dev"
  prefix      = "namnh21894-${local.environment}"
  region      = "eastus"

  common_tags = {
    Environment = "dev",
    Terraform   = true
  }
}