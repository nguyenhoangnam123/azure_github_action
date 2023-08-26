# datasource
data "azurerm_client_config" "current" {}

data "azuread_service_principal" "terraform_sp" {
  display_name = var.terraform_service_principal
}

data "azuread_users" "access_key_vault_users" {
  user_principal_names = var.access_key_vault_users
}

data "azuread_service_principals" "access_key_vault_sps" {
  display_names = var.access_key_vault_sps
}

data "azurerm_subscription" "current" {}

variable "terraform_service_principal" {
  type    = string
  default = "terraform-sp"
}

variable "automation_account_name" {
  type    = string
  default = "automation-dev-account"
}

variable "azure_mssql_server_fw_rule" {
  type    = map(string)
  default = {
    start_ip_address = "0.0.0.0",
    end_ip_address   = "0.0.0.0",
  }
}

variable "mssql_identity_app_roles" {
  type = list(object({
    allowed_member_types = set(string)
    description          = string
    display_name         = string
    enabled              = bool
    id                   = string
    value                = string
  }))

  default = [
    {
      allowed_member_types = ["User", "Application"]
      description          = "Admins can manage roles and perform all task actions"
      display_name         = "Admin"
      enabled              = true
      id                   = "1b19509b-32b1-4e9f-b71d-4992aa991967"
      value                = "admin"
    }
  ]
}

variable "mssql_identity_app_resource_access" {
  type = map(object({
    resource_app_id = string
    resource_access = set(object({
      id   = string
      type = string
    }))
  }))

  default = {
    microsoft_graph = {
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
          type = "Role"
        },
        {
          id   = "b4e74841-8e56-480b-be8b-910348b18b4c" # User.ReadWrite
          type = "Scope"
        }
      ]
    }
  }
}

variable "azure_sql_server_role_assigned_names" {
  type    = list(string)
  default = ["Contributor"]
}

variable "access_key_vault_users" {
  type = list(string)
  default = ["namnh21894_gmail.com#EXT#@namnh21894gmail.onmicrosoft.com"]
}

variable "access_key_vault_sps" {
  type = list(string)
  default = ["terraform-umi, terraform-msi, terraform-sp"]
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

resource "azurerm_key_vault" "key_vault" {
  name                = "${local.prefix}-kv"
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  dynamic "access_policy" {
    for_each = local.key_vault_access_policies
    content {
      tenant_id = access_policy.value["tenant_id"]
      object_id = access_policy.value["object_id"]
      key_permissions = access_policy.value["key_permissions"]
      secret_permissions = access_policy.value["secret_permissions"]
    }
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

resource "azurerm_user_assigned_identity" "mssql_server_identity" {
  name                = "${local.prefix}-mssqlserver-identity"
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name

  tags = merge(local.common_tags, tomap({
    "type" : "user-defined-managed-identity"
  }))
}

resource "azurerm_role_assignment" "mssql_server_identity_role_assignment" {
  for_each             = toset(var.azure_sql_server_role_assigned_names)
  role_definition_name = each.key
  scope                = data.azurerm_subscription.current.id
  principal_id         = azurerm_user_assigned_identity.mssql_server_identity.principal_id
}

resource "azuread_application" "mssql_server_identity_ad_app" {
  display_name     = "${local.prefix}-mssql-server-identity-ad-app"
  owners           = [azurerm_user_assigned_identity.mssql_server_identity.principal_id]
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

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mssql_server_identity.id]
  }

  primary_user_assigned_identity_id = azurerm_user_assigned_identity.mssql_server_identity.id

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
  name           = "${local.prefix}-mssql-db"
  server_id      = azurerm_mssql_server.main.id
  license_type   = "LicenseIncluded"
  #  max_size_gb    = 4
  #  read_scale     = true
  sku_name       = "S0"
  zone_redundant = false

  tags = merge(local.common_tags, tomap({
    "type" : "azure-sql-database"
  }))
}

#############################################
# Create Azure automation account and runbook
#############################################
resource "azurerm_automation_account" "main" {
  name                = "${local.prefix}-automation-account"
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name

  identity {
    type = "SystemAssigned"
  }

  sku_name = "Basic"

  tags = merge(local.common_tags, tomap({
    type = "automation-account"
  }))
}

data "local_file" "runbook_database_rbac" {
  filename = "${path.module}/runbooks/query-database-rbac.ps1"
}

resource "azurerm_automation_runbook" "query_database_rbac" {
  name                    = "${local.prefix}-query-database_rbac"
  location                = azurerm_resource_group.dev_rg.location
  resource_group_name     = azurerm_resource_group.dev_rg.name
  automation_account_name = azurerm_automation_account.main.name

  log_verbose  = "true"
  log_progress = "true"
  description  = "This is an runbook for querying database rbac"
  runbook_type = "PowerShell"

  content = data.local_file.runbook_database_rbac.content

  tags = merge(local.common_tags, tomap({
    type = "automation-runbook"
  }))
}

resource "azurerm_automation_webhook" "query_database_rbac_runbook_webhook" {
  name                    = "${local.prefix}-query-database-webhook"
  resource_group_name     = azurerm_resource_group.dev_rg.name
  automation_account_name = azurerm_automation_account.main.name
  expiry_time             = "2023-12-31T00:00:00Z"

  enabled      = true
  runbook_name = azurerm_automation_runbook.query_database_rbac.name
  parameters   = {
    input = "parameter"
  }
}

output "automation_runbook_webhook_uri" {
  sensitive = true
  value = azurerm_automation_webhook.query_database_rbac_runbook_webhook.uri
}

###################################
# Create guest and user group on AD
###################################
