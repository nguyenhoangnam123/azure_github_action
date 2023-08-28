########################################################
# Common variables
########################################################
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

########################################################
# Azure SQL variables
########################################################
variable "mssql_administrative_ad_service_principal_name" {
  type        = string
  description = "service principal name for administrative azure mssql"
  default     = ""
}