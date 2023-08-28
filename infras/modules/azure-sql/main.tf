# datasource
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

########################################
# Resource group for Azure SQL resources
########################################
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = "${local.prefix}-rg"
  location = local.region

  tags = merge(local.common_tags)
}

data "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {

}

#####################################################
# Azure SQL Administrative account (without Azure AD)
#####################################################
resource "random_string" "username" {
  count            = var.mssql_authentication_by_ad_only ? 0 : 1
  length           = 24
  special          = true
  override_special = "%@!"
}

resource "random_password" "password" {
  count            = var.mssql_authentication_by_ad_only ? 0 : 1
  length           = 24
  special          = true
  override_special = "%@!"
}

resource "azurerm_key_vault" "key_vault" {
  count               = var.mssql_authentication_by_ad_only ? 0 : 1
  name                = "${local.prefix}-kv"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
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
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]
  }
}

resource "azurerm_key_vault_secret" "sql_admin_username" {
  count        = var.mssql_authentication_by_ad_only ? 0 : 1
  name         = "${local.prefix}-sql-admin-username"
  value        = random_string.username[0].result
  key_vault_id = azurerm_key_vault.key_vault[0].id
  tags         = merge(local.common_tags, tomap({ "type" = "key-vault-secret-username" }))

  depends_on = [azurerm_key_vault.key_vault]
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  count        = var.mssql_authentication_by_ad_only ? 0 : 1
  name         = "${local.prefix}-sql-admin-password"
  value        = random_password.password[0].result
  key_vault_id = azurerm_key_vault.key_vault[0].id
  tags         = merge(local.common_tags, tomap({ "type" = "key-vault-secret-password" }))

  depends_on = [azurerm_key_vault.key_vault]
}

################################################
# Azure AD identity for Azure SQL Administrative
################################################
data "azuread_service_principal" "mssql_ad_administrative_sp" {
  count        = local.mssql_administrative_ad_service_principal_name ? 1 : 0
  display_name = var.mssql_administrative_ad_service_principal_name
}

data "azuread_user" "mssql_ad_administrative_user" {
  count               = local.mssql_administrative_ad_user_principal_name ? 1 : 0
  user_principal_name = var.mssql_administrative_ad_service_principal_name
}

###########################
# Azure SQL server Identity
###########################
resource "azurerm_user_assigned_identity" "mssql_server_identity" {
  count               = var.create_user_assigned_managed_identity ? 1 : 0
  name                = "${local.prefix}-mssqlserver-identity"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  tags = merge(local.common_tags, tomap({
    "type" : "user-defined-managed-identity"
  }))
}

resource "azurerm_role_assignment" "mssql_server_identity_role_assignment" {
  for_each             = var.create_user_assigned_managed_identity ? toset(var.azure_sql_server_role_assigned_names) : []
  role_definition_name = each.key
  scope                = data.azurerm_subscription.current.id
  principal_id         = azurerm_user_assigned_identity.mssql_server_identity[0].principal_id
}

resource "azuread_application" "mssql_server_identity_ad_app" {
  count            = var.create_user_assigned_managed_identity ? 1 : 0
  display_name     = "${local.prefix}-mssql-server-identity-ad-app"
  owners           = [azurerm_user_assigned_identity.mssql_server_identity[0].principal_id]
  sign_in_audience = "AzureADMyOrg"

  dynamic "app_role" {
    for_each = var.mssql_identity_app_roles
    content {
      allowed_member_types = app_role.value["allowed_member_types"]
      description          = app_role.value["description"]
      display_name         = app_role.value["display_name"]
      enabled              = app_role.value["enabled"]
      id                   = app_role.value["id"]
      value                = app_role.value["value"]
    }
  }

  dynamic "required_resource_access" {
    for_each = var.mssql_identity_app_resource_access
    content {
      resource_app_id = required_resource_access.value["resource_app_id"] # Microsoft Graph

      dynamic "resource_access" {
        for_each = required_resource_access.value["resource_access"]
        content {
          id   = resource_access.value["id"]
          type = resource_access.value["type"]
        }
      }
    }
  }
}

#########################################################
# Create Azure SQL server and database on dev environment
#########################################################
resource "azurerm_mssql_server" "main" {
  name                = "${local.prefix}-mssqlserver-main"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  version             = "12.0"
  minimum_tls_version = "1.2"

  administrator_login          = var.mssql_authentication_by_ad_only ? null : azurerm_key_vault_secret.sql_admin_username[0].value
  administrator_login_password = var.mssql_authentication_by_ad_only ? null : azurerm_key_vault_secret.sql_admin_password[0].value

  dynamic "azuread_administrator" {
    for_each = local.mssql_administrative_ad_service_principal_name ? [1] : []
    content {
      azuread_authentication_only = var.mssql_authentication_by_ad_only
      login_username              = data.azuread_service_principal.mssql_ad_administrative_sp[0].display_name
      object_id                   = data.azuread_service_principal.mssql_ad_administrative_sp[0].application_id
    }
  }

  dynamic "azuread_administrator" {
    for_each = local.mssql_administrative_ad_user_principal_name ? [1] : []
    content {
      azuread_authentication_only = var.mssql_authentication_by_ad_only
      login_username              = data.azuread_user.mssql_ad_administrative_user[0].display_name
      object_id                   = data.azuread_user.mssql_ad_administrative_user[0].object_id
    }
  }

  dynamic "identity" {
    for_each = var.create_user_assigned_managed_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.mssql_server_identity[0].id]
    }
  }

  primary_user_assigned_identity_id = azurerm_user_assigned_identity.mssql_server_identity[0].id

  tags = merge(local.common_tags, tomap({
    "type" : "azure-sql-server"
  }))

  depends_on = [azurerm_key_vault_secret.sql_admin_password, azurerm_key_vault_secret.sql_admin_username]
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.azure_mssql_server_fw_rule["start_ip_address"]
  end_ip_address   = var.azure_mssql_server_fw_rule["end_ip_address"]
}

resource "azurerm_mssql_database" "main" {
  name                 = "${local.prefix}-mssql-db"
  server_id            = azurerm_mssql_server.main.id
  license_type         = "LicenseIncluded"
  max_size_gb          = var.mssql_database_zone_redundant ? var.mssql_database_max_size_gb : null
  read_scale           = var.mssql_database_zone_redundant && var.mssql_database_read_scale
  sku_name             = var.mssql_database_sku_name
  zone_redundant       = var.mssql_database_zone_redundant
  storage_account_type = var.mssql_database_storage_account_type

  tags = merge(local.common_tags, tomap({
    "type" : "azure-sql-database"
  }))
}
