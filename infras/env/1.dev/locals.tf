locals {
  environment = "dev"
  prefix      = "namnh21894-${local.environment}"
  region      = "eastus"

  key_vault_user_access_policies = toset([
    for object_id in data.azuread_users.access_key_vault_users.object_ids :
    {
      tenant_id       = data.azurerm_client_config.current.tenant_id
      object_id       = object_id
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
  ])

  key_vault_sps_access_policies = toset([
    for object_id in data.azuread_service_principals.access_key_vault_sps.object_ids :
    {
      tenant_id       = data.azurerm_client_config.current.tenant_id
      object_id       = object_id
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
  ])

  key_vault_access_policies = setunion(
    local.key_vault_user_access_policies,
    local.key_vault_sps_access_policies
  )

  common_tags = {
    Environment = "dev",
    Terraform   = true
  }
}