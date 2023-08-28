locals {
  environment                                    = var.environment
  prefix                                         = "${var.common_prefix}-${local.environment}"
  region                                         = var.region
  resource_group_name                            = var.create_resource_group ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.main[0].name
  resource_group_location                        = var.create_resource_group ? azurerm_resource_group.main[0].location : data.azurerm_resource_group.main[0].location
  mssql_administrative_ad_service_principal_name = var.mssql_administrative_ad_entity_type == "ServicePrincipal" && length(var.mssql_administrative_ad_service_principal_name) > 0
  mssql_administrative_ad_user_principal_name    = var.mssql_administrative_ad_entity_type == "User" && length(var.mssql_administrative_ad_user_principal_name) > 0

  common_tags = var.common_tags
}