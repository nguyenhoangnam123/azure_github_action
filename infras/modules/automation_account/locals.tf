locals {
  environment = var.environment
  prefix      = "${var.common_prefix}-${local.environment}"
  region      = var.region
  resource_group_name     = var.create_resource_group ? azurerm_resource_group.main.name : data.azurerm_resource_group.main.name
  resource_group_location = var.create_resource_group ? azurerm_resource_group.main.location : data.azurerm_resource_group.main.location

  common_tags = {
    Environment = var.environment,
    Terraform   = true
  }
}