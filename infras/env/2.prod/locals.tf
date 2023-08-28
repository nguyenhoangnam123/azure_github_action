locals {
  common_tags = {
    Environment = var.environment,
    Terraform   = true
  }
}