output "resource_group_id" {
  value = var.create_resource_group ?  azurerm_resource_group.main[0].id : data.azurerm_resource_group.main[0].id
}

output "azure_key_vault_uri" {
  value       = azurerm_key_vault.key_vault[0].vault_uri
  description = "The key vault uri for azure sql server admin configuration"
}

output "azure_mssql_server_identity_client_id" {
  value       = azurerm_user_assigned_identity.mssql_server_identity[0].client_id
  description = "mssql server identity client id"
}

output "azure_mssql_server_identity_principal_id" {
  value       = azurerm_user_assigned_identity.mssql_server_identity[0].principal_id
  description = "mssql server identity principal id"
}

output "azure_mssql_server_identity_tenant_id" {
  value       = azurerm_user_assigned_identity.mssql_server_identity[0].tenant_id
  description = "mssql server identity tenant id"
}

output "azure_mssql_server_identity_ad_app_id" {
  value       = azuread_application.mssql_server_identity_ad_app[0].application_id
  description = "mssql server identity application id where to map identity with role. Eg: Microsoft Graph Role"
}

output "azure_mssql_server_fqdn" {
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
  description = "mssql server fully qualified domain name"
}

output "azurerm_mssql_database_id" {
  value       = azurerm_mssql_database.main.id
  description = "mssql database id"
}



