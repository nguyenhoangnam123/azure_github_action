module "azure_sql" {
  source = "../../modules/azure-sql/"

  environment   = var.environment
  region        = var.region
  common_prefix = var.common_prefix

  mssql_administrative_ad_entity_type            = "ServicePrincipal"
  mssql_administrative_ad_service_principal_name = var.mssql_administrative_ad_service_principal_name

  common_tags = local.common_tags
}

module "azure_automation_account" {
  source = "../../modules/automation_account"

  environment   = var.environment
  region        = var.region
  common_prefix = var.common_prefix

  runbook_file_path = "${path.root}/runbooks/query-database-rbac.ps1"
}




