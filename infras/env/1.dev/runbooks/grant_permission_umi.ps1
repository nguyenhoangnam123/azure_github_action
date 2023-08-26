$DestinationTenantId = "b5606dd5-4171-4134-a6bd-ec46618ad53d"
$MsiName = "terraform-umi" # Name of system-assigned or user-assigned managed service identity. (System-assigned use same name as resource).
$oPermissions = @(
  "Directory.ReadWrite.All"
  "Group.ReadWrite.All"
  "GroupMember.ReadWrite.All"
  "User.ReadWrite.All"
  "RoleManagement.ReadWrite.Directory"
  "AppRoleAssignment.ReadWrite.All"
  "Application.ReadWrite.All"
)
$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this.
$oMsi = Get-AzADServicePrincipal -Filter "displayName eq '$MsiName'"
$oGraphSpn = Get-AzADServicePrincipal -Filter "appId eq '$GraphAppId'"
$oAppRole = $oGraphSpn.AppRole | Where-Object {($_.Value -in $oPermissions) -and ($_.AllowedMemberType -contains "Application")}

Connect-MgGraph -TenantId $DestinationTenantId -Scopes "User.Read.all","Directory.ReadWrite.All","Group.ReadWrite.All","GroupMember.ReadWrite.All","User.ReadWrite.All","RoleManagement.ReadWrite.Directory", "AppRoleAssignment.ReadWrite.All"

foreach($AppRole in $oAppRole)
{
  $oAppRoleAssignment = @{
    "PrincipalId" = $oMSI.Id
    "ResourceId" = $oGraphSpn.Id
    "AppRoleId" = $AppRole.Id
  }

  New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $oAppRoleAssignment.PrincipalId `
    -BodyParameter $oAppRoleAssignment `
    -Verbose
}