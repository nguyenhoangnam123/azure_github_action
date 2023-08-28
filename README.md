## Azure SQL database and automation account workaround

### Prerequisites
- [x] Azure CLI on local machine
- [x] Azure Az Powershell module on local machine
- [x] Terraform
- [x] Azure subscription
- [x] Azure service principal which has adequate roles
- [x] GitHub public repository which has three environments (dev, prod)
- [x] Required identities

| Identity        | Type                            | RBAC          | Scope                   | Microsoft Graph API permissions                                                                                                                                                                                             | Descriptions                                                                                                                                                                                                                     |
|-----------------|---------------------------------|---------------|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `owners`        | `Microsoft User`                | `Owner`       | `Root management group` | Full permissions                                                                                                                                                                                                            | Create, grant permissions to other identities (service principal, managed identities) including two identities below by Az Powershell                                                                                            |
| `terraform-umi` | `User defined managed identity` | `Contributor` | `Subscription/0081ea25-c945-486a-b7c6-6fe8c1bd4169`         | `Directory.ReadWrite.All`<br/>`Group.ReadWrite.All`<br/>`GroupMember.ReadWrite.All`<br/>`User.ReadWrite.All`<br/>`RoleManagement.ReadWrite.Directory`<br/>`AppRoleAssignment.ReadWrite.All`<br/>`Application.ReadWrite.All` | Identity on behalf of owner to provision resources, has federated token from github OIDC provider to authenticate GitHub Action. It required permission to `Microsoft GraphAPI` to read and map `terraform-sp` as Database Admin |
| `terraform-sp`  | `Service Principal`             | `Contributor`       | `Subscription/0081ea25-c945-486a-b7c6-6fe8c1bd4169`                  | -                                                                                                                                                                                                                           | Azure AD identity represent for Azure SQL administrative account, to grant other AD identity access                                                                                                                              |

### Features
- Create Azure resources by Terraform, `user defined managed identity (UMI)`, and GitHub OIDC provider
- Modularize resources into modules for reusing in all environments (`dev`, `prod`)
- Continuous delivery resources by using GitHub Action and GitHub environment 
- Provision runbook in automation account to query Azure SQL database
- Azure SQL server uses `UMI` as server identity to read `Azure Directory (AD)` and map `AD identities` with database roles. 
- Cleanup environment by GitHub Action

### Project insights
- File structure
```
.
├── README.md
└── infras
    ├── env
    │   ├── 1.dev
    │   │   ├── locals.tf
    │   │   ├── main.tf
    │   │   ├── runbooks
    │   │   │   ├── grant_permission_umi.ps1
    │   │   │   └── query-database-rbac.ps1
    │   │   ├── terraform.tfvars
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   └── 2.prod
    │       ├── locals.tf
    │       ├── main.tf
    │       ├── runbooks
    │       │   ├── grant_permission_umi.ps1
    │       │   └── query-database-rbac.ps1
    │       ├── terraform.tfvars
    │       ├── variables.tf
    │       └── versions.tf
    └── modules
        ├── automation_account
        │   ├── locals.tf
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        └── azure_sql
            ├── locals.tf
            ├── main.tf
            ├── outputs.tf
            └── variables.tf
```
- Github Environment specs:

| Environment | protection rule     | secret: description                                                                                                                                                                                                                                                                                                                                                                                              |
|-------------|---------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| dev         | require approvement | `AZURE_CLIENT_ID`: `terraform-umi` client Id which is on behalf of you to provision infrastruture<br/>`AZURE_SUBSCRIPTION_ID`:<br/>`AZURE_TENANT_ID`<br/>`BACKEND_AZURE_RESOURCE_GROUP_NAME`: resource group of Terraform backend where storage account living<br/>`BACKEND_AZURE_STORAGE_ACCOUNT_NAME`: Terraform backend storage name<br/>`BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME`: backend storage path |
| prod        | require approvement              | Similar to dev                                                                                                                                                                                                                                                                                                                                                                                                   |

- Terraform module specs:

| Module               | Workspace path                        | Components                                                                                                                                                                                                                                    | Resources: description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|----------------------|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `azure_sql`          | `./infras/modules/azure_sql`          | `locals.tf`: share computed value from variables<br/>`main.tf`: resources specification location<br/>`variables.tf`: source parameters<br/>`outputs.tf`: exposed value from resources                                                         | `azurerm_resource_group`: resource container<br/>`random_string/random_password`: generate Azure SQL credential for SQL authentication<br/>`azurerm_key_vault/azurerm_key_vault_secret/azurerm_key_vault_secret`: store database credential secrets<br/>`azuread_service_principal/azuread_user`: mssql server administrators<br/>`azurerm_user_assigned_identity/azurerm_role_assignment/azuread_application`: mssql server identity<br/>`azurerm_mssql_server/azurerm_mssql_firewall_rule/azurerm_mssql_database`: mssql server, firewall and database |
| `automation_account` | `./infras/modules/automation_account` | `locals.tf`: share computed value from variables<br/>`main.tf`: resources specification location<br/>`variables.tf`: source parameters<br/>`outputs.tf`: exposed value from resources                                                         | `azurerm_resource_group`: resource container<br/>`azurerm_automation_account/local_file/azurerm_automation_runbook/azurerm_automation_webhook`: automation account, runbook and webhook                                                                                                                                                                                                                                                                                                                                                                  |
| `root (dev/prod)`    | `./infras/env/<NUMBER>.<ENV_NAME>`    | `locals.tf`: share computed value from variables<br/>`main.tf`: resources specification location<br/>`variables.tf`: source parameters<br/>`terraform.tfvars`: override variables<br/>`runbooks/query-database-rbac.ps1`: runbook source file | `azure_sql`: child module called to provision azure sql database<br/>`azure_automation_account`: child module  called to provision azure automation account                                                                                                                                                                                                                                                                                                                                                                                              |

### Continuous delivery workflows
- Workflow Identity: `terraform-umi` with federated token from GitHub OIDC provider
- Workflow dev:
  - trigger on `pull_request` on `main` branch created
  ```
    on:
      pull_request:
        branches:
          - main
      workflow_dispatch:  
  ```
  - permission `contents: read` allow checkout source and `id-token: write` allow create OIDC exchanged tokens
  ```
    permissions:
      id-token: write
      contents: read  
  ```
  - Job directory point to Terraform working environment.
  ```
    defaults:
      run:
        working-directory: infras/env/1.dev  
  ```
  - Environment variable to config Terraform CLI
  ```
    env:
      ARM_CLIENT_ID: "${{secrets.AZURE_CLIENT_ID}}"
      ARM_SUBSCRIPTION_ID: "${{secrets.AZURE_SUBSCRIPTION_ID}}"
      ARM_TENANT_ID: "${{secrets.AZURE_TENANT_ID}}"  
  ```
  - Initialize Terraform remote backend configuration on storage account
  ```
    - name: Terraform Init
      run: |
        terraform init \
          -backend-config="resource_group_name=${{secrets.BACKEND_AZURE_RESOURCE_GROUP_NAME}}" \
          -backend-config="storage_account_name=${{secrets.BACKEND_AZURE_STORAGE_ACCOUNT_NAME}}" \
          -backend-config="container_name=${{secrets.BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME}}"        
  ```

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