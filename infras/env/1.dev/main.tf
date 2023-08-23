resource "azurerm_resource_group" "dev_rg" {
  name     = "database-rg"
  location = "eastus"
}

data "azuread_service_principal" "terraform_sp" {
  display_name = "terraform-sp"
}

resource "azurerm_mssql_server" "main" {
  name                = "mssqlserver-main"
  resource_group_name = azurerm_resource_group.dev_rg.name
  location            = azurerm_resource_group.dev_rg.location
  version             = "12.0"
  minimum_tls_version = "1.2"

  #  administrator_login          = "admin"
  #  administrator_login_password = "123456Abc1"

  azuread_administrator {
    azuread_authentication_only = true
    login_username              = data.azuread_service_principal.terraform_sp.display_name
    object_id                   = data.azuread_service_principal.terraform_sp.application_id
  }

  tags = {
    Terraform   = "true"
    environment = "dev"
  }
}