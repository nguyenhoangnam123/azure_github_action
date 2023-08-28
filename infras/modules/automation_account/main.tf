resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = local.region

  tags = merge(local.common_tags)
}

data "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

########################################################
# Create Azure automation account and automation_account
########################################################
resource "azurerm_automation_account" "main" {
  name                = "${local.prefix}-automation-account"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  identity {
    type = "SystemAssigned"
  }

  sku_name = var.automation_account_sku_name

  tags = merge(local.common_tags, tomap({
    type = "automation-account"
  }))
}

data "local_file" "runbook_database_rbac" {
  count    = var.create_runbook ? 1 : 0
  filename = var.runbook_file_path
}

resource "azurerm_automation_runbook" "query_database_rbac" {
  count                   = var.create_runbook ? 1 : 0
  name                    = "${local.prefix}-query-database_rbac"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  log_verbose  = var.runbook_log_verbose
  log_progress = var.runbook_log_progress
  description  = var.runbook_description
  runbook_type = var.runbook_type

  content = data.local_file.runbook_database_rbac.content

  tags = merge(local.common_tags, tomap({
    type = "automation-runbook"
  }))
}

resource "azurerm_automation_webhook" "query_database_rbac_runbook_webhook" {
  count                   = var.create_runbook ? 1 : 0
  name                    = "${local.prefix}-query-database-webhook"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  expiry_time             = "2023-12-31T00:00:00Z"

  enabled      = var.enable_webhook
  runbook_name = azurerm_automation_runbook.query_database_rbac.name
  parameters   = var.webhook_parameters
}
