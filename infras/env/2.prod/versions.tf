terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.71.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.41.0"
    }
  }
  backend "azurerm" {
    use_oidc = true
    key      = "prod.terraform.tfstate"
    #    resource_group_name  = "terraform-state"
    #    storage_account_name = "namnh21894"
    #    container_name       = "tfstate"
    #    subscription_id      = "0081ea25-c945-486a-b7c6-6fe8c1bd4169"
    #    tenant_id            = "b5606dd5-4171-4134-a6bd-ec46618ad53d"
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
  #  subscription_id = "0081ea25-c945-486a-b7c6-6fe8c1bd4169"
  #  tenant_id       = "b5606dd5-4171-4134-a6bd-ec46618ad53d"
  #  client_id       = "23e114c5-6fb1-4f37-b733-e8b545f75bc7" # service principal id
}

provider "azuread" {
  use_oidc = true
  #  tenant_id = "b5606dd5-4171-4134-a6bd-ec46618ad53d"
  #  client_id       = "23e114c5-6fb1-4f37-b733-e8b545f75bc7" # service principal id
}

#1061981b-587a-4f1b-8941-cb3ecc83147f