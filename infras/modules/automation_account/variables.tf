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

variable "automation_account_sku_name" {
  type        = string
  description = "automation account sku name"
  default     = "Basic"
}

variable "create_runbook" {
  type        = bool
  description = "decide whether to create runbook or not"
  default     = true
}

variable "create_runbook_webhook" {
  type        = bool
  description = "decide whether to create runbook webhook or not"
  default     = true
}

variable "runbook_file_path" {
  type        = string
  description = "path to runbook file"
  default     = ""

  validation {
    condition     = length(var.runbook_file_path) > 0
    error_message = "the path to runbook can not be null or empty"
  }
}

variable "runbook_log_verbose" {
  type        = bool
  description = "decide log verbosity"
  default     = true
}

variable "runbook_log_progress" {
  type        = bool
  description = "decide log progress"
  default     = true
}

variable "runbook_description" {
  type        = string
  description = "runbook description"
  default     = ""
}

variable "runbook_type" {
  type        = string
  description = "runbook platform"
  default     = "PowerShell"
}

variable "webhook_parameters" {
  type        = map(any)
  description = "webhook parameters"
  default     = {}
}

variable "enable_webhook" {
  type        = bool
  description = "enable webhook"
  default     = true
}

