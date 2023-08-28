variable "common_tags" {
  type = map(string)
  description = "common tags for resources"
  default = {}
}

variable "create_resource_group" {
  type        = bool
  description = "decide whether create separate resource group for resources"
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "resource group name which is delivered from root module"
  default     = ""
}

variable "environment" {
  type        = string
  description = "resource environment which is delivered from root module"
  default     = "general"
}

variable "region" {
  type        = string
  description = "provider region which is delivered from root module"
  default     = "eastus"
}

variable "common_prefix" {
  type        = string
  description = "prefix of all resource names"
  default     = "namnh21894"
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

variable "enable_mssql_authentication_by_ad" {
  type        = bool
  description = "decide whether to authenticate with mssql server by azure ad"
  default     = true
}

variable "mssql_administrative_ad_entity_type" {
  type        = string
  description = "azure ad entity type for administrative azure mssql"

  validation {
    condition = contains(["User", "ServicePrincipal"], var.mssql_administrative_ad_entity_type)
    error_message = "invalid ad entity type"
  }
}

variable "mssql_administrative_ad_service_principal_name" {
  type        = string
  description = "service principal name for administrative azure mssql"
  default     = ""
}

variable "mssql_administrative_ad_user_principal_name" {
  type        = string
  description = "user principal name for administrative azure mssql"
  default     = ""
}

variable "mssql_authentication_by_ad_only" {
  type        = bool
  description = "decide whether to authenticate with mssql server by azure ad only"
  default     = false
}

variable "create_user_assigned_managed_identity" {
  type        = bool
  description = "decide whether to create user assigned managed identity"
  default     = true
}

variable "access_key_vault_users" {
  type    = list(string)
  default = ["namnh21894_gmail.com#EXT#@namnh21894gmail.onmicrosoft.com"]
}

variable "mssql_database_license_type" {
  type        = string
  description = "mssql database license type"
  default     = "LicenseIncluded"
}

variable "mssql_database_sku_name" {
  type        = string
  description = "mssql database sku name"
  default     = "S0"

  validation {
    condition = contains([
      "GP_S_Gen5_2", "HS_Gen4_1", "BC_Gen5_2", "ElasticPool", "Basic", "S0", "P2", "DW100c", "DS100"
    ], var.mssql_database_sku_name)
    error_message = "invalid database sku"
  }
}

variable "mssql_database_zone_redundant" {
  type        = bool
  description = "decide to redundant mssql database"
  default     = false
}

variable "mssql_database_read_scale" {
  type        = bool
  description = "decide to enable read scale for mssql database"
  default     = false
}

variable "mssql_database_max_size_gb" {
  type        = number
  description = "mssql database max size number in GB"
  default     = 4
}

