# datasource
data "azurerm_client_config" "current" {}

variable "terraform_service_principal" {
  type    = string
  default = "terraform-sp"
}

variable "automation_account_name" {
  type    = string
  default = "automation-dev-account"
}

#########################################################
# Create Azure SQL server and database on dev environment
#########################################################
resource "random_string" "username" {
  length           = 24
  special          = true
  override_special = "%@!"
}

resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "%@!"
}

resource "azurerm_resource_group" "dev_rg" {
  name     = "${local.prefix}-rg"
  location = local.region

  tags = merge(local.common_tags)
}

data "azuread_service_principal" "terraform_sp" {
  display_name = var.terraform_service_principal
}

resource "azurerm_key_vault" "key_vault" {
  name                = "${local.prefix}-kv"
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "List",
      "Set",
      "Get",
      "Delete"
    ]
  }
}

resource "azurerm_key_vault_secret" "sql_admin_username" {
  name         = "${local.prefix}-sql-admin-username"
  value        = random_string.username.result
  key_vault_id = azurerm_key_vault.key_vault.id
  tags         = merge(local.common_tags, tomap({ "type" = "key-vault-secret-username" }))

  depends_on = [azurerm_key_vault.key_vault]
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "${local.prefix}-sql-admin-password"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.key_vault.id
  tags         = merge(local.common_tags, tomap({ "type" = "key-vault-secret-password" }))

  depends_on = [azurerm_key_vault.key_vault]
}

resource "azurerm_mssql_server" "main" {
  name                = "${local.prefix}-mssqlserver-main"
  resource_group_name = azurerm_resource_group.dev_rg.name
  location            = azurerm_resource_group.dev_rg.location
  version             = "12.0"
  minimum_tls_version = "1.2"

  administrator_login          = azurerm_key_vault_secret.sql_admin_username.value
  administrator_login_password = azurerm_key_vault_secret.sql_admin_password.value

  azuread_administrator {
    #    azuread_authentication_only = true
    login_username = data.azuread_service_principal.terraform_sp.display_name
    object_id      = data.azuread_service_principal.terraform_sp.application_id
  }

  tags = merge(local.common_tags, tomap({
    "type" : "azure-sql-server"
  }))

  depends_on = [azurerm_key_vault_secret.sql_admin_password, azurerm_key_vault_secret.sql_admin_username]
}

resource "azurerm_mssql_database" "main" {
  name           = "${local.prefix}-mssql-db"
  server_id      = azurerm_mssql_server.main.id
  license_type   = "LicenseIncluded"
#  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = false

  tags = merge(local.common_tags, tomap({
    "type" : "azure-sql-database"
  }))
}

#############################################
# Create Azure automation account and runbook
#############################################


###################################
# Create guest and user group on AD
###################################
