output "resource_group_id" {
  value = var.create_resource_group ?  azurerm_resource_group.main.id : data.azurerm_resource_group.main[0].id
}

output "azurerm_automation_account_id" {
  value = azurerm_automation_account.main.id
  description = "azure automation account id"
}

output "azurerm_automation_runbook_id" {
  value = azurerm_automation_runbook.query_database_rbac[0].id
  description = "azure automation runbook id"
}

output "automation_runbook_webhook_uri" {
  sensitive = true
  value = azurerm_automation_webhook.query_database_rbac_runbook_webhook[0].uri
}