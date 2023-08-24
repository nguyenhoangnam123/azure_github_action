## This repository is considered to be the guideline for creating Azure SQL database

### Prerequisites
- [x] Azure CLI
- [x] Terraform
- [x] Azure subscription
- [x] Azure service principal which has adequate roles
- [x] GitHub public repository which has three environments (dev, staging, prod)

### CI/CD workflows

### References
- [How to install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure CLI documentation](https://learn.microsoft.com/en-us/cli/azure/reference-docs-index)
- [How to install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [How to config Terraform Azure provider](https://learn.microsoft.com/en-us/azure/developer/terraform/create-resource-group?tabs=azure-cli)
- [How to authenticate Terraform client by Azure service principal](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?source=recommendations&tabs=bash)
- [How to store Terraform remote backend in Storage Account](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)
- [How to use Az Powershell](https://learn.microsoft.com/bs-latn-ba/powershell/azure/get-started-azureps?view=azps-0.10.0)
- [Azure SQL authentication by Azure AD](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-configure?tabs=azure-cli&view=azuresql#provision-azure-ad-admin-sql-managed-instance)
- [How to create User assigned managed identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp)